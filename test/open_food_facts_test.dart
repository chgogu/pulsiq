import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/open_food_facts.dart';

Map<String, dynamic> product(Map<String, dynamic> nutriments,
        {String name = 'Test bar', String? brands, num? servingQ}) =>
    {
      'status': 1,
      'product': {
        'product_name': name,
        if (brands != null) 'brands': brands,
        if (servingQ != null) 'serving_quantity': servingQ,
        'nutriments': nutriments,
      },
    };

void main() {
  group('Open Food Facts parsing', () {
    test('prefers per-serving nutriments when present', () {
      final r = parseOffProduct(product({
        'energy-kcal_serving': 190,
        'proteins_serving': 10,
        'carbohydrates_serving': 22,
        'fat_serving': 7,
        'fiber_serving': 3,
        'energy-kcal_100g': 475, // should be ignored
      }, name: 'Protein bar', brands: 'Acme, Other'));
      expect(r, isNotNull);
      expect(r!.macros.caloriesKcal, 190);
      expect(r.macros.proteinG, 10);
      expect(r.label, 'Acme Protein bar'); // first brand only
    });

    test('scales per-100g by the serving size when there is no per-serving', () {
      final r = parseOffProduct(product({
        'energy-kcal_100g': 400,
        'proteins_100g': 8,
        'carbohydrates_100g': 60,
        'fat_100g': 14,
        'fiber_100g': 5,
      }, servingQ: 40));
      // 40 g serving → 40% of the per-100g values.
      expect(r!.macros.caloriesKcal, 160);
      expect(r.macros.proteinG, closeTo(3.2, 0.05));
    });

    test('falls back to a 100 g portion when no serving size is given', () {
      final r = parseOffProduct(product({
        'energy-kcal_100g': 250,
        'proteins_100g': 5,
        'carbohydrates_100g': 30,
        'fat_100g': 12,
      }));
      expect(r!.macros.caloriesKcal, 250);
    });

    test('a fat-dense product reads dense', () {
      // 500 kcal, 40 g fat → 360 fat-kcal = 72% → dense.
      final r = parseOffProduct(product({
        'energy-kcal_serving': 500,
        'fat_serving': 40,
        'proteins_serving': 5,
        'carbohydrates_serving': 30,
      }));
      expect(r!.macros.quality, 'dense');
    });

    test('returns null when the product has no usable energy', () {
      expect(parseOffProduct(product({'salt_100g': 1.2})), isNull);
    });

    test('returns null when the barcode is unknown (status 0)', () {
      expect(parseOffProduct({'status': 0, 'status_verbose': 'not found'}),
          isNull);
    });

    test('handles a missing product name gracefully', () {
      final r = parseOffProduct({
        'status': 1,
        'product': {
          'nutriments': {'energy-kcal_serving': 100}
        },
      });
      expect(r!.name, 'Scanned item');
    });
  });
}
