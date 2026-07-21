import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/daily_insights.dart';
import '../domain/daily_spark.dart';
import '../domain/nutrition.dart';
import '../domain/nutrition_advice.dart';
import 'providers.dart';

final macroTotalsProvider = StreamProvider<MacroTotals>(
    (ref) => ref.watch(appDatabaseProvider).watchMacroTotals());

/// Set to `manual` once the user types their own targets; cleared back to
/// `auto` by "Use my body profile".
const targetsModeKey = 'targets_mode';

/// Daily targets, in precedence order: hand-typed overrides, then numbers
/// derived from the body profile, then flat defaults.
final nutritionTargetsProvider = FutureProvider<NutritionTargets>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  if (await db.getSetting(targetsModeKey) == 'manual') {
    final entries = <String, String?>{};
    for (final key in const [
      'target_calories',
      'target_protein_g',
      'target_fiber_g',
      'target_carbs_g',
      'target_fat_g',
    ]) {
      entries[key] = await db.getSetting(key);
    }
    return NutritionTargets.fromSettings((k) => entries[k]);
  }
  final body = await ref.watch(bodyProfileProvider.future);
  return body?.derivedTargets ?? const NutritionTargets();
});

/// Count of today's food entries — gates the cut-down advice (needs ≥2).
final mealsLoggedTodayProvider = Provider<int>((ref) {
  return ref.watch(todayFoodsProvider).value?.length ?? 0;
});

final nutritionAdviceProvider = Provider<NutritionAdvice>((ref) {
  final totals = ref.watch(macroTotalsProvider).value ?? const MacroTotals.zero();
  final targets =
      ref.watch(nutritionTargetsProvider).value ?? const NutritionTargets();
  return computeNutritionAdvice(
    totals: totals,
    targets: targets,
    mealsLogged: ref.watch(mealsLoggedTodayProvider),
  );
});

/// 7-day macro history for the trend chart.
final macroHistoryProvider = FutureProvider(
    (ref) => ref.watch(appDatabaseProvider).macrosByDay(7));

/// Observations and next-meal suggestions read off today's log.
final dailyInsightsProvider = Provider<List<DailyInsight>>((ref) {
  return computeDailyInsights(InsightsInput(
    totals: ref.watch(macroTotalsProvider).value ?? const MacroTotals.zero(),
    targets:
        ref.watch(nutritionTargetsProvider).value ?? const NutritionTargets(),
    now: DateTime.now(),
    hydrationMl: ref.watch(todayHydrationMlProvider).value ?? 0,
    hydrationTargetMl: ref.watch(hydrationTargetProvider),
    mealsLogged: ref.watch(mealsLoggedTodayProvider),
    exerciseMinutes: ref.watch(todayExerciseMinutesProvider).value ?? 0,
    body: ref.watch(bodyProfileProvider).value,
  ));
});

/// Quote and joke of the day. Keyed to the date so it is stable until
/// midnight rather than reshuffling on every rebuild.
final dailySparkProvider =
    Provider<DailySpark>((ref) => sparkFor(DateTime.now()));
