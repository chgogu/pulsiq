/// Rolling-baseline engine (spec §3): every biometric shown anywhere is
/// presented relative to the user's own 7-day and 30-day baselines,
/// computed on-device. Baselines exclude today (today is what gets
/// compared) and need at least [minSamples] points to exist at all — no
/// fake confidence from two data points.
library;

class BaselineResult {
  const BaselineResult({this.today, this.avg7, this.avg30});

  final double? today;
  final double? avg7;
  final double? avg30;

  double? get delta7 =>
      (today != null && avg7 != null) ? today! - avg7! : null;

  double? get delta30 =>
      (today != null && avg30 != null) ? today! - avg30! : null;

  bool get hasBaseline => avg7 != null;
}

const minSamples = 3;

/// [series] holds (day, value) points, any order, nulls allowed.
/// [today]'s value (if present in the series) becomes `today` and is
/// excluded from both averages.
BaselineResult computeBaseline(
  List<({DateTime day, double? value})> series,
  DateTime today,
) {
  final dayOnly = DateTime(today.year, today.month, today.day);
  double? todayValue;
  final prior = <({DateTime day, double value})>[];
  for (final point in series) {
    final v = point.value;
    if (v == null) continue;
    final d = DateTime(point.day.year, point.day.month, point.day.day);
    if (d == dayOnly) {
      todayValue = v;
    } else if (d.isBefore(dayOnly)) {
      prior.add((day: d, value: v));
    }
  }

  double? windowAvg(int days) {
    final cutoff = dayOnly.subtract(Duration(days: days));
    final window = [
      for (final p in prior)
        if (!p.day.isBefore(cutoff)) p.value,
    ];
    if (window.length < minSamples) return null;
    return window.reduce((a, b) => a + b) / window.length;
  }

  return BaselineResult(
    today: todayValue,
    avg7: windowAvg(7),
    avg30: windowAvg(30),
  );
}

double _clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

/// Cardiac recovery component for the PulsIQ Score (40% weight): HRV above
/// its 7-day baseline and RHR below its baseline both read as recovery.
/// ±20% off baseline maps to the full 0..1 range around a 0.5 midpoint.
double? cardiacRecoveryComponent({
  required BaselineResult hrv,
  required BaselineResult rhr,
}) {
  double? hrvScore;
  if (hrv.today != null && hrv.avg7 != null && hrv.avg7! > 0) {
    hrvScore = _clamp01(0.5 + (hrv.today! - hrv.avg7!) / hrv.avg7! * 2.5);
  }
  double? rhrScore;
  if (rhr.today != null && rhr.avg7 != null && rhr.avg7! > 0) {
    rhrScore = _clamp01(0.5 - (rhr.today! - rhr.avg7!) / rhr.avg7! * 2.5);
  }
  if (hrvScore == null && rhrScore == null) return null;
  if (hrvScore == null) return rhrScore;
  if (rhrScore == null) return hrvScore;
  return (hrvScore + rhrScore) / 2;
}

/// Sleep component (25% weight): duration against an 8h ideal (60%) plus
/// efficiency (40%); falls back to duration alone.
double? sleepQualityComponent({
  double? lastNightHours,
  double? efficiencyPct,
}) {
  if (lastNightHours == null && efficiencyPct == null) return null;
  final duration =
      lastNightHours == null ? null : _clamp01(lastNightHours / 8.0);
  final efficiency =
      efficiencyPct == null ? null : _clamp01(efficiencyPct / 100.0);
  if (duration == null) return efficiency;
  if (efficiency == null) return duration;
  return duration * 0.6 + efficiency * 0.4;
}

/// Morning Recovery Reset trigger (spec §3): before 11am when last night's
/// sleep was short or RHR runs hot over the 7-day baseline.
bool morningResetDue({
  required DateTime now,
  double? lastNightSleepHours,
  required BaselineResult rhr,
}) {
  if (now.hour >= 11) return false;
  final shortSleep =
      lastNightSleepHours != null && lastNightSleepHours < 6.5;
  final hotRhr = rhr.delta7 != null && rhr.delta7! > 5;
  return shortSleep || hotRhr;
}

/// One plain-language correlation line for coaching messages (spec §3/§5),
/// citing the strongest current signal. Null when there's nothing notable.
String? correlationNote({
  required BaselineResult rhr,
  required BaselineResult hrv,
  double? lastNightSleepHours,
}) {
  final rhrDelta = rhr.delta7;
  final hrvDelta = hrv.delta7;
  if (rhrDelta != null && rhrDelta > 3) {
    return 'Heads up: your heart is running '
        '${rhrDelta.round()} beats over baseline this morning — easy fuel '
        'and extra water help it settle.';
  }
  if (lastNightSleepHours != null && lastNightSleepHours < 6.5) {
    return 'Short night (${lastNightSleepHours.toStringAsFixed(1)}h) — '
        'steady, clean fuel beats a sugar bump today.';
  }
  if (hrvDelta != null && hrv.avg7 != null && hrvDelta > hrv.avg7! * 0.08) {
    return 'Recovery is trending up — your HRV is riding '
        '${hrvDelta.round()} ms over baseline. Good day to move.';
  }
  if (rhrDelta != null && rhrDelta < -3) {
    return "Your heart's running ${rhrDelta.abs().round()} beats calmer "
        'than usual — recovery is landing.';
  }
  return null;
}
