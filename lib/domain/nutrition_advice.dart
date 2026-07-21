/// Daily "what to cut down" engine (NUTRITION_VISION_PROMPT §5). Pure and
/// unit-tested: from today's totals vs targets, produce 1–3 specific,
/// actionable suggestions, each pairing a cut with a concrete swap. Stays
/// wellness-framed — never diagnostic.
library;

import 'nutrition.dart';

class NutritionAdvice {
  const NutritionAdvice({required this.headline, required this.tips});

  final String headline;
  final List<String> tips;

  bool get isEmpty => tips.isEmpty;
}

/// [mealsLogged] gates the advice — one item isn't enough of a picture (§5).
NutritionAdvice computeNutritionAdvice({
  required MacroTotals totals,
  required NutritionTargets targets,
  required int mealsLogged,
  DateTime? now,
}) {
  if (mealsLogged < 2 || totals.isEmpty) {
    return const NutritionAdvice(headline: '', tips: []);
  }
  final hour = (now ?? DateTime.now()).hour;
  final tips = <({double severity, String text})>[];

  // Calories over target — the headline lever.
  final calOver = totals.calories - targets.calories;
  if (calOver > 150) {
    final swap = hour < 15
        ? 'swap the next snack for a handful of nuts or Greek yogurt instead of something sweet'
        : 'keep dinner protein-and-veg forward and skip the second helping';
    tips.add((
      severity: calOver / 100,
      text: "You're about $calOver kcal over today — $swap.",
    ));
  }

  // Fat-dense day (rough: >40% of a 2000-cal day from fat ≈ >89 g).
  final fatCalShare =
      totals.calories == 0 ? 0 : (totals.fatG * 9) / totals.calories;
  if (fatCalShare > 0.42 && totals.fatG > 70) {
    tips.add((
      severity: 1.5,
      text: 'A lot of today\'s energy is coming from fat — trade fried or '
          'creamy sides for grilled or steamed to steady things out.',
    ));
  }

  // Short on fiber — pair the cut with an add.
  final fiberShort = targets.fiberG - totals.fiberG;
  if (fiberShort > 10) {
    tips.add((
      severity: fiberShort / 15,
      text: 'Fiber is running low (${totals.fiberG.round()} of '
          '${targets.fiberG.round()} g) — add a piece of fruit, beans, or '
          'a side of veg to your next meal for longer-lasting energy.',
    ));
  }

  // Short on protein late in the day.
  final proteinShort = targets.proteinG - totals.proteinG;
  if (proteinShort > 30 && hour >= 15) {
    tips.add((
      severity: proteinShort / 40,
      text: 'You\'re light on protein (${totals.proteinG.round()} of '
          '${targets.proteinG.round()} g) — anchor dinner around eggs, '
          'chicken, fish, or tofu to close the gap.',
    ));
  }

  if (tips.isEmpty) {
    return const NutritionAdvice(
      headline: 'Nicely balanced today',
      tips: ["You're tracking close to your targets — keep it rolling."],
    );
  }

  tips.sort((a, b) => b.severity.compareTo(a.severity));
  return NutritionAdvice(
    headline: 'Small tweaks for steadier energy',
    tips: [for (final t in tips.take(3)) t.text],
  );
}
