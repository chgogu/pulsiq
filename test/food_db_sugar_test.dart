import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/food_db.dart';

void main() {
  final db = FoodDb.parse(File('assets/nutrition/foods.json').readAsStringSync());

  test('a sugary food carries sugar from the table', () {
    final r = db.resolve('banana');
    expect(r, isNotNull);
    // ~118 g banana at ~12 g/100 g ≈ 14 g sugar.
    expect(r!.sugarG, greaterThan(8));
  });

  test('a savoury food correctly reports ~0 sugar', () {
    final r = db.resolve('2 eggs');
    expect(r, isNotNull);
    expect(r!.sugarG, lessThan(1));
  });
}
