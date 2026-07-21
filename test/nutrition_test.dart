import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/log_repository.dart';
import 'package:pulsiq/domain/meal_vision.dart';
import 'package:pulsiq/domain/nutrition.dart';
import 'package:pulsiq/domain/nutrition_advice.dart';
import 'package:pulsiq/llm/llm_client.dart';

void main() {
  group('Meal-vision contract', () {
    const valid = '''
    {"confidence": "high",
     "items": [
       {"name": "Grilled chicken", "portion": "150g", "calories": 280,
        "protein_g": 35, "fiber_g": 1, "carbs_g": 4, "fat_g": 12,
        "quality_score": "clean"},
       {"name": "Rice", "portion": "1 cup", "calories": 200, "protein_g": 4,
        "fiber_g": 1, "carbs_g": 44, "fat_g": 1, "quality_score": "moderate"}
     ],
     "note": "Solid, steady fuel."}''';

    test('parses items and totals', () {
      final r = parseMealVision(valid);
      expect(r.items, hasLength(2));
      expect(r.totalCalories, 480);
      expect(r.totalProtein, 39);
      expect(r.confidence, 'high');
      expect(r.lowConfidence, isFalse);
    });

    test('rejects negative macros and bad quality', () {
      expect(() => parseMealVision(valid.replaceFirst('280', '-10')),
          throwsFormatException);
      expect(() => parseMealVision(valid.replaceFirst('"clean"', '"tasty"')),
          throwsFormatException);
    });

    test('rejects empty item list', () {
      expect(
        () => parseMealVision('{"confidence": "low", "items": []}'),
        throwsFormatException,
      );
    });

    test('parses JSON wrapped in prose/fences', () {
      final wrapped = 'Here you go:\n```json\n$valid\n```';
      expect(parseMealVision(wrapped).totalCalories, 480);
    });
  });

  group('MockLlmBackend.analyzeMealImage', () {
    test('estimates macros from a hint', () async {
      final raw = await const MockLlmBackend().analyzeMealImage(
          base64Image: '', hint: 'grilled salmon and salad');
      final r = parseMealVision(raw);
      expect(r.items.length, greaterThanOrEqualTo(2));
      expect(r.totalCalories, greaterThan(300));
      expect(r.confidence, 'medium');
    });

    test('falls back to a mixed plate with low confidence, no hint',
        () async {
      final raw = await const MockLlmBackend()
          .analyzeMealImage(base64Image: 'ZmFrZQ==');
      final r = parseMealVision(raw);
      expect(r.items, isNotEmpty);
      expect(r.confidence, 'low');
    });
  });

  group('MacroTotals aggregation', () {
    late AppDatabase db;
    late LogRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = LogRepository(db);
    });
    tearDown(() => db.close());

    test('sums macros across photo-logged foods', () async {
      await repo.addFood(
        name: 'Chicken',
        quantity: '150g',
        quality: FuelQuality.clean,
        caloriesKcal: 280,
        proteinG: 35,
        fiberG: 1,
        carbsG: 4,
        fatG: 12,
        source: 'photo',
      );
      await repo.addFood(
        name: 'Burrito',
        quantity: '1',
        quality: FuelQuality.dense,
        caloriesKcal: 640,
        proteinG: 26,
        fiberG: 12,
        carbsG: 78,
        fatG: 24,
        source: 'photo',
      );
      final totals = await db.watchMacroTotals().first;
      expect(totals.calories, 920);
      expect(totals.proteinG, 61);
      expect(totals.fiberG, 13);
    });

    test('foods without macros contribute zero, not null', () async {
      await repo.addFood(
          name: 'Voice note', quantity: 'oats', quality: FuelQuality.clean);
      final totals = await db.watchMacroTotals().first;
      expect(totals.calories, 0);
      expect(totals.isEmpty, isTrue);
    });
  });

  group('Cut-down advice engine', () {
    const targets = NutritionTargets();

    test('stays silent under 2 meals', () {
      final a = computeNutritionAdvice(
        totals: const MacroTotals(
            calories: 2600, proteinG: 40, fiberG: 5, carbsG: 300, fatG: 90),
        targets: targets,
        mealsLogged: 1,
      );
      expect(a.isEmpty, isTrue);
    });

    test('flags calories over + fiber short with concrete swaps', () {
      final a = computeNutritionAdvice(
        totals: const MacroTotals(
            calories: 2600, proteinG: 60, fiberG: 8, carbsG: 300, fatG: 70),
        targets: targets,
        mealsLogged: 3,
        now: DateTime(2026, 7, 21, 12),
      );
      expect(a.tips, isNotEmpty);
      expect(a.tips.first, contains('over')); // calories are the headline
      expect(a.tips.join(' '), contains('Fiber'));
    });

    test('congratulates a balanced day', () {
      final a = computeNutritionAdvice(
        totals: const MacroTotals(
            calories: 1950, proteinG: 105, fiberG: 32, carbsG: 200, fatG: 60),
        targets: targets,
        mealsLogged: 3,
        now: DateTime(2026, 7, 21, 20),
      );
      expect(a.headline.toLowerCase(), contains('balanced'));
    });

    test('caps at three tips', () {
      final a = computeNutritionAdvice(
        totals: const MacroTotals(
            calories: 3000, proteinG: 20, fiberG: 3, carbsG: 200, fatG: 130),
        targets: targets,
        mealsLogged: 4,
        now: DateTime(2026, 7, 21, 19),
      );
      expect(a.tips.length, lessThanOrEqualTo(3));
    });
  });
}
