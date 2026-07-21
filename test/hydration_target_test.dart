import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/hydration_target.dart';

void main() {
  group('computeHydrationTargetMl', () {
    test('base target with no adjustments is 2000', () {
      expect(computeHydrationTargetMl(const HydrationTargetInput()), 2000);
    });

    test('hot weather adds 500, warm adds 250', () {
      expect(
          computeHydrationTargetMl(const HydrationTargetInput(tempC: 32)),
          2500);
      expect(
          computeHydrationTargetMl(const HydrationTargetInput(tempC: 27)),
          2250);
    });

    test('humidity only counts when warm', () {
      expect(
        computeHydrationTargetMl(
            const HydrationTargetInput(tempC: 27, humidityPct: 75)),
        2500,
      );
      expect(
        computeHydrationTargetMl(
            const HydrationTargetInput(tempC: 20, humidityPct: 80)),
        2000,
      );
    });

    test('exercise adds ~12 ml per minute, rounded to 50', () {
      expect(
        computeHydrationTargetMl(
            const HydrationTargetInput(exerciseMinutes: 30)),
        2350, // 2000 + 360 → 2350
      );
      expect(
        computeHydrationTargetMl(
            const HydrationTargetInput(exerciseMinutes: 7)),
        2100, // 2000 + 84 → 2100
      );
    });

    test('caffeine and alcohol offset 1:1', () {
      expect(
        computeHydrationTargetMl(const HydrationTargetInput(caffeineMl: 300)),
        2300,
      );
      expect(
        computeHydrationTargetMl(
            const HydrationTargetInput(caffeineMl: 300, alcoholMl: 150)),
        2450,
      );
    });

    test('target is capped at 5000', () {
      expect(
        computeHydrationTargetMl(const HydrationTargetInput(
          tempC: 35,
          exerciseMinutes: 200,
          caffeineMl: 2000,
        )),
        5000,
      );
    });
  });
}
