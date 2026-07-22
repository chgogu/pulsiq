import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart' show FuelQuality;
import 'package:pulsiq/domain/meal_vision.dart';
import 'package:pulsiq/llm/llm_client.dart';

/// A backend that returns canned JSON, so the estimator's parsing and summing
/// can be exercised without a network or a proxy.
class _StubBackend implements LlmBackend {
  _StubBackend(this._json, {this.throwIt = false});
  final String _json;
  final bool throwIt;

  @override
  String get name => 'stub';

  @override
  Future<String> analyzeMealImage({
    required String base64Image,
    String hint = '',
  }) async {
    if (throwIt) throw Exception('down');
    return _json;
  }

  @override
  Future<String> complete(String userText) async => _json;
  @override
  Future<String> analyzeMenu(String menuText) async => _json;
}

const _twoItem = '''
{"confidence":"medium","note":"",
 "items":[
   {"name":"Cooked Quinoa","portion":"1 cup","calories":220,"protein_g":8,
    "fiber_g":5,"carbs_g":39,"fat_g":4,"quality_score":"clean"},
   {"name":"Toor Dal","portion":"1/2 cup","calories":100,"protein_g":6,
    "fiber_g":4,"carbs_g":18,"fat_g":1,"quality_score":"moderate"}
 ]}''';

void main() {
  group('text estimation reaches the backend', () {
    test('estimateMealFromText sends the description as the hint, no image',
        () async {
      String? seenImage;
      String? seenHint;
      final backend = _CapturingBackend((img, hint) {
        seenImage = img;
        seenHint = hint;
      }, _twoItem);
      final coach = LlmCoach(primary: backend, fallback: backend);

      final raw = await coach.estimateMealFromText('quinoa and toor dal');
      expect(raw, isNotNull);
      expect(seenImage, isEmpty, reason: 'no photo for a text estimate');
      expect(seenHint, 'quinoa and toor dal');
    });

    test('falls back to the second backend when the first throws', () async {
      final coach = LlmCoach(
        primary: _StubBackend('', throwIt: true),
        fallback: _StubBackend(_twoItem),
      );
      final raw = await coach.estimateMealFromText('anything');
      expect(raw, isNotNull);
      expect(parseMealVision(raw!).items, hasLength(2));
    });

    test('returns null when every backend is down', () async {
      final coach = LlmCoach(
        primary: _StubBackend('', throwIt: true),
        fallback: _StubBackend('', throwIt: true),
      );
      expect(await coach.estimateMealFromText('anything'), isNull);
    });
  });

  group('summing a multi-item plate', () {
    test('totals add up across items', () {
      final r = parseMealVision(_twoItem);
      expect(r.totalCalories, 320);
      expect(r.totalProtein, 14);
      expect(r.totalFiber, 9);
      expect(r.totalCarbs, 57);
      expect(r.totalFat, 5);
    });

    test('overall quality is the least-clean component', () {
      // clean + moderate -> moderate defines how the plate eats.
      expect(parseMealVision(_twoItem).overallQuality, 'moderate');
      expect(FuelQuality.values.byName(parseMealVision(_twoItem).overallQuality),
          FuelQuality.moderate);
    });

    test('a single dense item drives the whole plate dense', () {
      const json = '''
      {"confidence":"high","note":"","items":[
        {"name":"Salad","portion":"1 bowl","calories":200,"protein_g":8,
         "fiber_g":7,"carbs_g":18,"fat_g":12,"quality_score":"clean"},
        {"name":"Fried chicken","portion":"2 pc","calories":500,"protein_g":30,
         "fiber_g":1,"carbs_g":20,"fat_g":35,"quality_score":"dense"}
      ]}''';
      expect(parseMealVision(json).overallQuality, 'dense');
    });
  });
}

/// Backend that records what it was called with, then returns canned JSON.
class _CapturingBackend implements LlmBackend {
  _CapturingBackend(this._onCall, this._json);
  final void Function(String image, String hint) _onCall;
  final String _json;

  @override
  String get name => 'capturing';

  @override
  Future<String> analyzeMealImage({
    required String base64Image,
    String hint = '',
  }) async {
    _onCall(base64Image, hint);
    return _json;
  }

  @override
  Future<String> complete(String userText) async => _json;
  @override
  Future<String> analyzeMenu(String menuText) async => _json;
}
