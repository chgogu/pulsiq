/// Per-source Health Score.
///
/// A single 0–100 read of "how is your health doing" for one day, scored
/// against the person's own window baseline and blended with absolute anchors.
/// Renormalizes over whatever metrics a source actually provides (WHOOP has a
/// recovery score; Apple Health has steps but no recovery), so the number never
/// pretends to have data it doesn't — same discipline as [pulsiq_score].
library;

import 'whoop.dart';

enum HealthComponent { recovery, hrv, restingHr, sleep, activity }

const _weights = <HealthComponent, double>{
  HealthComponent.recovery: 0.35,
  HealthComponent.hrv: 0.20,
  HealthComponent.restingHr: 0.15,
  HealthComponent.sleep: 0.20,
  HealthComponent.activity: 0.10,
};

enum HealthBand {
  excellent,
  good,
  fair,
  low;

  static HealthBand of(int score) => score >= 80
      ? HealthBand.excellent
      : score >= 65
          ? HealthBand.good
          : score >= 50
              ? HealthBand.fair
              : HealthBand.low;

  String get label => switch (this) {
        HealthBand.excellent => 'Excellent',
        HealthBand.good => 'Good',
        HealthBand.fair => 'Fair',
        HealthBand.low => 'Needs care',
      };
}

class HealthScore {
  const HealthScore({required this.value, required this.parts});

  /// 0–100, or null when no component had data.
  final int? value;
  final Map<HealthComponent, double> parts;

  HealthBand? get band => value == null ? null : HealthBand.of(value!);
}

/// 0.5 at the baseline, → 1.0 when [value] is [tolerance] better, → 0.0 when
/// [tolerance] worse. [tolerance] must be > 0.
double _relative(
  double value,
  double avg, {
  required bool higherIsBetter,
  required double tolerance,
}) {
  final delta = (value - avg) / tolerance;
  final signed = higherIsBetter ? delta : -delta;
  return (0.5 + 0.5 * signed).clamp(0.0, 1.0);
}

double _tol(double avg, double frac, double floor) {
  final t = avg.abs() * frac;
  return t < floor ? floor : t;
}

/// Scores [day] (defaults to the window's latest signal-bearing day) against
/// the [window]'s own averages.
HealthScore computeHealthScore(WhoopBody window, {WhoopDay? day}) {
  final d = day ?? window.latest;
  if (d == null) return const HealthScore(value: null, parts: {});

  final parts = <HealthComponent, double>{};

  if (d.recoveryPct != null) {
    parts[HealthComponent.recovery] = (d.recoveryPct! / 100).clamp(0.0, 1.0);
  }

  final avgHrv = window.average((x) => x.hrvMs);
  if (d.hrvMs != null && avgHrv != null && avgHrv > 0) {
    parts[HealthComponent.hrv] = _relative(d.hrvMs!, avgHrv,
        higherIsBetter: true, tolerance: _tol(avgHrv, 0.30, 5));
  }

  final avgRhr = window.average((x) => x.restingHr);
  if (d.restingHr != null && avgRhr != null && avgRhr > 0) {
    parts[HealthComponent.restingHr] = _relative(d.restingHr!, avgRhr,
        higherIsBetter: false, tolerance: _tol(avgRhr, 0.12, 4));
  }

  if (d.sleepPerformancePct != null) {
    parts[HealthComponent.sleep] =
        (d.sleepPerformancePct! / 100).clamp(0.0, 1.0);
  } else if (d.sleepHours != null) {
    parts[HealthComponent.sleep] = (d.sleepHours! / 8).clamp(0.0, 1.0);
  }

  if (d.steps != null) {
    parts[HealthComponent.activity] = (d.steps! / 8000).clamp(0.0, 1.0);
  } else if (d.exerciseMinutes != null) {
    parts[HealthComponent.activity] =
        (d.exerciseMinutes! / 45).clamp(0.0, 1.0);
  }

  if (parts.isEmpty) return const HealthScore(value: null, parts: {});

  final totalWeight =
      parts.keys.fold(0.0, (s, c) => s + _weights[c]!);
  final weighted = parts.entries
      .fold(0.0, (s, e) => s + e.value * (_weights[e.key]! / totalWeight));
  return HealthScore(
    value: (weighted * 100).round().clamp(0, 100),
    parts: parts,
  );
}

/// Per-day scores across the window (each day scored against the window
/// baseline) — the series behind the trend chart, average, and stored history.
List<({DateTime day, int score})> dailyHealthScores(WhoopBody window) => [
      for (final d in window.days)
        if (!d.isEmpty)
          if (computeHealthScore(window, day: d).value case final v?)
            (day: d.day, score: v),
    ];

/// Mean of the daily scores, or null when the window scores nothing.
int? averageHealthScore(WhoopBody window) {
  final scores = dailyHealthScores(window);
  if (scores.isEmpty) return null;
  return (scores.fold<int>(0, (s, e) => s + e.score) / scores.length).round();
}
