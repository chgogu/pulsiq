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
