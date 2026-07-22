import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/food_db.dart';

void main() {
  late FoodDb db;

  setUpAll(() {
    // Load the real bundled asset from disk (no Flutter binding needed).
    final json = File('assets/nutrition/foods.json').readAsStringSync();
    db = FoodDb.parse(json);
  });

  FoodResolution resolve(String s) {
    final r = db.resolve(s);
    expect(r, isNotNull, reason: 'expected "$s" to resolve locally');
    return r!;
  }

  group('single foods + portions', () {
    test('a bare food is one serving', () {
      final r = resolve('banana');
      expect(r.caloriesKcal, closeTo(105, 3)); // 118 g × 0.89
      expect(r.itemCount, 1);
    });

    test('counts multiply the natural unit', () {
      // 2 eggs = 100 g at 143 kcal/100 g = 143.
      expect(resolve('2 eggs').caloriesKcal, closeTo(143, 3));
      // 3 eggs scales.
      expect(resolve('3 eggs').caloriesKcal, closeTo(215, 4));
    });

    test('cup unit uses the per-food gram weight', () {
      // 1 cup cooked white rice = 158 g at 130 kcal/100 g ≈ 205.
      expect(resolve('1 cup rice').caloriesKcal, closeTo(205, 5));
    });

    test('millilitres parse whether glued or spaced', () {
      final glued = resolve('200ml milk');
      final spaced = resolve('200 ml milk');
      expect(glued.caloriesKcal, spaced.caloriesKcal);
      expect(glued.caloriesKcal, closeTo(122, 3)); // 61 kcal/100 ml × 2
    });

    test('fractions work', () {
      // half avocado = 100 g at 160 kcal/100 g = 160.
      expect(resolve('half avocado').caloriesKcal, closeTo(160, 3));
    });
  });

  group("the user's real meals resolve locally (\$0)", () {
    test('quinoa, spinach, toor dal, 2 egg whites', () {
      final r = resolve('quinoa with cooked spinach toor dal with 2 egg whites');
      // 4 distinct items, including the space-separated "spinach toor dal".
      expect(r.itemCount, 4);
      // Sanity band, not a brittle exact number.
      expect(r.caloriesKcal, inInclusiveRange(350, 560));
      expect(r.proteinG, greaterThan(15));
    });

    test('sourdough, half avocado, hemp hearts, lime juice', () {
      final r = resolve(
          'sourdough bread with half avocado topped with hemp hearts and lime juice');
      expect(r.itemCount, 4);
      expect(r.caloriesKcal, inInclusiveRange(300, 460));
    });

    test('green tea resolves to ~0 calories', () {
      expect(resolve('green tea').caloriesKcal, lessThan(5));
    });
  });

  group('quality rollup', () {
    test('one dense item makes the plate dense', () {
      expect(resolve('chicken and fries').quality, 'dense');
    });

    test('all-clean stays clean', () {
      expect(resolve('chicken and broccoli').quality, 'clean');
    });
  });

  group('USDA breadth (foods beyond the curated set)', () {
    test('common USDA foods now resolve locally', () {
      for (final food in ['asparagus', 'edamame', 'cod', 'tilapia', 'okra']) {
        final r = db.resolve(food);
        expect(r, isNotNull, reason: '"$food" should resolve from USDA');
        expect(r!.caloriesKcal, greaterThan(0));
      }
    });

    test('portions still apply to USDA foods', () {
      final one = db.resolve('asparagus')!;
      final two = db.resolve('2 cups asparagus')!;
      expect(two.caloriesKcal, greaterThan(one.caloriesKcal));
    });

    test('curated foods still win over USDA on shared names', () {
      // "rice" must resolve to curated white rice (130 kcal/100g, 158 g cup),
      // not some bulk USDA rice variant.
      expect(db.resolve('1 cup rice')!.caloriesKcal, closeTo(205, 6));
    });
  });

  group('escalation', () {
    test('an unknown food returns null (caller escalates to the model)', () {
      expect(db.resolve('szechuan mapo tofu explosion'), isNull);
      expect(db.resolve('quinoa and unicorn stew'), isNull,
          reason: 'a partial match must not silently under-count');
    });

    test('empty input is null', () {
      expect(db.resolve('   '), isNull);
    });
  });
}
