import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/body_profile.dart';
import 'package:pulsiq/domain/nutrition.dart';

void main() {
  // 80 kg, 180 cm, 30 y male:
  //   BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
  const male = BodyProfile(
    heightCm: 180,
    weightKg: 80,
    age: 30,
    sex: BodySex.male,
    activity: ActivityLevel.moderate,
  );

  group('Mifflin–St Jeor', () {
    test('computes resting burn for male', () {
      expect(male.bmr, closeTo(1780, 0.001));
    });

    test('computes resting burn for female (constant differs by 166)', () {
      const female = BodyProfile(
        heightCm: 180,
        weightKg: 80,
        age: 30,
        sex: BodySex.female,
      );
      expect(female.bmr, closeTo(1780 - 166, 0.001));
    });

    test('unspecified sex lands between male and female', () {
      const unspec = BodyProfile(heightCm: 180, weightKg: 80, age: 30);
      const female = BodyProfile(
          heightCm: 180, weightKg: 80, age: 30, sex: BodySex.female);
      expect(unspec.bmr, lessThan(male.bmr));
      expect(unspec.bmr, greaterThan(female.bmr));
    });

    test('daily burn applies the activity factor', () {
      expect(male.tdee, closeTo(1780 * 1.55, 0.001));
    });
  });

  group('calorie target', () {
    test('maintain matches daily burn (rounded to 10)', () {
      expect(male.targetCalories, 2760); // 2759 -> 2760
    });

    test('lose applies a 20% deficit', () {
      final lose = male.copyWith(goal: FuelGoal.lose);
      expect(lose.targetCalories, closeTo(male.tdee * 0.8, 10));
    });

    test('gain applies a 10% surplus', () {
      final gain = male.copyWith(goal: FuelGoal.gain);
      expect(gain.targetCalories, greaterThan(male.targetCalories));
    });

    test('never drops below the safety floor, even for a small sedentary '
        'body in a deficit', () {
      const small = BodyProfile(
        heightCm: 150,
        weightKg: 42,
        age: 65,
        sex: BodySex.female,
        activity: ActivityLevel.sedentary,
        goal: FuelGoal.lose,
      );
      // Raw math would land near 1080 kcal; the floor must catch it.
      expect(small.tdee * 0.8, lessThan(1200));
      expect(small.targetCalories, greaterThanOrEqualTo(1200));
    });
  });

  group('macro targets', () {
    test('protein scales with body weight', () {
      expect(male.targetProteinG, 80 * 1.6);
      final heavier = male.copyWith(weightKg: 100);
      expect(heavier.targetProteinG, greaterThan(male.targetProteinG));
    });

    test('protein rises in a deficit to protect lean mass', () {
      expect(male.copyWith(goal: FuelGoal.lose).targetProteinG,
          greaterThan(male.targetProteinG));
    });

    test('fiber follows calories at 14 g per 1000 kcal', () {
      expect(male.targetFiberG, (2760 / 1000 * 14).clamp(20, 45).round());
    });

    test('macros roughly reconstruct the calorie target', () {
      final kcal = male.targetProteinG * 4 +
          male.targetCarbsG * 4 +
          male.targetFatG * 9;
      expect(kcal, closeTo(male.targetCalories, 12));
    });

    test('carbs never go negative for a high-protein small body', () {
      const tiny = BodyProfile(
        heightCm: 150,
        weightKg: 45,
        age: 25,
        goal: FuelGoal.lose,
        activity: ActivityLevel.sedentary,
      );
      expect(tiny.targetCarbsG, greaterThanOrEqualTo(0));
    });

    test('derived targets are tagged as derived', () {
      expect(male.derivedTargets.source, TargetSource.derived);
    });
  });

  group('hydration and BMI', () {
    test('water baseline scales at ~35 ml/kg', () {
      expect(male.baseHydrationMl, 2800);
      expect(male.copyWith(weightKg: 55).baseHydrationMl, 1925);
    });

    test('BMI is kg over metres squared', () {
      expect(male.bmi, closeTo(80 / (1.8 * 1.8), 0.001));
    });

    test('healthy weight range brackets a BMI of 18.5 to 24.9', () {
      final (low, high) = male.healthyWeightRangeKg;
      expect(low, closeTo(18.5 * 1.8 * 1.8, 0.001));
      expect(high, closeTo(24.9 * 1.8 * 1.8, 0.001));
    });
  });

  group('validation and persistence', () {
    test('rejects implausible bodies', () {
      expect(male.isUsable, isTrue);
      expect(male.copyWith(weightKg: 5).isUsable, isFalse);
      expect(male.copyWith(heightCm: 40).isUsable, isFalse);
      expect(male.copyWith(age: 4).isUsable, isFalse);
    });

    test('round-trips through settings', () {
      final map = male.toSettings();
      final back = BodyProfile.fromSettings((k) => map[k]);
      expect(back, isNotNull);
      expect(back!.heightCm, male.heightCm);
      expect(back.weightKg, male.weightKg);
      expect(back.age, male.age);
      expect(back.sex, male.sex);
      expect(back.activity, male.activity);
      expect(back.goal, male.goal);
    });

    test('returns null when nothing has been saved', () {
      expect(BodyProfile.fromSettings((_) => null), isNull);
    });

    test('falls back to safe enums on corrupt values', () {
      final back = BodyProfile.fromSettings((k) => switch (k) {
            'body_height_cm' => '180',
            'body_weight_kg' => '80',
            'body_age' => '30',
            'body_sex' => 'nonsense',
            'body_activity' => 'nonsense',
            _ => null,
          });
      expect(back!.sex, BodySex.unspecified);
      expect(back.activity, ActivityLevel.light);
    });
  });

  group('unit conversion', () {
    test('pounds and kilograms round-trip', () {
      expect(kgToLb(lbToKg(180)), closeTo(180, 0.0001));
    });

    test('a known conversion is right', () {
      expect(lbToKg(220.462), closeTo(100, 0.001));
      expect(inchesToCm(70), closeTo(177.8, 0.001));
    });
  });
}
