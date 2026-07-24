import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/food_db.dart';
import '../domain/meal_vision.dart';
import '../llm/llm_client.dart';
import '../voice/voice_pipeline.dart' show llmCoachProvider;
import 'ai_settings.dart';
import 'db/app_database.dart' show AppDatabase, FuelQuality;
import 'foundation_model.dart';
import 'log_repository.dart';
import 'providers.dart';

/// The local food table, loaded once from the bundled asset. A Provider (not
/// FutureProvider) so callers can hold the Future and await it lazily.
final foodDbProvider = Provider<Future<FoodDb>>((ref) =>
    rootBundle.loadString('assets/nutrition/foods.json').then(FoodDb.parse));

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

/// Resolves a food description to macros through a cost cascade
/// (OFFLINE_NUTRITION_PROMPT): personal cache → local USDA table → Gemini.
/// The frontier model only runs when the free local tiers give up, and every
/// success is cached so the next identical meal is $0.
class MealEstimator {
  MealEstimator(
    this._coach,
    this._repo,
    this._db,
    this._foodDb, {
    FoundationModel fm = const FoundationModel(),
    Future<bool> Function() aiEnabled = _offlineOnly,
    // Private named fields can't be initializing formals.
    // ignore: prefer_initializing_formals
  })  : _fm = fm,
        // ignore: prefer_initializing_formals
        _aiEnabled = aiEnabled;

  final LlmCoach _coach;
  final LogRepository _repo;
  final AppDatabase _db;
  final Future<FoodDb> _foodDb;
  final FoundationModel _fm;

  /// Gates the cloud (Gemini) escalation. Default keeps everything on-device.
  final Future<bool> Function() _aiEnabled;
  static Future<bool> _offlineOnly() async => false;

  static String _normalize(String s) =>
      s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Cache → local table → LLM. Null only when all three miss (offline, no
  /// proxy, and nothing matched locally).
  Future<MealEstimate?> estimate(String description) async {
    final query = _normalize(description);
    if (query.isEmpty) return null;

    // 0. Personal cache — the cheapest request is the one never made.
    final cached = await _db.getMealCache(query);
    if (cached != null) {
      return MealEstimate(
        caloriesKcal: cached.caloriesKcal,
        proteinG: cached.proteinG,
        fiberG: cached.fiberG,
        carbsG: cached.carbsG,
        fatG: cached.fatG,
        quality: FuelQuality.values.byName(cached.quality),
        lowConfidence: false,
        itemCount: 1,
      );
    }

    // 1. Local USDA table — $0, offline, ground-truth numbers for the foods
    // it knows exactly.
    try {
      final db = await _foodDb;
      final local = db.resolve(query);
      if (local != null) {
        final est = MealEstimate(
          caloriesKcal: local.caloriesKcal,
          proteinG: local.proteinG,
          fiberG: local.fiberG,
          carbsG: local.carbsG,
          fatG: local.fatG,
          quality: FuelQuality.values.byName(local.quality),
          lowConfidence: false,
          itemCount: local.itemCount,
        );
        await _cache(query, est);
        return est;
      }
    } catch (_) {
      // asset missing / parse issue → fall through to the on-device model
    }

    // 2. Apple's on-device model (iOS 26+) — the real offline brain. It
    // estimates nutrition for anything the table couldn't (biryani, dosa, a
    // sentence with filler words), still $0, still private, still offline.
    if (await _fm.available()) {
      final raw = await _fm.estimateMeal(description);
      final est = raw == null ? null : _fromVisionJson(raw);
      if (est != null) {
        if (!est.lowConfidence) await _cache(query, est);
        return est;
      }
    }

    // 3. Cloud model — only when the user has opted into it. Off by default:
    // an unresolved food just means "log it manually," never a silent network
    // call.
    if (!await _aiEnabled()) return null;
    final raw = await _coach.estimateMealFromText(description);
    final est = raw == null ? null : _fromVisionJson(raw);
    if (est != null && !est.lowConfidence) await _cache(query, est);
    return est;
  }

  /// Parse a MEAL_SCHEMA reply (on-device or cloud) into a summed estimate.
  MealEstimate? _fromVisionJson(String raw) {
    try {
      final result = parseMealVision(raw);
      if (result.items.isEmpty) return null;
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
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(String query, MealEstimate est) => _db.putMealCache(
        query,
        caloriesKcal: est.caloriesKcal,
        proteinG: est.proteinG,
        fiberG: est.fiberG,
        carbsG: est.carbsG,
        fatG: est.fatG,
        quality: est.quality.name,
      );

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

  /// Same, for a beverage — only calories are stored (a plain tea/coffee
  /// resolves to ~0, a juice or latte to a real number that joins intake).
  Future<void> estimateAndPatchBeverage(int beverageId, String description) async {
    final est = await estimate(description);
    if (est == null) return;
    await _repo.patchBeverageCalories(beverageId, est.caloriesKcal);
  }
}

final mealEstimatorProvider = Provider<MealEstimator>(
  (ref) => MealEstimator(
    ref.read(llmCoachProvider),
    ref.read(logRepositoryProvider),
    ref.read(appDatabaseProvider),
    ref.read(foodDbProvider),
    fm: ref.read(foundationModelProvider),
    aiEnabled: () async => aiAssistEnabled(ref),
  ),
);
