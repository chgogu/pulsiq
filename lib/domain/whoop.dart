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

/// One day of body signals — the union of that day's recovery, sleep, and
/// cycle from the wearable. Fields are null when the wearable hasn't scored
/// them yet. (Distinct from [DailyBiometrics], which is the trimmed subset the
/// baseline score consumes.)
class WhoopDay {
  const WhoopDay({
    required this.day,
    this.recoveryPct,
    this.hrvMs,
    this.restingHr,
    this.respiratoryRate,
    this.spo2Pct,
    this.skinTempC,
    this.sleepHours,
    this.sleepPerformancePct,
    this.strain,
    this.avgHr,
    this.calories,
  });

  final DateTime day;
  final int? recoveryPct;
  final double? hrvMs;
  final double? restingHr;
  final double? respiratoryRate;
  final double? spo2Pct;
  final double? skinTempC;
  final double? sleepHours;
  final double? sleepPerformancePct;
  final double? strain; // 0–21
  final double? avgHr;
  final double? calories; // kcal

  bool get isEmpty =>
      recoveryPct == null &&
      hrvMs == null &&
      restingHr == null &&
      strain == null &&
      sleepHours == null;

  RecoveryBand? get band =>
      recoveryPct == null ? null : RecoveryBand.of(recoveryPct!);
}

/// A window of [WhoopDay]s (ascending; last = most recent) with the averaging
/// helpers the dashboard needs. Built for a 60-day window.
class WhoopBody {
  const WhoopBody(this.days);

  final List<WhoopDay> days;

  bool get isEmpty => days.isEmpty || days.every((d) => d.isEmpty);

  /// Most recent day that carries any signal — the card's headline reading.
  WhoopDay? get latest {
    for (final d in days.reversed) {
      if (!d.isEmpty) return d;
    }
    return days.isEmpty ? null : days.last;
  }

  int get scoredRecoveryDays =>
      days.where((d) => d.recoveryPct != null).length;

  /// Mean of a metric over the window, skipping days that lack it. Null when
  /// no day has the metric.
  double? average(num? Function(WhoopDay) pick) {
    var sum = 0.0;
    var n = 0;
    for (final d in days) {
      final v = pick(d);
      if (v != null) {
        sum += v;
        n++;
      }
    }
    return n == 0 ? null : sum / n;
  }

  int samples(num? Function(WhoopDay) pick) =>
      days.where((d) => pick(d) != null).length;
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

const _kjPerKcal = 4.184;

/// Merge recovery + sleep + cycle records into one [WhoopDay] per calendar
/// day, over whatever range was fetched. Ascending by day.
List<WhoopDay> mapWhoopDays({
  required List<Map<String, dynamic>> recovery,
  required List<Map<String, dynamic>> sleep,
  List<Map<String, dynamic>> cycle = const [],
}) {
  final recPct = <DateTime, int>{};
  final hrv = <DateTime, double>{};
  final rhr = <DateTime, double>{};
  final spo2 = <DateTime, double>{};
  final skin = <DateTime, double>{};
  final resp = <DateTime, double>{};
  final sleepH = <DateTime, double>{};
  final sleepPerf = <DateTime, double>{};
  final strain = <DateTime, double>{};
  final avgHr = <DateTime, double>{};
  final cals = <DateTime, double>{};
  final days = <DateTime>{};

  for (final r in recovery) {
    if (r['score_state'] != 'SCORED') continue;
    final score = r['score'];
    if (score is! Map<String, dynamic>) continue;
    final ts = _tsOf(r, const ['created_at', 'updated_at']);
    if (ts == null) continue;
    final day = _dayOf(ts);
    days.add(day);
    final rp = _num(score, 'recovery_score');
    if (rp != null) recPct[day] = rp.round();
    final rh = _num(score, 'resting_heart_rate');
    if (rh != null) rhr[day] = rh;
    var h = _num(score, 'hrv_rmssd_milli');
    if (h != null) hrv[day] = h < 1 ? h * 1000 : h; // seconds → ms
    final sp = _num(score, 'spo2_percentage');
    if (sp != null) spo2[day] = sp;
    final st = _num(score, 'skin_temp_celsius');
    if (st != null) skin[day] = st;
  }

  for (final s in sleep) {
    if (s['score_state'] != 'SCORED') continue;
    if (s['nap'] == true) continue;
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
    final perf = _num(score, 'sleep_performance_percentage');
    if (perf != null) sleepPerf[day] = perf;
    final rr = _num(score, 'respiratory_rate');
    if (rr != null) resp[day] = rr;
  }

  for (final c in cycle) {
    if (c['score_state'] != 'SCORED') continue;
    final score = c['score'];
    if (score is! Map<String, dynamic>) continue;
    final ts = _tsOf(c, const ['start', 'created_at']);
    if (ts == null) continue;
    final day = _dayOf(ts);
    days.add(day);
    final str = _num(score, 'strain');
    if (str != null) strain[day] = str;
    final ah = _num(score, 'average_heart_rate');
    if (ah != null) avgHr[day] = ah;
    final kj = _num(score, 'kilojoule');
    if (kj != null) cals[day] = kj / _kjPerKcal;
  }

  return [
    for (final day in days)
      WhoopDay(
        day: day,
        recoveryPct: recPct[day],
        hrvMs: hrv[day],
        restingHr: rhr[day],
        respiratoryRate: resp[day],
        spo2Pct: spo2[day],
        skinTempC: skin[day],
        sleepHours: sleepH[day],
        sleepPerformancePct: sleepPerf[day],
        strain: strain[day],
        avgHr: avgHr[day],
        calories: cals[day],
      ),
  ]..sort((a, b) => a.day.compareTo(b.day));
}

/// Smart, one-line read of the latest day. Leads with recovery, then flags the
/// interactions that matter: high strain on low recovery (overreach), and a
/// green-light to push when primed and rested. Plain language, never a bare
/// number.
String whoopInsight(WhoopDay s) {
  final rec = s.recoveryPct;
  final strain = s.strain;
  if (rec == null) {
    return s.sleepHours != null
        ? 'Sleep is in — your recovery score computes shortly after.'
        : 'Signals are syncing. Your recovery score lands after your next '
            'logged sleep.';
  }
  final band = RecoveryBand.of(rec);
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
