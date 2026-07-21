import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/pulsiq_score.dart';

void main() {
  group('computePulsIQScore', () {
    test('full inputs use the 40/25/20/15 weighting', () {
      final result = computePulsIQScore(
        const PulsIQScoreInput(
          cardiacRecovery: 0.82,
          sleepQuality: 0.76,
          fuelQuality: 0.64,
          hydrationProgress: 0.45,
        ),
      );
      // 0.82*0.40 + 0.76*0.25 + 0.64*0.20 + 0.45*0.15 = 0.7135
      expect(result.score, 71);
      expect(result.isFuelOnly, isFalse);
      expect(result.effectiveWeights[ScoreComponent.cardiac],
          closeTo(0.40, 1e-9));
      expect(
        result.effectiveWeights.values.fold(0.0, (a, b) => a + b),
        closeTo(1.0, 1e-9),
      );
    });

    test('no biometric components renormalizes and flags fuel-only', () {
      final result = computePulsIQScore(
        const PulsIQScoreInput(fuelQuality: 0.64, hydrationProgress: 0.45),
      );
      // Weights renormalize to 0.20/0.35 and 0.15/0.35.
      // 0.64*(4/7) + 0.45*(3/7) = 0.5586
      expect(result.score, 56);
      expect(result.isFuelOnly, isTrue);
      expect(result.effectiveWeights[ScoreComponent.fuel],
          closeTo(4 / 7, 1e-9));
      expect(result.effectiveWeights[ScoreComponent.hydration],
          closeTo(3 / 7, 1e-9));
    });

    test('one missing component renormalizes without fuel-only flag', () {
      final result = computePulsIQScore(
        const PulsIQScoreInput(
          sleepQuality: 0.76,
          fuelQuality: 0.64,
          hydrationProgress: 0.45,
        ),
      );
      // (0.76*0.25 + 0.64*0.20 + 0.45*0.15) / 0.60 = 0.6425
      expect(result.score, 64);
      expect(result.isFuelOnly, isFalse);
      expect(result.componentValues.containsKey(ScoreComponent.cardiac),
          isFalse);
    });

    test('sleep alone is biometric, so not fuel-only', () {
      final result =
          computePulsIQScore(const PulsIQScoreInput(sleepQuality: 0.8));
      expect(result.score, 80);
      expect(result.isFuelOnly, isFalse);
    });

    test('inputs are clamped to 0..1', () {
      final result = computePulsIQScore(
        const PulsIQScoreInput(cardiacRecovery: 1.7, sleepQuality: -0.3),
      );
      expect(result.componentValues[ScoreComponent.cardiac], 1.0);
      expect(result.componentValues[ScoreComponent.sleep], 0.0);
      // 1.0*(0.40/0.65) + 0.0 = 0.6154
      expect(result.score, 62);
    });

    test('no data at all yields a null score', () {
      final result = computePulsIQScore(const PulsIQScoreInput());
      expect(result.score, isNull);
      expect(result.isFuelOnly, isFalse);
      expect(result.componentValues, isEmpty);
      expect(result.effectiveWeights, isEmpty);
    });
  });
}
