/// PulsIQ Score engine.
///
/// Weighted formula (spec §2): 40% cardiac recovery, 25% sleep, 20% fuel
/// quality, 15% hydration progress. Components missing from the input
/// renormalize the remaining weights so the score never pretends to have
/// data it doesn't. When no biometric component (cardiac, sleep) is
/// available at all, the result is flagged fuel-only.
library;

enum ScoreComponent { cardiac, sleep, fuel, hydration }

const scoreWeights = <ScoreComponent, double>{
  ScoreComponent.cardiac: 0.40,
  ScoreComponent.sleep: 0.25,
  ScoreComponent.fuel: 0.20,
  ScoreComponent.hydration: 0.15,
};

const _biometricComponents = {ScoreComponent.cardiac, ScoreComponent.sleep};

class PulsIQScoreInput {
  const PulsIQScoreInput({
    this.cardiacRecovery,
    this.sleepQuality,
    this.fuelQuality,
    this.hydrationProgress,
  });

  /// All values are normalized 0..1; null means "no data for this component".
  final double? cardiacRecovery;
  final double? sleepQuality;
  final double? fuelQuality;
  final double? hydrationProgress;

  double? valueOf(ScoreComponent component) => switch (component) {
        ScoreComponent.cardiac => cardiacRecovery,
        ScoreComponent.sleep => sleepQuality,
        ScoreComponent.fuel => fuelQuality,
        ScoreComponent.hydration => hydrationProgress,
      };
}

class PulsIQScoreResult {
  const PulsIQScoreResult({
    required this.score,
    required this.isFuelOnly,
    required this.componentValues,
    required this.effectiveWeights,
  });

  /// 0–100, or null when no component has data.
  final int? score;

  /// True when the score is built without any biometric component.
  final bool isFuelOnly;

  /// Clamped 0..1 values for the components that had data.
  final Map<ScoreComponent, double> componentValues;

  /// Renormalized weights over the available components (sums to 1).
  final Map<ScoreComponent, double> effectiveWeights;
}

PulsIQScoreResult computePulsIQScore(PulsIQScoreInput input) {
  final values = <ScoreComponent, double>{
    for (final c in ScoreComponent.values)
      if (input.valueOf(c) != null) c: input.valueOf(c)!.clamp(0.0, 1.0),
  };
  if (values.isEmpty) {
    return const PulsIQScoreResult(
      score: null,
      isFuelOnly: false,
      componentValues: {},
      effectiveWeights: {},
    );
  }
  final totalWeight =
      values.keys.fold(0.0, (sum, c) => sum + scoreWeights[c]!);
  final effectiveWeights = {
    for (final c in values.keys) c: scoreWeights[c]! / totalWeight,
  };
  final weighted = values.entries
      .fold(0.0, (sum, e) => sum + e.value * effectiveWeights[e.key]!);
  return PulsIQScoreResult(
    score: (weighted * 100).round().clamp(0, 100),
    isFuelOnly: values.keys.every((c) => !_biometricComponents.contains(c)),
    componentValues: values,
    effectiveWeights: effectiveWeights,
  );
}
