import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/baseline_engine.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  List<({DateTime day, double? value})> series(Map<int, double?> daysAgo) => [
        for (final e in daysAgo.entries)
          (day: today.subtract(Duration(days: e.key)), value: e.value),
      ];

  group('computeBaseline', () {
    test('7- and 30-day averages exclude today', () {
      final r = computeBaseline(
        series({0: 58, 1: 60, 2: 62, 3: 64, 10: 70, 20: 80}),
        today,
      );
      expect(r.today, 58);
      expect(r.avg7, (60 + 62 + 64) / 3); // 62
      expect(r.avg30, (60 + 62 + 64 + 70 + 80) / 5); // 67.2
      expect(r.delta7, -4);
    });

    test('needs at least 3 samples per window', () {
      final r = computeBaseline(series({0: 58, 1: 60, 2: 61}), today);
      expect(r.avg7, isNull); // only 2 prior points in window
      expect(r.avg30, isNull);
      expect(r.hasBaseline, isFalse);
    });

    test('nulls in the series are skipped, order does not matter', () {
      final r = computeBaseline(
        series({5: 61, 1: 60, 3: null, 2: 62, 4: 65}),
        today,
      );
      expect(r.today, isNull);
      expect(r.avg7, (60 + 62 + 65 + 61) / 4);
    });

    test('points outside the 7-day window only feed the 30-day average',
        () {
      final r = computeBaseline(
        series({1: 60, 2: 60, 3: 60, 8: 90, 9: 90, 29: 90}),
        today,
      );
      expect(r.avg7, 60);
      expect(r.avg30, (60 * 3 + 90 * 3) / 6);
    });
  });

  group('score components', () {
    test('cardiac: HRV up and RHR down over baseline scores high', () {
      final score = cardiacRecoveryComponent(
        hrv: const BaselineResult(today: 72, avg7: 60),
        rhr: const BaselineResult(today: 56, avg7: 62),
      );
      expect(score, greaterThan(0.85));
    });

    test('cardiac: both trending badly scores low', () {
      final score = cardiacRecoveryComponent(
        hrv: const BaselineResult(today: 48, avg7: 60),
        rhr: const BaselineResult(today: 70, avg7: 62),
      );
      expect(score, lessThan(0.2));
    });

    test('cardiac: null without any baseline', () {
      expect(
        cardiacRecoveryComponent(
          hrv: const BaselineResult(today: 60),
          rhr: const BaselineResult(),
        ),
        isNull,
      );
    });

    test('sleep: blends duration and efficiency, falls back to duration',
        () {
      expect(
        sleepQualityComponent(lastNightHours: 8, efficiencyPct: 100),
        1.0,
      );
      final blended =
          sleepQualityComponent(lastNightHours: 6, efficiencyPct: 90)!;
      expect(blended, closeTo(0.6 * 0.75 + 0.4 * 0.9, 1e-9));
      expect(sleepQualityComponent(lastNightHours: 4), 0.5);
      expect(sleepQualityComponent(), isNull);
    });
  });

  group('morningResetDue', () {
    final rhrHot = const BaselineResult(today: 68, avg7: 61);
    final rhrNormal = const BaselineResult(today: 62, avg7: 61);

    test('fires before 11am on short sleep or hot RHR', () {
      final at9 = DateTime(2026, 7, 21, 9);
      expect(
        morningResetDue(now: at9, lastNightSleepHours: 5.9, rhr: rhrNormal),
        isTrue,
      );
      expect(
        morningResetDue(now: at9, lastNightSleepHours: 7.5, rhr: rhrHot),
        isTrue,
      );
      expect(
        morningResetDue(now: at9, lastNightSleepHours: 7.5, rhr: rhrNormal),
        isFalse,
      );
    });

    test('never fires from 11am', () {
      final at11 = DateTime(2026, 7, 21, 11);
      expect(
        morningResetDue(now: at11, lastNightSleepHours: 4, rhr: rhrHot),
        isFalse,
      );
    });
  });

  group('correlationNote', () {
    test('hot RHR wins over other signals', () {
      final note = correlationNote(
        rhr: const BaselineResult(today: 67, avg7: 61),
        hrv: const BaselineResult(today: 80, avg7: 60),
        lastNightSleepHours: 5.0,
      );
      expect(note, contains('6 beats over baseline'));
    });

    test('short sleep noted when RHR is fine', () {
      final note = correlationNote(
        rhr: const BaselineResult(today: 61, avg7: 61),
        hrv: const BaselineResult(),
        lastNightSleepHours: 5.5,
      );
      expect(note, contains('Short night'));
    });

    test('silent when nothing notable', () {
      final note = correlationNote(
        rhr: const BaselineResult(today: 61, avg7: 61),
        hrv: const BaselineResult(today: 60, avg7: 60),
        lastNightSleepHours: 7.4,
      );
      expect(note, isNull);
    });
  });
}
