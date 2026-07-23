import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/health_models.dart';
import 'package:pulsiq/domain/whoop.dart';
import 'package:pulsiq/health/body_signals.dart';

DailyBiometrics day(
  int d, {
  double? hrv,
  double? rhr,
  double? sleep,
  int? steps,
  int? active,
  double? resp,
}) =>
    DailyBiometrics(
      day: DateTime(2026, 7, d),
      hrvMs: hrv,
      restingHr: rhr,
      sleepHours: sleep,
      steps: steps,
      zone2Minutes: active,
      respiratoryRate: resp,
    );

void main() {
  group('mapping platform health into the card model', () {
    test('carries HRV, resting HR, sleep, steps and active minutes', () {
      final body = bodyFromBiometrics([
        day(1, hrv: 55, rhr: 58, sleep: 7.5, steps: 9000, active: 40),
      ]);
      final d = body.days.single;
      expect(d.hrvMs, 55);
      expect(d.restingHr, 58);
      expect(d.sleepHours, 7.5);
      expect(d.steps, 9000);
      expect(d.exerciseMinutes, 40);
    });

    test('leaves recovery and strain null — no source invents them', () {
      final d = bodyFromBiometrics([day(1, hrv: 55)]).days.single;
      expect(d.recoveryPct, isNull);
      expect(d.strain, isNull);
    });

    test('a day with only steps still counts as data, not empty', () {
      // Steps alone used to read as isEmpty, which hid the whole card for
      // anyone whose phone tracks movement but not sleep or HRV.
      final body = bodyFromBiometrics([day(1, steps: 12000)]);
      expect(body.isEmpty, isFalse);
      expect(body.latest?.steps, 12000);
    });

    test('averages skip missing days rather than counting them as zero', () {
      final body = bodyFromBiometrics([
        day(1, hrv: 50, steps: 10000),
        day(2, steps: 20000), // no HRV this day
        day(3, hrv: 70, steps: 30000),
      ]);
      expect(body.average((d) => d.hrvMs), 60);
      expect(body.average((d) => d.steps), 20000);
      expect(body.samples((d) => d.hrvMs), 2);
      expect(body.samples((d) => d.steps), 3);
    });

    test('latest is the most recent day carrying signal', () {
      final body = bodyFromBiometrics([
        day(1, hrv: 50),
        day(2, hrv: 60),
        day(3), // empty trailing day
      ]);
      expect(body.latest?.hrvMs, 60);
    });
  });

  group('source capabilities drive what the card shows', () {
    test('only WHOOP claims recovery and strain', () {
      expect(BodySignalSource.whoop.hasRecoveryAndStrain, isTrue);
      expect(BodySignalSource.appleHealth.hasRecoveryAndStrain, isFalse);
      expect(BodySignalSource.healthConnect.hasRecoveryAndStrain, isFalse);
    });

    test('only the phone platforms claim steps', () {
      expect(BodySignalSource.appleHealth.hasSteps, isTrue);
      expect(BodySignalSource.healthConnect.hasSteps, isTrue);
      expect(BodySignalSource.whoop.hasSteps, isFalse);
    });

    test('each source names itself for the averages heading', () {
      expect(BodySignalSource.appleHealth.label, 'Apple Health');
      expect(BodySignalSource.whoop.label, 'WHOOP');
    });
  });

  group('insight for sources without a recovery score', () {
    WhoopBody windowWith(List<DailyBiometrics> days) =>
        bodyFromBiometrics(days);

    test('never promises a recovery score that will never arrive', () {
      final w = windowWith([day(1, hrv: 50, rhr: 60, sleep: 7)]);
      final text = platformInsight(w.latest!, w);
      expect(text.toLowerCase(), isNot(contains('recovery score')));
    });

    test('calls out HRV above the window average', () {
      final w = windowWith([
        day(1, hrv: 50),
        day(2, hrv: 50),
        day(3, hrv: 70),
      ]);
      expect(platformInsight(w.latest!, w), contains('above'));
    });

    test('calls out HRV below the window average', () {
      final w = windowWith([
        day(1, hrv: 70),
        day(2, hrv: 70),
        day(3, hrv: 45),
      ]);
      expect(platformInsight(w.latest!, w), contains('below'));
    });

    test('flags an elevated resting heart rate when HRV is steady', () {
      final w = windowWith([
        day(1, rhr: 55),
        day(2, rhr: 55),
        day(3, rhr: 62),
      ]);
      expect(platformInsight(w.latest!, w), contains('Resting heart rate'));
    });

    test('flags a short night', () {
      final w = windowWith([day(1, sleep: 5.2)]);
      expect(platformInsight(w.latest!, w), contains('5.2h'));
    });

    test('says something sane when a day has no numbers at all', () {
      final w = windowWith([day(1)]);
      expect(platformInsight(w.latest!, w), isNotEmpty);
    });
  });
}
