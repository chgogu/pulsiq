import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/food_db.dart';

void main() {
  final db =
      FoodDb.parse(File('assets/nutrition/foods.json').readAsStringSync());

  test('plurals and compound spellings resolve to the same food', () {
    // All three spellings of the same nut used to MISS; only the exact stored
    // alias worked. They must now land on one entry.
    final a = db.resolve('brazilnut');
    final b = db.resolve('brazil nut');
    final c = db.resolve('brazil nuts');
    expect(a, isNotNull);
    expect(b, isNotNull);
    expect(c, isNotNull);
    expect(a!.caloriesKcal, b!.caloriesKcal);
    expect(b.caloriesKcal, c!.caloriesKcal);
  });

  test('singular and plural of a common food both resolve', () {
    expect(db.resolve('almond'), isNotNull);
    expect(db.resolve('almonds'), isNotNull);
  });

  test('multi-food meals and portions still work (no regression)', () {
    expect(db.resolve('2 eggs'), isNotNull);
    expect(db.resolve('1 cup rice'), isNotNull);
    expect(db.resolve('grilled chicken'), isNotNull);
    final combo = db.resolve('chicken and rice');
    expect(combo, isNotNull);
    expect(combo!.itemCount, 2);
  });

  test('a genuinely unknown food still misses (escalates)', () {
    expect(db.resolve('xyzzy quantum gruel'), isNull);
  });
}
