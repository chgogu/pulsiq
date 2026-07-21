/// Body profile → personalized fuel targets.
///
/// Pure and unit-tested. Given height, weight, age, sex, activity and goal,
/// derives resting burn (Mifflin–St Jeor), daily burn, and macro targets.
///
/// These are population estimates, not prescriptions — the UI says so, and
/// every derived number stays overridable by hand.
library;

import 'dart:math' as math;

import 'nutrition.dart';

const kgPerLb = 0.45359237;
const cmPerInch = 2.54;

double lbToKg(double lb) => lb * kgPerLb;
double kgToLb(double kg) => kg / kgPerLb;
double inchesToCm(double inches) => inches * cmPerInch;
double cmToInches(double cm) => cm / cmPerInch;

enum BodySex {
  female,
  male,

  /// Averages the two Mifflin–St Jeor constants. Offered so the app never
  /// forces a disclosure it doesn't strictly need.
  unspecified;

  String get label => switch (this) {
        BodySex.female => 'Female',
        BodySex.male => 'Male',
        BodySex.unspecified => 'Prefer not to say',
      };

  /// The `s` term in Mifflin–St Jeor.
  double get bmrConstant => switch (this) {
        BodySex.male => 5,
        BodySex.female => -161,
        BodySex.unspecified => -78, // midpoint
      };
}

enum ActivityLevel {
  sedentary(1.2, 'Sedentary', 'Desk job, little deliberate exercise'),
  light(1.375, 'Lightly active', 'Light exercise 1–3 days a week'),
  moderate(1.55, 'Moderately active', 'Moderate exercise 3–5 days a week'),
  high(1.725, 'Very active', 'Hard exercise 6–7 days a week'),
  athlete(1.9, 'Athlete', 'Physical job or two-a-day training');

  const ActivityLevel(this.factor, this.label, this.blurb);

  final double factor;
  final String label;
  final String blurb;
}

enum FuelGoal {
  lose('Lose weight', 'Steady deficit'),
  maintain('Maintain', 'Match your burn'),
  gain('Build', 'Slight surplus');

  const FuelGoal(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// Lowest calorie targets PulsIQ will suggest without supervision. A deficit
/// is also capped at 20% of daily burn, so aggressive goals can't compound
/// into an unsafe number.
const _floorKcalFemale = 1200;
const _floorKcalMale = 1500;
const _maxDeficitFraction = 0.20;
const _surplusFraction = 0.10;

class BodyProfile {
  const BodyProfile({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    this.sex = BodySex.unspecified,
    this.activity = ActivityLevel.light,
    this.goal = FuelGoal.maintain,
    this.metric = false,
  });

  final double heightCm;
  final double weightKg;
  final int age;
  final BodySex sex;
  final ActivityLevel activity;
  final FuelGoal goal;

  /// Display preference only — storage is always metric.
  final bool metric;

  /// Whether the numbers are physically plausible enough to derive from.
  bool get isUsable =>
      heightCm >= 90 &&
      heightCm <= 250 &&
      weightKg >= 25 &&
      weightKg <= 350 &&
      age >= 13 &&
      age <= 100;

  /// Resting energy expenditure, kcal/day (Mifflin–St Jeor).
  double get bmr =>
      10 * weightKg + 6.25 * heightCm - 5 * age + sex.bmrConstant;

  /// Total daily energy expenditure, kcal/day.
  double get tdee => bmr * activity.factor;

  double get bmi => weightKg / math.pow(heightCm / 100, 2);

  /// Weight span for a BMI of 18.5–24.9, in kg.
  (double, double) get healthyWeightRangeKg {
    final m2 = math.pow(heightCm / 100, 2).toDouble();
    return (18.5 * m2, 24.9 * m2);
  }

  /// Baseline hydration from body mass (~35 ml/kg), before weather and
  /// exercise adjustments. Clamped to the same sane band as the base target.
  int get baseHydrationMl => (weightKg * 35).round().clamp(1500, 4000);

  int get targetCalories {
    final burn = tdee;
    final adjusted = switch (goal) {
      FuelGoal.maintain => burn,
      FuelGoal.gain => burn * (1 + _surplusFraction),
      FuelGoal.lose => burn * (1 - _maxDeficitFraction),
    };
    final floor = switch (sex) {
      BodySex.male => _floorKcalMale,
      BodySex.female => _floorKcalFemale,
      // Without a stated sex, use the more protective floor.
      BodySex.unspecified => _floorKcalMale,
    };
    return (adjusted.round().clamp(floor, 6000) / 10).round() * 10;
  }

  /// Protein scales with body mass. Slightly higher in a deficit or a build,
  /// where preserving or adding lean mass is the point. Capped at 2.2 g/kg,
  /// the top of the range with evidence behind it.
  double get targetProteinG {
    final perKg = switch (goal) {
      FuelGoal.maintain => 1.6,
      FuelGoal.lose => 1.8,
      FuelGoal.gain => 1.8,
    };
    return (weightKg * perKg).clamp(40.0, weightKg * 2.2).roundToDouble();
  }

  /// 14 g per 1,000 kcal — the Dietary Guidelines figure, so fiber tracks
  /// how much you actually eat rather than sitting at a flat 30 g.
  double get targetFiberG =>
      (targetCalories / 1000 * 14).clamp(20.0, 45.0).roundToDouble();

  /// 30% of calories from fat — mid-range of the 20–35% AMDR.
  double get targetFatG => (targetCalories * 0.30 / 9).roundToDouble();

  /// Whatever energy is left after protein and fat are covered.
  double get targetCarbsG {
    final remaining = targetCalories - targetProteinG * 4 - targetFatG * 9;
    return math.max(0, remaining / 4).roundToDouble();
  }

  NutritionTargets get derivedTargets => NutritionTargets(
        calories: targetCalories,
        proteinG: targetProteinG,
        fiberG: targetFiberG,
        carbsG: targetCarbsG,
        fatG: targetFatG,
        source: TargetSource.derived,
      );

  BodyProfile copyWith({
    double? heightCm,
    double? weightKg,
    int? age,
    BodySex? sex,
    ActivityLevel? activity,
    FuelGoal? goal,
    bool? metric,
  }) =>
      BodyProfile(
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        age: age ?? this.age,
        sex: sex ?? this.sex,
        activity: activity ?? this.activity,
        goal: goal ?? this.goal,
        metric: metric ?? this.metric,
      );

  static const settingsKeys = [
    'body_height_cm',
    'body_weight_kg',
    'body_age',
    'body_sex',
    'body_activity',
    'body_goal',
    'body_metric',
  ];

  Map<String, String> toSettings() => {
        'body_height_cm': '$heightCm',
        'body_weight_kg': '$weightKg',
        'body_age': '$age',
        'body_sex': sex.name,
        'body_activity': activity.name,
        'body_goal': goal.name,
        'body_metric': '$metric',
      };

  /// Returns null when the profile has never been filled in — the caller
  /// then falls back to flat defaults rather than inventing a body.
  static BodyProfile? fromSettings(String? Function(String) get) {
    final h = double.tryParse(get('body_height_cm') ?? '');
    final w = double.tryParse(get('body_weight_kg') ?? '');
    final a = int.tryParse(get('body_age') ?? '');
    if (h == null || w == null || a == null) return null;
    return BodyProfile(
      heightCm: h,
      weightKg: w,
      age: a,
      sex: BodySex.values.firstWhere(
        (s) => s.name == get('body_sex'),
        orElse: () => BodySex.unspecified,
      ),
      activity: ActivityLevel.values.firstWhere(
        (s) => s.name == get('body_activity'),
        orElse: () => ActivityLevel.light,
      ),
      goal: FuelGoal.values.firstWhere(
        (s) => s.name == get('body_goal'),
        orElse: () => FuelGoal.maintain,
      ),
      metric: get('body_metric') == 'true',
    );
  }
}
