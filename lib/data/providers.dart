import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/body_profile.dart';
import '../domain/hydration_target.dart';
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

/// The user's body profile, or null until they fill one in. Lives here rather
/// than in nutrition_providers because hydration needs it too.
final bodyProfileProvider = FutureProvider<BodyProfile?>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final entries = <String, String?>{};
  for (final key in BodyProfile.settingsKeys) {
    entries[key] = await db.getSetting(key);
  }
  final profile = BodyProfile.fromSettings((k) => entries[k]);
  return profile?.isUsable == true ? profile : null;
});

/// Recomputed on every log event (§3) because it watches the log streams.
final hydrationTargetProvider = Provider<int>((ref) {
  final weather = ref.watch(weatherProvider).value;
  final exercise = ref.watch(todayExerciseMinutesProvider).value ?? 0;
  final (caffeine, alcohol) =
      ref.watch(todayDiureticMlProvider).value ?? (0, 0);
  final boost = ref.watch(morningBoostProvider).value ?? 0;
  final body = ref.watch(bodyProfileProvider).value;
  return computeHydrationTargetMl(HydrationTargetInput(
        tempC: weather?.tempC,
        humidityPct: weather?.humidityPct,
        exerciseMinutes: exercise,
        caffeineMl: caffeine,
        alcoholMl: alcohol,
        baseMl: body?.baseHydrationMl,
      )) +
      boost;
});

final todayFoodsProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayFoods());
final todayBeveragesProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayBeverages());
final _todayHydrationProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayHydration());
final _todayExerciseProvider = StreamProvider(
    (ref) => ref.watch(appDatabaseProvider).watchTodayExercise());

final logFeedProvider = Provider<AsyncValue<List<LogItem>>>((ref) {
  final foods = ref.watch(todayFoodsProvider);
  final beverages = ref.watch(todayBeveragesProvider);
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
  final foods = ref.watch(todayFoodsProvider).value;
  if (foods == null || foods.isEmpty) return null;
  const scores = {
    FuelQuality.clean: 1.0,
    FuelQuality.moderate: 0.6,
    FuelQuality.dense: 0.25,
  };
  final total = foods.fold(0.0, (sum, f) => sum + scores[f.qualityScore]!);
  return total / foods.length;
});

/// Extra ml added to today's target by the Morning Recovery Reset.
final morningBoostProvider = FutureProvider<int>((ref) async {
  final now = DateTime.now();
  final v = await ref
      .watch(appDatabaseProvider)
      .getSetting('goal_boost_${now.year}-${now.month}-${now.day}');
  return int.tryParse(v ?? '0') ?? 0;
});
