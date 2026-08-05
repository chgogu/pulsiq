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
  test('no goals set → no opinion', () {
    final v = assessFood(food(sugar: 40), {});
    expect(v.hasOpinion, isFalse);
    expect(v.level, SafetyLevel.good);
  });

  group('diabetes', () {
    test('high sugar is flagged avoid', () {
      final v = assessFood(food(sugar: 30), {HealthGoal.diabetes});
      expect(v.level, SafetyLevel.avoid);
      expect(v.reasons.single.goal, HealthGoal.diabetes);
    });
    test('moderate sugar is a caution', () {
      final v = assessFood(food(sugar: 15), {HealthGoal.diabetes});
      expect(v.level, SafetyLevel.caution);
    });
    test('low sugar passes', () {
      final v = assessFood(food(sugar: 4), {HealthGoal.diabetes});
      expect(v.hasOpinion, isFalse);
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
    test('coffee is a caution, not a block', () {
      final v = assessFood(food(name: 'Iced coffee'), {HealthGoal.pregnancy});
      expect(v.level, SafetyLevel.caution);
    });
  });

  group('heart health', () {
    test('high saturated fat is avoid', () {
      final v = assessFood(food(satFat: 12), {HealthGoal.heartHealth});
      expect(v.level, SafetyLevel.avoid);
    });
    test('high sodium is flagged', () {
      final v = assessFood(food(sodium: 1300), {HealthGoal.heartHealth});
      expect(v.level, SafetyLevel.avoid);
    });
  });

  test('weight gain frames a dense food positively', () {
    final v = assessFood(food(kcal: 600), {HealthGoal.weightGain});
    expect(v.level, SafetyLevel.good);
    expect(v.reasons, isNotEmpty);
  });

  test('the worst goal sets the overall level', () {
    final v = assessFood(
      food(name: 'wine cake', sugar: 30),
      {HealthGoal.diabetes, HealthGoal.weightGain},
    );
    // diabetes says avoid, weight-gain says good → avoid wins.
    expect(v.level, SafetyLevel.avoid);
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
