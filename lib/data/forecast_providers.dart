import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/baseline_engine.dart';
import '../domain/evening_forecast.dart';
import '../health/health_providers.dart';
import 'providers.dart';

/// Evening forecast appears from 7pm local (spec §3). A dev override lets
/// the web preview show it any time.
final forecastVisibleProvider = Provider<bool>((ref) {
  if (ref.watch(forceForecastProvider)) return true;
  return DateTime.now().hour >= 19;
});

class ForceForecast extends Notifier<bool> {
  @override
  bool build() => false;
  @override
  set state(bool value) => super.state = value;
}

final forceForecastProvider =
    NotifierProvider<ForceForecast, bool>(ForceForecast.new);

final eveningForecastProvider = Provider<Forecast?>((ref) {
  final baselines = ref.watch(baselinesProvider);
  final exercise = ref.watch(todayExerciseMinutesProvider).value ?? 0;
  final consumed = ref.watch(todayHydrationMlProvider).value ?? 0;
  final target = ref.watch(hydrationTargetProvider);
  final denseFuel = ref.watch(_todayDenseFuelCountProvider);
  final lateCaffeine = ref.watch(_lateCaffeineProvider);

  // Forecast needs at least a biometric trend or a full day of logs.
  if (baselines == null && exercise == 0 && denseFuel == 0) return null;

  return computeForecast(ForecastInput(
    rhr: baselines?.rhr ?? const BaselineResult(),
    hrv: baselines?.hrv ?? const BaselineResult(),
    exerciseMinutes: exercise,
    denseFuelCount: denseFuel,
    lateCaffeine: lateCaffeine,
    hydrationProgress: target == 0 ? 0 : consumed / target,
  ));
});

final _todayDenseFuelCountProvider = Provider<int>((ref) {
  final foods = ref.watch(todayFoodsProvider).value;
  if (foods == null) return 0;
  return foods.where((f) => f.qualityScore.name == 'dense').length;
});

final _lateCaffeineProvider = Provider<bool>((ref) {
  final beverages = ref.watch(todayBeveragesProvider).value;
  if (beverages == null) return false;
  return beverages.any((b) =>
      b.type.name == 'caffeine' && b.loggedAt.hour >= 15);
});
