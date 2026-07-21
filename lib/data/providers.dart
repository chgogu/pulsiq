import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hydration_target.dart';
import '../domain/pulsiq_score.dart';
import 'db/app_database.dart';
import 'log_repository.dart';
import 'weather/weather_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final logRepositoryProvider =
    Provider<LogRepository>((ref) => LogRepository(ref.watch(appDatabaseProvider)));

final todayHydrationMlProvider = StreamProvider<int>(
    (ref) => ref.watch(appDatabaseProvider).watchTodayHydrationMl());

final todayExerciseMinutesProvider = StreamProvider<int>(
    (ref) => ref.watch(appDatabaseProvider).watchTodayExerciseMinutes());

final todayDiureticMlProvider = StreamProvider<(int, int)>(
    (ref) => ref.watch(appDatabaseProvider).watchTodayDiureticMl());

final weatherProvider = FutureProvider<WeatherSnapshot?>(
    (ref) => WeatherService(ref.watch(appDatabaseProvider)).current());

/// Recomputed on every log event (§3) because it watches the log streams.
final hydrationTargetProvider = Provider<int>((ref) {
  final weather = ref.watch(weatherProvider).value;
  final exercise = ref.watch(todayExerciseMinutesProvider).value ?? 0;
  final (caffeine, alcohol) =
      ref.watch(todayDiureticMlProvider).value ?? (0, 0);
  return computeHydrationTargetMl(HydrationTargetInput(
    tempC: weather?.tempC,
    humidityPct: weather?.humidityPct,
    exerciseMinutes: exercise,
    caffeineMl: caffeine,
    alcoholMl: alcohol,
  ));
});

final _todayFoodsProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayFoods());
final _todayBeveragesProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayBeverages());
final _todayHydrationProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayHydration());
final _todayExerciseProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayExercise());

final logFeedProvider = Provider<AsyncValue<List<LogItem>>>((ref) {
  final foods = ref.watch(_todayFoodsProvider);
  final beverages = ref.watch(_todayBeveragesProvider);
  final hydration = ref.watch(_todayHydrationProvider);
  final exercise = ref.watch(_todayExerciseProvider);
  for (final v in [foods, beverages, hydration, exercise]) {
    if (v.hasError) return AsyncError(v.error!, v.stackTrace!);
    if (!v.hasValue) return const AsyncLoading();
  }
  final items = <LogItem>[
    ...foods.requireValue.map(foodToItem),
    ...beverages.requireValue.map(beverageToItem),
    ...hydration.requireValue.map(hydrationToItem),
    ...exercise.requireValue.map(exerciseToItem),
  ]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  return AsyncData(items);
});

final auditTrailProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchAudit());

/// Fuel quality from today's food logs: clean=1.0, moderate=0.6, dense=0.25,
/// averaged. Null (component absent) until something is logged.
final fuelQualityProvider = Provider<double?>((ref) {
  final foods = ref.watch(_todayFoodsProvider).value;
  if (foods == null || foods.isEmpty) return null;
  const scores = {
    FuelQuality.clean: 1.0,
    FuelQuality.moderate: 0.6,
    FuelQuality.dense: 0.25,
  };
  final total = foods.fold(0.0, (sum, f) => sum + scores[f.qualityScore]!);
  return total / foods.length;
});

/// Cardiac + sleep stay mocked until M5 wires HealthKit/Health Connect;
/// fuel and hydration are live from the local DB.
final scoreInputProvider = Provider<PulsIQScoreInput>((ref) {
  final consumed = ref.watch(todayHydrationMlProvider).value ?? 0;
  final target = ref.watch(hydrationTargetProvider);
  return PulsIQScoreInput(
    cardiacRecovery: 0.82,
    sleepQuality: 0.76,
    fuelQuality: ref.watch(fuelQualityProvider),
    hydrationProgress: target == 0 ? 0 : (consumed / target).clamp(0.0, 1.0),
  );
});

final scoreResultProvider =
    Provider((ref) => computePulsIQScore(ref.watch(scoreInputProvider)));
