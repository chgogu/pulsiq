/// Today's log, read back as observations and forward-looking suggestions.
///
/// Pure and unit-tested. Distinct from [computeNutritionAdvice], which looks
/// backward at what to cut; this looks at where the day *is* — pace, gaps,
/// balance — and what the remaining meals have room for.
///
/// Tone rule: these describe food and timing, never the person. Nothing here
/// grades a body or moralizes about a meal.
library;

import 'body_profile.dart';
import 'nutrition.dart';

enum InsightTone { good, watch, info }

/// Icon is a stable key the UI maps to a Material icon, so this stays a
/// pure Dart library with no Flutter import.
enum InsightIcon { pace, protein, fiber, water, balance, move, quality, plan }

class DailyInsight {
  const DailyInsight({
    required this.headline,
    required this.detail,
    required this.tone,
    required this.icon,
  });

  final String headline;
  final String detail;
  final InsightTone tone;
  final InsightIcon icon;
}

class InsightsInput {
  const InsightsInput({
    required this.totals,
    required this.targets,
    required this.now,
    this.hydrationMl = 0,
    this.hydrationTargetMl = 2000,
    this.mealsLogged = 0,
    this.exerciseMinutes = 0,
    this.body,
  });

  final MacroTotals totals;
  final NutritionTargets targets;
  final DateTime now;
  final int hydrationMl;
  final int hydrationTargetMl;
  final int mealsLogged;
  final int exerciseMinutes;
  final BodyProfile? body;
}

/// Waking window used for pace. Eating is assumed to spread over roughly
/// 7am–9pm; outside it the pace check is meaningless and gets skipped.
const _dayStartHour = 7;
const _dayEndHour = 21;

/// How far through the eating day we are, 0..1.
double dayFraction(DateTime now) {
  final minutes = now.hour * 60 + now.minute;
  const start = _dayStartHour * 60;
  const end = _dayEndHour * 60;
  return ((minutes - start) / (end - start)).clamp(0.0, 1.0);
}

/// Up to [max] insights, most useful first.
List<DailyInsight> computeDailyInsights(InsightsInput input, {int max = 4}) {
  final t = input.totals;
  final target = input.targets;
  final out = <DailyInsight>[];

  if (input.mealsLogged == 0 && t.isEmpty) {
    return const [
      DailyInsight(
        headline: 'Nothing logged yet today',
        detail: 'Snap a meal or hold the button and say what you ate — '
            'insights appear as soon as there is something to read.',
        tone: InsightTone.info,
        icon: InsightIcon.plan,
      ),
    ];
  }

  final pace = dayFraction(input.now);
  final calFraction = target.calories == 0 ? 0.0 : t.calories / target.calories;
  final remaining = target.calories - t.calories;

  // 1. Calorie pace — the headline read on the day.
  if (calFraction > pace + 0.2 && pace < 0.9) {
    out.add(DailyInsight(
      headline: 'Ahead of pace',
      detail: '${t.calories} kcal by now is about '
          '${((calFraction - pace) * 100).round()}% ahead of an even spread. '
          'Lighter choices later keep the day balanced.',
      tone: InsightTone.watch,
      icon: InsightIcon.pace,
    ));
  } else if (pace > 0.75 && calFraction < 0.6 && t.calories > 0) {
    out.add(DailyInsight(
      headline: 'Running light today',
      detail: 'Only ${t.calories} of ${target.calories} kcal logged this late. '
          'Under-fuelling tends to show up as an evening energy dip.',
      tone: InsightTone.watch,
      icon: InsightIcon.pace,
    ));
  }

  // 2. Protein — the macro most worth defending, especially in a deficit.
  final proteinGap = target.proteinG - t.proteinG;
  final proteinFraction =
      target.proteinG == 0 ? 1.0 : t.proteinG / target.proteinG;
  if (proteinFraction >= 0.9) {
    out.add(DailyInsight(
      headline: 'Protein handled',
      detail: '${t.proteinG.round()} g of ${target.proteinG.round()} g — '
          'that is the one that protects muscle while you train and sleep.',
      tone: InsightTone.good,
      icon: InsightIcon.protein,
    ));
  } else if (proteinGap > 0 && proteinFraction < pace - 0.15) {
    out.add(DailyInsight(
      headline: 'Protein is lagging',
      detail: '${proteinGap.round()} g still to go. Eggs, yogurt, fish, '
          'tofu, or beans close that gap fastest.',
      tone: InsightTone.watch,
      icon: InsightIcon.protein,
    ));
  }

  // 3. Fat share of the day, which drives how calorie-dense the food is.
  if (t.calories > 400) {
    final fatShare = t.fatG * 9 / t.calories;
    if (fatShare > 0.42) {
      out.add(DailyInsight(
        headline: 'Fat-dense day',
        detail: '${(fatShare * 100).round()}% of today\'s calories came from '
            'fat. Grilled instead of fried, and dressing on the side, pulls '
            'that back without shrinking the plate.',
        tone: InsightTone.watch,
        icon: InsightIcon.balance,
      ));
    }
  }

  // 4. Fiber — the strongest single predictor of steady energy here.
  final fiberGap = target.fiberG - t.fiberG;
  if (fiberGap > 8 && pace > 0.4) {
    out.add(DailyInsight(
      headline: 'Fiber is short',
      detail: '${t.fiberG.round()} g of ${target.fiberG.round()} g. Beans, '
          'berries, or leaving the skin on flattens the energy curve.',
      tone: InsightTone.watch,
      icon: InsightIcon.fiber,
    ));
  } else if (t.fiberG >= target.fiberG) {
    out.add(DailyInsight(
      headline: 'Fiber target met',
      detail: '${t.fiberG.round()} g — that is the steady-energy macro doing '
          'its job.',
      tone: InsightTone.good,
      icon: InsightIcon.fiber,
    ));
  }

  // 5. Hydration.
  final waterFraction = input.hydrationTargetMl == 0
      ? 1.0
      : input.hydrationMl / input.hydrationTargetMl;
  if (waterFraction < pace - 0.2) {
    out.add(DailyInsight(
      headline: 'Behind on water',
      detail: '${input.hydrationMl} of ${input.hydrationTargetMl} ml. Mild '
          'dehydration reads as tiredness long before it reads as thirst.',
      tone: InsightTone.watch,
      icon: InsightIcon.water,
    ));
  }

  // 6. Movement earns a mention — it is the one input that widens the budget.
  if (input.exerciseMinutes >= 20) {
    out.add(DailyInsight(
      headline: '${input.exerciseMinutes} min logged',
      detail: 'Movement is banked. It steadies glucose response for hours '
          'afterward, not just during.',
      tone: InsightTone.good,
      icon: InsightIcon.move,
    ));
  }

  // 7. Protein relative to body mass — only meaningful with a profile.
  final body = input.body;
  if (body != null && t.proteinG > 0) {
    final perKg = t.proteinG / body.weightKg;
    if (perKg >= 1.6) {
      out.add(DailyInsight(
        headline: '${perKg.toStringAsFixed(1)} g protein per kg',
        detail: 'Comfortably in the range that supports training and '
            'recovery for your body.',
        tone: InsightTone.good,
        icon: InsightIcon.protein,
      ));
    }
  }

  // Rank: things to act on first, then wins, then context.
  int rank(DailyInsight i) => switch (i.tone) {
        InsightTone.watch => 0,
        InsightTone.good => 1,
        InsightTone.info => 2,
      };
  out.sort((a, b) => rank(a).compareTo(rank(b)));

  // Always close with something forward-looking when the day isn't over.
  final plan = _nextMealPlan(remaining, proteinGap, pace);
  final trimmed = out.take(plan == null ? max : max - 1).toList();
  if (plan != null) trimmed.add(plan);
  return trimmed;
}

/// What the rest of the day has room for — the recommendation half.
DailyInsight? _nextMealPlan(int remainingKcal, double proteinGap, double pace) {
  if (pace >= 0.95) return null;
  if (remainingKcal <= 0) {
    return const DailyInsight(
      headline: 'Budget is spent',
      detail: 'Anything else today is best kept to protein and vegetables — '
          'they cost the least against the target and satisfy the most.',
      tone: InsightTone.info,
      icon: InsightIcon.plan,
    );
  }
  final proteinBit =
      proteinGap > 5 ? ' with about ${proteinGap.round()} g protein' : '';
  return DailyInsight(
    headline: 'Room for $remainingKcal kcal',
    detail: 'That is what is left in today\'s budget$proteinBit. '
        'Build the next plate around that and the day lands on target.',
    tone: InsightTone.info,
    icon: InsightIcon.plan,
  );
}
