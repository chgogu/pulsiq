import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/body_profile.dart';
import 'package:pulsiq/domain/daily_insights.dart';
import 'package:pulsiq/domain/daily_spark.dart';
import 'package:pulsiq/domain/nutrition.dart';

MacroTotals totals({
  int calories = 0,
  double protein = 0,
  double fiber = 0,
  double carbs = 0,
  double fat = 0,
}) =>
    MacroTotals(
      calories: calories,
      proteinG: protein,
      fiberG: fiber,
      carbsG: carbs,
      fatG: fat,
    );

DateTime at(int hour) => DateTime(2026, 7, 21, hour);

void main() {
  const targets = NutritionTargets(); // 2000 kcal, 100 g protein, 30 g fiber

  group('day pace', () {
    test('is zero before the eating window and one after', () {
      expect(dayFraction(at(5)), 0);
      expect(dayFraction(at(23)), 1);
    });

    test('is about half at midday', () {
      expect(dayFraction(at(14)), closeTo(0.5, 0.01));
    });
  });

  group('empty state', () {
    test('asks for a log rather than inventing a read', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(),
        targets: targets,
        now: at(12),
      ));
      expect(out, hasLength(1));
      expect(out.single.headline, contains('Nothing logged'));
      expect(out.single.icon, InsightIcon.plan);
    });
  });

  group('calorie pace', () {
    test('flags being well ahead of an even spread', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1800, protein: 90, fiber: 28),
        targets: targets,
        now: at(11), // ~29% through the day, 90% of budget spent
        mealsLogged: 2,
      ));
      expect(out.map((i) => i.headline), contains('Ahead of pace'));
    });

    test('flags running light late in the day', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 700, protein: 40, fiber: 12),
        targets: targets,
        now: at(20),
        mealsLogged: 2,
      ));
      expect(out.map((i) => i.headline), contains('Running light today'));
    });

    test('says nothing about pace when the day is on track', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1000, protein: 50, fiber: 15),
        targets: targets,
        now: at(14),
        mealsLogged: 2,
      ));
      final headlines = out.map((i) => i.headline);
      expect(headlines, isNot(contains('Ahead of pace')));
      expect(headlines, isNot(contains('Running light today')));
    });
  });

  group('protein', () {
    test('celebrates hitting the target', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1500, protein: 95, fiber: 20),
        targets: targets,
        now: at(18),
        mealsLogged: 3,
      ));
      final protein = out.firstWhere((i) => i.headline == 'Protein handled');
      expect(protein.tone, InsightTone.good);
    });

    test('flags protein lagging behind the day', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1400, protein: 15, fiber: 20),
        targets: targets,
        now: at(19),
        mealsLogged: 3,
      ));
      expect(out.map((i) => i.headline), contains('Protein is lagging'));
    });
  });

  group('balance and gaps', () {
    test('flags a fat-dense day by share of calories', () {
      // 1200 kcal with 70 g fat = 630 kcal from fat = 52%.
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1200, protein: 60, fiber: 25, fat: 70),
        targets: targets,
        now: at(15),
        mealsLogged: 2,
      ));
      expect(out.map((i) => i.headline), contains('Fat-dense day'));
    });

    test('does not compute a fat share on a nearly empty day', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 200, protein: 5, fat: 18),
        targets: targets,
        now: at(9),
        mealsLogged: 1,
      ));
      expect(out.map((i) => i.headline), isNot(contains('Fat-dense day')));
    });

    test('flags being behind on water', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1200, protein: 60, fiber: 20),
        targets: targets,
        now: at(19),
        hydrationMl: 200,
        hydrationTargetMl: 2500,
        mealsLogged: 3,
      ));
      expect(out.map((i) => i.headline), contains('Behind on water'));
    });

    test('credits logged movement', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1200, protein: 60, fiber: 20),
        targets: targets,
        now: at(15),
        exerciseMinutes: 45,
        mealsLogged: 2,
      ));
      expect(out.map((i) => i.headline), contains('45 min logged'));
    });
  });

  group('forward-looking plan', () {
    test('reports the remaining budget', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1200, protein: 60, fiber: 20),
        targets: targets,
        now: at(15),
        mealsLogged: 2,
      ));
      expect(out.last.headline, 'Room for 800 kcal');
      expect(out.last.icon, InsightIcon.plan);
    });

    test('handles an overspent budget without negative numbers', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 2600, protein: 120, fiber: 35),
        targets: targets,
        now: at(16),
        mealsLogged: 4,
      ));
      expect(out.last.headline, 'Budget is spent');
      expect(out.map((i) => i.headline).join(), isNot(contains('-')));
    });

    test('drops the plan once the day is effectively over', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1800, protein: 95, fiber: 28),
        targets: targets,
        now: at(23),
        mealsLogged: 4,
      ));
      expect(out.map((i) => i.icon), isNot(contains(InsightIcon.plan)));
    });
  });

  group('personalization', () {
    const body = BodyProfile(heightCm: 180, weightKg: 80, age: 30);

    test('reports protein per kg when a body profile exists', () {
      // 140 g over 80 kg = 1.75 g/kg, above the 1.6 threshold.
      final out = computeDailyInsights(
        InsightsInput(
          totals: totals(calories: 1800, protein: 140, fiber: 30),
          targets: targets,
          now: at(19),
          mealsLogged: 3,
          body: body,
        ),
        max: 8,
      );
      expect(out.map((i) => i.headline), contains('1.8 g protein per kg'));
    });

    test('says nothing about g/kg without a profile', () {
      final out = computeDailyInsights(
        InsightsInput(
          totals: totals(calories: 1800, protein: 140, fiber: 30),
          targets: targets,
          now: at(19),
          mealsLogged: 3,
        ),
        max: 8,
      );
      expect(out.map((i) => i.headline).join(), isNot(contains('per kg')));
    });
  });

  group('ranking and caps', () {
    test('never returns more than the cap', () {
      final out = computeDailyInsights(
        InsightsInput(
          totals: totals(calories: 2600, protein: 10, fiber: 2, fat: 130),
          targets: targets,
          now: at(20),
          hydrationMl: 100,
          hydrationTargetMl: 2500,
          exerciseMinutes: 60,
          mealsLogged: 4,
        ),
        max: 4,
      );
      expect(out.length, lessThanOrEqualTo(4));
    });

    test('puts things to act on before wins', () {
      final out = computeDailyInsights(InsightsInput(
        totals: totals(calories: 1400, protein: 10, fiber: 35),
        targets: targets,
        now: at(19),
        exerciseMinutes: 40,
        mealsLogged: 3,
      ));
      final firstGood = out.indexWhere((i) => i.tone == InsightTone.good);
      final firstWatch = out.indexWhere((i) => i.tone == InsightTone.watch);
      if (firstGood >= 0 && firstWatch >= 0) {
        expect(firstWatch, lessThan(firstGood));
      }
    });
  });

  group('daily spark', () {
    test('is stable across a calendar day', () {
      final morning = sparkFor(DateTime(2026, 7, 21, 6));
      final night = sparkFor(DateTime(2026, 7, 21, 23, 59));
      expect(morning.quote, night.quote);
      expect(morning.joke, night.joke);
    });

    test('changes from one day to the next', () {
      final a = sparkFor(DateTime(2026, 7, 21));
      final b = sparkFor(DateTime(2026, 7, 22));
      expect(a.quote, isNot(b.quote));
      expect(a.joke, isNot(b.joke));
    });

    test('never returns empty content, across a full year', () {
      var day = DateTime(2026, 1, 1);
      for (var i = 0; i < 365; i++) {
        final spark = sparkFor(day);
        expect(spark.quote.trim(), isNotEmpty);
        expect(spark.joke.trim(), isNotEmpty);
        day = day.add(const Duration(days: 1));
      }
    });

    test('handles dates before the epoch without throwing', () {
      final spark = sparkFor(DateTime(1999, 5, 4));
      expect(spark.quote.trim(), isNotEmpty);
      expect(spark.joke.trim(), isNotEmpty);
    });

    test('quote and joke lists cycle at different rates', () {
      final pairs = <String>{};
      var day = DateTime(2026, 1, 1);
      for (var i = 0; i < 60; i++) {
        final s = sparkFor(day);
        pairs.add('${s.quote}|${s.joke}');
        day = day.add(const Duration(days: 1));
      }
      expect(pairs, hasLength(60), reason: 'pairings should not repeat early');
    });
  });
}
