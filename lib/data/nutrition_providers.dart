import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/nutrition.dart';
import '../domain/nutrition_advice.dart';
import 'providers.dart';

final macroTotalsProvider = StreamProvider<MacroTotals>(
    (ref) => ref.watch(appDatabaseProvider).watchMacroTotals());

/// Editable daily targets, loaded from settings (defaults in [NutritionTargets]).
final nutritionTargetsProvider = FutureProvider<NutritionTargets>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final entries = <String, String?>{};
  for (final key in const [
    'target_calories',
    'target_protein_g',
    'target_fiber_g',
  ]) {
    entries[key] = await db.getSetting(key);
  }
  return NutritionTargets.fromSettings((k) => entries[k]);
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
