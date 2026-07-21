import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pulsiq_score.dart';
import '../health/health_providers.dart';
import 'providers.dart';

/// Live PulsIQ Score input: cardiac + sleep from wearable baselines (null
/// until a source is connected → automatic fuel-only renormalization),
/// fuel + hydration from the local log DB.
final scoreInputProvider = Provider<PulsIQScoreInput>((ref) {
  final consumed = ref.watch(todayHydrationMlProvider).value ?? 0;
  final target = ref.watch(hydrationTargetProvider);
  return PulsIQScoreInput(
    cardiacRecovery: ref.watch(cardiacRecoveryProvider),
    sleepQuality: ref.watch(sleepQualityProvider),
    fuelQuality: ref.watch(fuelQualityProvider),
    hydrationProgress:
        target == 0 ? 0 : (consumed / target).clamp(0.0, 1.0),
  );
});

final scoreResultProvider =
    Provider((ref) => computePulsIQScore(ref.watch(scoreInputProvider)));
