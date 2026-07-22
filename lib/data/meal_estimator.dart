import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/meal_vision.dart';
import '../llm/llm_client.dart';
import '../voice/voice_pipeline.dart' show llmCoachProvider;
import 'db/app_database.dart' show FuelQuality;
import 'log_repository.dart';
import 'providers.dart';

/// The macros a written meal description resolves to, summed across the
/// dish's components.
class MealEstimate {
  const MealEstimate({
    required this.caloriesKcal,
    required this.proteinG,
    required this.fiberG,
    required this.carbsG,
    required this.fatG,
    required this.quality,
    required this.lowConfidence,
    required this.itemCount,
  });

  final int caloriesKcal;
  final double proteinG;
  final double fiberG;
  final double carbsG;
  final double fatG;
  final FuelQuality quality;
  final bool lowConfidence;
  final int itemCount;
}

/// Turns a food description into nutrition numbers via the LLM, and can patch
/// them onto an already-saved row. One place so the manual sheet, its inline
/// "estimate" button, and the save-time auto-fill all behave identically.
class MealEstimator {
  MealEstimator(this._coach, this._repo);

  final LlmCoach _coach;
  final LogRepository _repo;

  /// Estimate from text; null when both backends fail (offline with no
  /// reachable proxy, and the description matched nothing in the mock table).
  Future<MealEstimate?> estimate(String description) async {
    final text = description.trim();
    if (text.isEmpty) return null;
    final raw = await _coach.estimateMealFromText(text);
    if (raw == null) return null;
    final MealVisionResult result;
    try {
      result = parseMealVision(raw);
    } catch (_) {
      return null;
    }
    return MealEstimate(
      caloriesKcal: result.totalCalories,
      proteinG: result.totalProtein,
      fiberG: result.totalFiber,
      carbsG: result.totalCarbs,
      fatG: result.totalFat,
      quality: FuelQuality.values.byName(result.overallQuality),
      lowConfidence: result.lowConfidence,
      itemCount: result.items.length,
    );
  }

  /// Fire-and-forget: estimate [description] and write the macros onto row
  /// [foodId]. Silently does nothing on failure — the row keeps its (empty)
  /// macros and simply doesn't contribute to the day's totals, exactly as an
  /// un-estimated entry would.
  Future<void> estimateAndPatch(int foodId, String description) async {
    final est = await estimate(description);
    if (est == null) return;
    await _repo.patchFoodMacros(
      foodId,
      caloriesKcal: est.caloriesKcal,
      proteinG: est.proteinG,
      fiberG: est.fiberG,
      carbsG: est.carbsG,
      fatG: est.fatG,
      quality: est.quality,
    );
  }
}

final mealEstimatorProvider = Provider<MealEstimator>(
  (ref) => MealEstimator(
    ref.read(llmCoachProvider),
    ref.read(logRepositoryProvider),
  ),
);
