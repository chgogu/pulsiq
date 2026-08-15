import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/health_score.dart';
import 'package:pulsiq/domain/whoop.dart';

WhoopDay _day(
  DateTime d, {
  int? recovery,
  double? hrv,
  double? rhr,
  double? sleep,
  double? sleepPerf,
  int? steps,
}) =>
    WhoopDay(
      day: d,
      recoveryPct: recovery,
      hrvMs: hrv,
      restingHr: rhr,
      sleepHours: sleep,
      sleepPerformancePct: sleepPerf,
      steps: steps,
    );

void main() {
  test('empty window scores null', () {
    expect(computeHealthScore(const WhoopBody([])).value, isNull);
    expect(averageHealthScore(const WhoopBody([])), isNull);
  });

  test('WHOOP: recovery drives the score', () {
    final base = DateTime(2026, 8, 10);
    final low = WhoopBody([
      _day(base, recovery: 30, hrv: 50, rhr: 60, sleep: 7),
    ]);
    final high = WhoopBody([
      _day(base, recovery: 90, hrv: 50, rhr: 60, sleep: 7),
    ]);
    expect(computeHealthScore(high).value! > computeHealthScore(low).value!,
        isTrue);
    // High recovery pulls the composite into good-or-better territory.
    expect(computeHealthScore(high).value! >= 65, isTrue);
  });

  test('Apple-only (no recovery) still scores from hrv/rhr/sleep/steps', () {
    final base = DateTime(2026, 8, 10);
    final body = WhoopBody([
      _day(base.subtract(const Duration(days: 1)),
          hrv: 55, rhr: 60, sleep: 7, steps: 6000),
      _day(base, hrv: 60, rhr: 58, sleep: 7.5, steps: 9000),
    ]);
    final score = computeHealthScore(body);
    expect(score.value, isNotNull);
    expect(score.parts.containsKey(HealthComponent.recovery), isFalse);
    expect(score.parts.containsKey(HealthComponent.activity), isTrue);
  });

  test('higher HRV and lower resting HR raise the score vs baseline', () {
    final base = DateTime(2026, 8, 10);
    // window of two days establishing a baseline; latest is the "good" day
    final good = WhoopBody([
      _day(base.subtract(const Duration(days: 1)), hrv: 50, rhr: 62, sleep: 7),
      _day(base, hrv: 70, rhr: 54, sleep: 7),
    ]);
    final bad = WhoopBody([
      _day(base.subtract(const Duration(days: 1)), hrv: 70, rhr: 54, sleep: 7),
      _day(base, hrv: 50, rhr: 62, sleep: 7),
    ]);
    expect(
        computeHealthScore(good).value! > computeHealthScore(bad).value!, isTrue);
  });

  test('dailyHealthScores covers every signal-bearing day; average matches', () {
    final base = DateTime(2026, 8, 10);
    final body = WhoopBody([
      _day(base.subtract(const Duration(days: 2)), recovery: 40, hrv: 50, rhr: 60),
      _day(base.subtract(const Duration(days: 1)), recovery: 60, hrv: 55, rhr: 58),
      _day(base, recovery: 80, hrv: 60, rhr: 56),
    ]);
    final series = dailyHealthScores(body);
    expect(series.length, 3);
    final mean =
        (series.fold<int>(0, (s, e) => s + e.score) / series.length).round();
    expect(averageHealthScore(body), mean);
  });

  test('bands map at their thresholds', () {
    expect(HealthBand.of(80), HealthBand.excellent);
    expect(HealthBand.of(65), HealthBand.good);
    expect(HealthBand.of(50), HealthBand.fair);
    expect(HealthBand.of(49), HealthBand.low);
  });
}
