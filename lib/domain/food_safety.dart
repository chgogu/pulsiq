/// "Can I eat this?" — a per-goal verdict on a food, from its nutrition and
/// name. Pure and unit-tested. Deliberately conservative and framed as general
/// guidance, never medical advice (the UI carries that disclaimer).
library;

import 'health_goal.dart';

enum SafetyLevel {
  /// Fits the user's goals.
  good,

  /// Fine in moderation, or one thing to watch.
  caution,

  /// Works against a goal strongly enough to flag.
  avoid,
}

/// A single reason behind a verdict, tied to the goal that raised it.
class SafetyReason {
  const SafetyReason(this.goal, this.level, this.text);
  final HealthGoal goal;
  final SafetyLevel level;
  final String text;
}

class SafetyVerdict {
  const SafetyVerdict(this.level, this.reasons);

  /// The worst level across all goals — one "avoid" makes the whole verdict
  /// "avoid".
  final SafetyLevel level;
  final List<SafetyReason> reasons;

  bool get hasOpinion => reasons.isNotEmpty;

  String get headline => switch (level) {
        SafetyLevel.good => 'Good for your goals',
        SafetyLevel.caution => 'Okay — one thing to watch',
        SafetyLevel.avoid => 'Better to skip this one',
      };
}

/// What the engine needs to judge a food. Everything past the first three is
/// optional — a snapped meal has calories and sugar; a scanned product adds
/// sodium, saturated fat, and an ingredients string.
class FoodSafetyInput {
  const FoodSafetyInput({
    required this.name,
    required this.caloriesKcal,
    required this.sugarG,
    this.saturatedFatG,
    this.sodiumMg,
    this.ingredients,
  });

  final String name;
  final int caloriesKcal;
  final double sugarG;
  final double? saturatedFatG;
  final double? sodiumMg;
  final String? ingredients;

  /// name + ingredients, lowercased, for keyword checks.
  String get _haystack => '$name ${ingredients ?? ''}'.toLowerCase();
  bool _mentions(RegExp re) => re.hasMatch(_haystack);
}

final _alcohol = RegExp(
    r'\b(wine|beer|whiskey|vodka|rum|liquor|cocktail|brandy|tequila|'
    r'champagne|alcohol|liqueur)\b');
final _rawUnsafe = RegExp(
    r'\b(raw|unpasteuri[sz]ed|undercooked|deli meat|cold cut|pat[eé]|'
    r'runny egg|sushi|sashimi|raw fish)\b');
final _highMercuryFish = RegExp(r'\b(shark|swordfish|king mackerel|marlin)\b');
final _caffeine = RegExp(r'\b(coffee|espresso|energy drink|cola)\b');

/// Assess a food against the user's goals. Empty verdict (no reasons) when no
/// goal is set or nothing is worth flagging.
SafetyVerdict assessFood(FoodSafetyInput food, Set<HealthGoal> goals) {
  final reasons = <SafetyReason>[];

  void add(HealthGoal g, SafetyLevel l, String t) =>
      reasons.add(SafetyReason(g, l, t));

  for (final goal in goals) {
    switch (goal) {
      case HealthGoal.diabetes:
        if (food.sugarG >= 25) {
          add(goal, SafetyLevel.avoid,
              '${food.sugarG.round()} g sugar — a big spike for blood glucose.');
        } else if (food.sugarG >= 12) {
          add(goal, SafetyLevel.caution,
              '${food.sugarG.round()} g sugar — pair it with protein or fiber '
              'to soften the spike.');
        }

      case HealthGoal.weightLoss:
        if (food.caloriesKcal >= 600) {
          add(goal, SafetyLevel.caution,
              '${food.caloriesKcal} kcal in one item — heavy for a cut. A '
              'smaller portion keeps you on budget.');
        }
        if (food.sugarG >= 20) {
          add(goal, SafetyLevel.caution,
              'High in sugar, which is easy to over-eat.');
        }

      case HealthGoal.weightGain:
        if (food.caloriesKcal >= 400) {
          add(goal, SafetyLevel.good,
              'Calorie-dense — helps you hit a surplus.');
        }

      case HealthGoal.pregnancy:
        if (food._mentions(_alcohol)) {
          add(goal, SafetyLevel.avoid,
              'Contains alcohol — best avoided entirely in pregnancy.');
        }
        if (food._mentions(_rawUnsafe)) {
          add(goal, SafetyLevel.avoid,
              'Looks raw or unpasteurized — a listeria risk in pregnancy.');
        }
        if (food._mentions(_highMercuryFish)) {
          add(goal, SafetyLevel.avoid,
              'High-mercury fish — one to skip while pregnant.');
        }
        if (food._mentions(_caffeine)) {
          add(goal, SafetyLevel.caution,
              'Caffeine — keep under about 200 mg/day in pregnancy.');
        }

      case HealthGoal.heartHealth:
        final sat = food.saturatedFatG;
        if (sat != null && sat >= 10) {
          add(goal, SafetyLevel.avoid,
              '${sat.round()} g saturated fat — hard on cholesterol.');
        } else if (sat != null && sat >= 5) {
          add(goal, SafetyLevel.caution,
              '${sat.round()} g saturated fat — enjoy in moderation.');
        }
        _sodium(food, goal, add, cautionMg: 600, avoidMg: 1200);

      case HealthGoal.lowSodium:
        _sodium(food, goal, add, cautionMg: 400, avoidMg: 800);
    }
  }

  final level = reasons.fold(SafetyLevel.good, (worst, r) {
    // good < caution < avoid
    return r.level.index > worst.index ? r.level : worst;
  });
  return SafetyVerdict(reasons.isEmpty ? SafetyLevel.good : level, reasons);
}

void _sodium(
  FoodSafetyInput food,
  HealthGoal goal,
  void Function(HealthGoal, SafetyLevel, String) add, {
  required double cautionMg,
  required double avoidMg,
}) {
  final s = food.sodiumMg;
  if (s == null) return;
  if (s >= avoidMg) {
    add(goal, SafetyLevel.avoid, '${s.round()} mg sodium — very salty.');
  } else if (s >= cautionMg) {
    add(goal, SafetyLevel.caution, '${s.round()} mg sodium — on the salty side.');
  }
}
