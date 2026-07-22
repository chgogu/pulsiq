import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/foundation_model.dart';

void main() {
  group('itemsFromModelJson', () {
    test('flattens items to "quantity name" joined by commas', () {
      const raw =
          '{"items":[{"name":"quinoa","quantity":"1 cup"},{"name":"spinach","quantity":""},{"name":"egg whites","quantity":"2"}]}';
      expect(itemsFromModelJson(raw), '1 cup quinoa, spinach, 2 egg whites');
    });

    test('tolerates prose wrapped around the JSON', () {
      const raw =
          'Sure! Here you go:\n{"items":[{"name":"oatmeal","quantity":"1 bowl"}]}\nHope that helps.';
      expect(itemsFromModelJson(raw), '1 bowl oatmeal');
    });

    test('drops "1 serving" so the DB uses its own default portion', () {
      const raw = '{"items":[{"name":"toast","quantity":"1 serving"}]}';
      expect(itemsFromModelJson(raw), 'toast');
    });

    test('skips items with no name', () {
      const raw =
          '{"items":[{"name":"","quantity":"2"},{"name":"banana","quantity":"1"}]}';
      expect(itemsFromModelJson(raw), '1 banana');
    });

    test('returns null when there is no JSON object', () {
      expect(itemsFromModelJson("I can't help with that"), isNull);
    });

    test('returns null on an empty item list', () {
      expect(itemsFromModelJson('{"items":[]}'), isNull);
    });
  });
}
