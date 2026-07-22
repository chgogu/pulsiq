/// WHOOP API payloads → app models. Pure and unit-tested; the HTTP/auth
/// plumbing lives in lib/health/whoop and only ever hands parsed JSON here.
///
/// WHOOP fills exactly the biometric fields the PulsIQ Score already uses
/// (resting HR, HRV, respiratory rate, sleep), so connecting it lights up the
/// score with no change to the baseline engine.
library;

import 'health_models.dart';

/// OAuth token set from the WHOOP token endpoint.
class WhoopTokens {
  const WhoopTokens({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
  });

  final String accessToken;

  /// Present only when `offline` scope was granted; null on a refresh that
  /// doesn't rotate it.
  final String? refreshToken;
  final DateTime expiresAt;

  /// Refresh a minute early so a call in flight doesn't race expiry.
  bool isExpired(DateTime now) =>
      !now.isBefore(expiresAt.subtract(const Duration(seconds: 60)));

  static WhoopTokens parse(Map<String, dynamic> json, {DateTime? now}) {
    final access = json['access_token'];
    if (access is! String || access.isEmpty) {
      throw const FormatException('WHOOP token response missing access_token');
    }
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    final refresh = json['refresh_token'];
    return WhoopTokens(
      accessToken: access,
      refreshToken: refresh is String && refresh.isNotEmpty ? refresh : null,
      expiresAt:
          (now ?? DateTime.now()).add(Duration(seconds: expiresIn)),
    );
  }
}

/// Body measurements — used to pre-fill the body-profile screen.
class WhoopProfile {
  const WhoopProfile({this.heightM, this.weightKg, this.maxHr});

  final double? heightM;
  final double? weightKg;
  final int? maxHr;

  static WhoopProfile parse(Map<String, dynamic> json) => WhoopProfile(
        heightM: (json['height_meter'] as num?)?.toDouble(),
        weightKg: (json['weight_kilogram'] as num?)?.toDouble(),
        maxHr: (json['max_heart_rate'] as num?)?.toInt(),
      );
}

/// WHOOP's recovery bands (green ≥67, yellow 34–66, red ≤33).
enum RecoveryBand {
  green,
  yellow,
  red;

  static RecoveryBand of(num pct) =>
      pct >= 67 ? RecoveryBand.green : (pct >= 34 ? RecoveryBand.yellow : RecoveryBand.red);

  String get label => switch (this) {
        RecoveryBand.green => 'Primed',
        RecoveryBand.yellow => 'Moderate',
        RecoveryBand.red => 'Take it easy',
      };
}

/// The richest recent WHOOP reading — the latest scored recovery, plus the
/// sleep and cycle that go with it. Drives the dashboard WHOOP card. Unlike
/// [DailyBiometrics] (which feeds the baseline score and needs a same-day
/// point), this deliberately surfaces the *most recent available* data so the
/// card is never blank just because today's recovery hasn't computed yet.
class WhoopSnapshot {
  const WhoopSnapshot({
    required this.day,
    this.recoveryPct,
    this.hrvMs,
    this.restingHr,
    this.strain,
    this.avgHr,
    this.sleepHours,
    this.sleepPerformancePct,
    this.respiratoryRate,
    this.daysOfData = 0,
  });

  final DateTime day;
  final int? recoveryPct;
  final double? hrvMs;
  final double? restingHr;
  final double? strain; // 0–21
  final double? avgHr;
  final double? sleepHours;
  final double? sleepPerformancePct;
  final double? respiratoryRate;

  /// How many scored recovery days were in range — context for "is this a
  /// one-off or a trend".
  final int daysOfData;

  bool get isEmpty =>
      recoveryPct == null &&
      hrvMs == null &&
      restingHr == null &&
      strain == null &&
      sleepHours == null;

  RecoveryBand? get band =>
      recoveryPct == null ? null : RecoveryBand.of(recoveryPct!);
}

const _msPerHour = 3600000.0;

double? _num(Map<String, dynamic>? m, String k) =>
    (m?[k] as num?)?.toDouble();

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Parses a WHOOP timestamp; records with no usable date are dropped.
DateTime? _tsOf(Map<String, dynamic> record, List<String> keys) {
  for (final k in keys) {
    final v = record[k];
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed.toLocal();
    }
  }
  return null;
}

/// Merge WHOOP recovery + sleep record lists into one [DailyBiometrics] per
/// day. Recovery carries HRV/resting-HR; sleep carries hours, efficiency, and
/// respiratory rate. Records still scoring (`score_state != 'SCORED'`) or with
/// no score are skipped rather than logged as zeros.
List<DailyBiometrics> mapWhoopDaily({
  required List<Map<String, dynamic>> recovery,
  required List<Map<String, dynamic>> sleep,
}) {
  final rhr = <DateTime, double>{};
  final hrv = <DateTime, double>{};
  final resp = <DateTime, double>{};
  final sleepH = <DateTime, double>{};
  final eff = <DateTime, double>{};
  final days = <DateTime>{};

  for (final r in recovery) {
    if (r['score_state'] != 'SCORED') continue;
    final score = r['score'];
    if (score is! Map<String, dynamic>) continue;
    // WHOOP dates recovery to the sleep it followed; use created_at.
    final ts = _tsOf(r, const ['created_at', 'updated_at']);
    if (ts == null) continue;
    final day = _dayOf(ts);
    days.add(day);
    final restingHr = _num(score, 'resting_heart_rate');
    final hrvMs = _num(score, 'hrv_rmssd_milli');
    if (restingHr != null) rhr[day] = restingHr;
    // WHOOP reports HRV in seconds (rmssd_milli is a misnomer for some
    // firmware); values <1 are seconds → convert to ms.
    if (hrvMs != null) hrv[day] = hrvMs < 1 ? hrvMs * 1000 : hrvMs;
  }

  for (final s in sleep) {
    if (s['score_state'] != 'SCORED') continue;
    if (s['nap'] == true) continue; // naps don't set the day's baseline
    final score = s['score'];
    if (score is! Map<String, dynamic>) continue;
    final ts = _tsOf(s, const ['end', 'start']);
    if (ts == null) continue;
    final day = _dayOf(ts);
    days.add(day);
    final stages = score['stage_summary'];
    if (stages is Map<String, dynamic>) {
      final inBed = _num(stages, 'total_in_bed_time_milli') ?? 0;
      final awake = _num(stages, 'total_awake_time_milli') ?? 0;
      final asleep = (inBed - awake).clamp(0, double.infinity);
      if (asleep > 0) sleepH[day] = asleep / _msPerHour;
    }
    final e = _num(score, 'sleep_efficiency_percentage');
    if (e != null) eff[day] = e;
    final rr = _num(score, 'respiratory_rate');
    if (rr != null) resp[day] = rr;
  }

  final out = [
    for (final day in days)
      DailyBiometrics(
        day: day,
        restingHr: rhr[day],
        hrvMs: hrv[day],
        respiratoryRate: resp[day],
        sleepHours: sleepH[day],
        sleepEfficiencyPct: eff[day],
      ),
  ]..sort((a, b) => a.day.compareTo(b.day));
  return out;
}

/// Picks the newest SCORED record from a list, by the first present timestamp
/// key. Returns null if none qualify.
Map<String, dynamic>? _latestScored(
  List<Map<String, dynamic>> records,
  List<String> tsKeys, {
  bool skipNaps = false,
}) {
  Map<String, dynamic>? best;
  DateTime? bestTs;
  for (final r in records) {
    if (r['score_state'] != 'SCORED') continue;
    if (skipNaps && r['nap'] == true) continue;
    if (r['score'] is! Map) continue;
    final ts = _tsOf(r, tsKeys);
    if (ts == null) continue;
    if (bestTs == null || ts.isAfter(bestTs)) {
      best = r;
      bestTs = ts;
    }
  }
  return best;
}

/// Combine the latest recovery + sleep + cycle into one rich snapshot.
WhoopSnapshot? latestWhoopSnapshot({
  required List<Map<String, dynamic>> recovery,
  required List<Map<String, dynamic>> sleep,
  List<Map<String, dynamic>> cycle = const [],
}) {
  final rec = _latestScored(recovery, const ['created_at', 'updated_at']);
  final slp =
      _latestScored(sleep, const ['end', 'start'], skipNaps: true);
  final cyc = _latestScored(cycle, const ['start', 'created_at']);
  if (rec == null && slp == null && cyc == null) return null;

  final recScore = rec?['score'] as Map<String, dynamic>?;
  final slpScore = slp?['score'] as Map<String, dynamic>?;
  final cycScore = cyc?['score'] as Map<String, dynamic>?;

  final day = _tsOf(rec ?? slp ?? cyc!,
          const ['created_at', 'end', 'start', 'updated_at']) ??
      DateTime.now();

  double? hrv = _num(recScore, 'hrv_rmssd_milli');
  if (hrv != null && hrv < 1) hrv *= 1000; // seconds → ms

  double? sleepHours;
  final stages = slpScore?['stage_summary'];
  if (stages is Map<String, dynamic>) {
    final inBed = _num(stages, 'total_in_bed_time_milli') ?? 0;
    final awake = _num(stages, 'total_awake_time_milli') ?? 0;
    final asleep = (inBed - awake).clamp(0, double.infinity);
    if (asleep > 0) sleepHours = asleep / _msPerHour;
  }

  final scoredDays = recovery
      .where((r) => r['score_state'] == 'SCORED' && r['score'] is Map)
      .length;

  return WhoopSnapshot(
    day: _dayOf(day),
    recoveryPct: _num(recScore, 'recovery_score')?.round(),
    hrvMs: hrv,
    restingHr: _num(recScore, 'resting_heart_rate'),
    strain: _num(cycScore, 'strain'),
    avgHr: _num(cycScore, 'average_heart_rate'),
    sleepHours: sleepHours,
    sleepPerformancePct: _num(slpScore, 'sleep_performance_percentage'),
    respiratoryRate: _num(slpScore, 'respiratory_rate'),
    daysOfData: scoredDays,
  );
}

/// Smart, one-line read of the day. Leads with recovery, then flags the two
/// interactions that actually matter: high strain on low recovery (overreach)
/// and a recovery/strain mismatch worth acting on. Plain language, never a
/// bare number.
String whoopInsight(WhoopSnapshot s) {
  final rec = s.recoveryPct;
  final strain = s.strain;
  if (rec == null) {
    return s.sleepHours != null
        ? 'Sleep is in. Recovery computes shortly after — check back this morning.'
        : 'Connected. Your first recovery score lands after your next sleep.';
  }
  final band = RecoveryBand.of(rec);
  // Strain context, when we have it.
  if (strain != null) {
    if (band == RecoveryBand.red && strain >= 10) {
      return 'Recovery is low ($rec%) and yesterday ran hard (strain '
          '${strain.toStringAsFixed(1)}). Today is a recovery day — keep it easy.';
    }
    if (band == RecoveryBand.green && strain < 8) {
      return "You're primed ($rec%) and yesterday was light. Good day to push "
          'if you want to.';
    }
    if (band == RecoveryBand.red) {
      return 'Recovery is low ($rec%). Protect it — gentle movement, water, '
          'and an early night.';
    }
  }
  return switch (band) {
    RecoveryBand.green =>
      "You're primed at $rec%. Your body can take on load today.",
    RecoveryBand.yellow =>
      'Moderate recovery ($rec%). Train, but leave a little in the tank.',
    RecoveryBand.red =>
      'Recovery is low ($rec%). A lighter day pays off tomorrow.',
  };
}
