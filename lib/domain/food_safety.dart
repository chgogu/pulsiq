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
  const SafetyVerdict(this.level, this.reasons, {this.hasGoals = false});

  /// The worst level across all goals — one "avoid" makes the whole verdict
  /// "avoid".
  final SafetyLevel level;
  final List<SafetyReason> reasons;

  /// Whether the user has any goals set. Without them there's no basis for an
  /// answer, so the banner stays hidden.
  final bool hasGoals;

  /// A straight Yes/No, so the user doesn't have to interpret a scale. Only a
  /// clear conflict (level "avoid") is a No; a mild caution is still Yes.
  bool get canEat => level != SafetyLevel.avoid;

  bool get hasAnswer => hasGoals;

  String get answer => canEat ? 'Yes' : 'No';

  /// One neutral line — the single most relevant fact, never a lecture.
  String get oneLiner {
    // Surface the most severe reason; ties keep declaration order.
    SafetyReason? top;
    for (final r in reasons) {
      if (top == null || r.level.index > top.level.index) top = r;
    }
    if (top != null) return top.text;
    return 'No conflicts with your goals.';
  }
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

  // One neutral fact per rule — the reason, no judgement.
  for (final goal in goals) {
    switch (goal) {
      case HealthGoal.diabetes:
        if (food.sugarG >= 25) {
          add(goal, SafetyLevel.avoid,
              '${food.sugarG.round()} g sugar — high for blood sugar.');
        } else if (food.sugarG >= 12) {
          add(goal, SafetyLevel.caution,
              '${food.sugarG.round()} g sugar — moderate; pair with protein.');
        }

      case HealthGoal.weightLoss:
        if (food.caloriesKcal >= 600) {
          add(goal, SafetyLevel.caution,
              '${food.caloriesKcal} kcal — high for a calorie deficit.');
        } else if (food.sugarG >= 20) {
          add(goal, SafetyLevel.caution,
              '${food.sugarG.round()} g sugar — calorie-dense.');
        }

      case HealthGoal.weightGain:
        if (food.caloriesKcal >= 400) {
          add(goal, SafetyLevel.good,
              '${food.caloriesKcal} kcal — supports a surplus.');
        }

      case HealthGoal.pregnancy:
        if (food._mentions(_alcohol)) {
          add(goal, SafetyLevel.avoid, 'Contains alcohol.');
        } else if (food._mentions(_rawUnsafe)) {
          add(goal, SafetyLevel.avoid, 'Raw or unpasteurized.');
        } else if (food._mentions(_highMercuryFish)) {
          add(goal, SafetyLevel.avoid, 'High-mercury fish.');
        } else if (food._mentions(_caffeine)) {
          add(goal, SafetyLevel.caution, 'Contains caffeine — limit to 200 mg/day.');
        }

      case HealthGoal.heartHealth:
        final sat = food.saturatedFatG;
        if (sat != null && sat >= 10) {
          add(goal, SafetyLevel.avoid,
              '${sat.round()} g saturated fat — high.');
        } else if (sat != null && sat >= 5) {
          add(goal, SafetyLevel.caution,
              '${sat.round()} g saturated fat — moderate.');
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
  return SafetyVerdict(
    reasons.isEmpty ? SafetyLevel.good : level,
    reasons,
    hasGoals: goals.isNotEmpty,
  );
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
    add(goal, SafetyLevel.avoid, '${s.round()} mg sodium — high.');
  } else if (s >= cautionMg) {
    add(goal, SafetyLevel.caution, '${s.round()} mg sodium — moderate.');
  }
}
