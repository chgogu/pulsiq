import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/food_safety.dart';
import 'package:pulsiq/domain/health_goal.dart';

FoodSafetyInput food({
  String name = 'Food',
  int kcal = 200,
  double sugar = 5,
  double? satFat,
  double? sodium,
  String? ingredients,
}) =>
    FoodSafetyInput(
      name: name,
      caloriesKcal: kcal,
      sugarG: sugar,
      saturatedFatG: satFat,
      sodiumMg: sodium,
      ingredients: ingredients,
    );

void main() {
  test('no goals set → no answer to show', () {
    final v = assessFood(food(sugar: 40), {});
    expect(v.hasAnswer, isFalse);
  });

  group('diabetes', () {
    test('high sugar → No, with a one-line reason', () {
      final v = assessFood(food(sugar: 30), {HealthGoal.diabetes});
      expect(v.canEat, isFalse);
      expect(v.answer, 'No');
      expect(v.oneLiner, contains('sugar'));
    });
    test('moderate sugar is still Yes, with a caveat', () {
      final v = assessFood(food(sugar: 15), {HealthGoal.diabetes});
      expect(v.canEat, isTrue);
      expect(v.answer, 'Yes');
    });
    test('low sugar → Yes, no conflicts', () {
      final v = assessFood(food(sugar: 4), {HealthGoal.diabetes});
      expect(v.hasAnswer, isTrue);
      expect(v.canEat, isTrue);
      expect(v.oneLiner, contains('No conflicts'));
    });
  });

  group('pregnancy', () {
    test('alcohol is avoid', () {
      final v = assessFood(food(name: 'Red wine sauce'), {HealthGoal.pregnancy});
      expect(v.level, SafetyLevel.avoid);
    });
    test('raw/unpasteurized is avoid', () {
      final v = assessFood(
          food(name: 'Sushi platter', ingredients: 'raw salmon'),
          {HealthGoal.pregnancy});
      expect(v.level, SafetyLevel.avoid);
    });
    test('coffee is Yes with a caffeine caveat, not a block', () {
      final v = assessFood(food(name: 'Iced coffee'), {HealthGoal.pregnancy});
      expect(v.canEat, isTrue);
      expect(v.oneLiner.toLowerCase(), contains('caffeine'));
    });
  });

  group('heart health', () {
    test('high saturated fat → No', () {
      final v = assessFood(food(satFat: 12), {HealthGoal.heartHealth});
      expect(v.answer, 'No');
    });
    test('high sodium → No even when saturated fat is fine', () {
      final v = assessFood(food(satFat: 2, sodium: 1300), {HealthGoal.heartHealth});
      expect(v.answer, 'No');
    });
  });

  test('weight gain → Yes for a calorie-dense food', () {
    final v = assessFood(food(kcal: 600), {HealthGoal.weightGain});
    expect(v.answer, 'Yes');
    expect(v.oneLiner, contains('kcal'));
  });

  test('one conflicting goal makes the answer No', () {
    final v = assessFood(
      food(name: 'wine cake', sugar: 30),
      {HealthGoal.diabetes, HealthGoal.weightGain},
    );
    // diabetes conflicts (high sugar) even though weight-gain is happy → No.
    expect(v.answer, 'No');
  });

  test('serializes and restores goals through settings', () {
    const profile = HealthProfile(
      goals: {HealthGoal.diabetes, HealthGoal.pregnancy},
      conditionsNote: 'gluten intolerance',
    );
    final map = profile.toSettings();
    final back = HealthProfile.fromSettings((k) => map[k]);
    expect(back.goals, profile.goals);
    expect(back.conditionsNote, 'gluten intolerance');
  });
}
