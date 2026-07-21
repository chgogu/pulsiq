import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/baseline_engine.dart';
import 'package:pulsiq/domain/evening_forecast.dart';
import 'package:pulsiq/domain/menu_hack.dart';
import 'package:pulsiq/domain/sweetness.dart';
import 'package:pulsiq/llm/llm_client.dart';

void main() {
  group('Order Hack parsing', () {
    const valid = '''
    {"headline": "Top picks",
     "top_picks": [
       {"name": "Salmon bowl", "why": "Lean protein.", "energy_rating": "steady"},
       {"name": "Grain bowl", "why": "Fiber.", "energy_rating": "moderate"},
       {"name": "Burger", "why": "Dense.", "energy_rating": "spike"}
     ]}''';

    test('parses picks and caps at three', () {
      final r = parseOrderHack(valid);
      expect(r.picks, hasLength(3));
      expect(r.picks.first.name, 'Salmon bowl');
      expect(r.picks.first.energyRating, 'steady');
    });

    test('rejects bad energy_rating', () {
      final bad = valid.replaceFirst('"steady"', '"amazing"');
      expect(() => parseOrderHack(bad), throwsFormatException);
    });

    test('rejects empty pick list', () {
      expect(
        () => parseOrderHack('{"headline": "x", "top_picks": []}'),
        throwsFormatException,
      );
    });
  });

  group('MockLlmBackend.analyzeMenu', () {
    test('ranks steady options above spikes', () async {
      final raw = await const MockLlmBackend().analyzeMenu(
          'Fried chicken sandwich, grilled salmon salad, chocolate shake');
      final result = parseOrderHack(raw);
      expect(result.picks.first.energyRating, 'steady');
      expect(result.picks.length, greaterThanOrEqualTo(2));
    });

    test('always yields a pick even for an unhelpful menu', () async {
      final raw = await const MockLlmBackend().analyzeMenu('???');
      expect(parseOrderHack(raw).picks, isNotEmpty);
    });
  });

  group('Sweetness adjuster', () {
    test('fires above 15 g or when user-flagged', () {
      expect(isTooSweet(20), isTrue);
      expect(isTooSweet(10), isFalse);
      expect(isTooSweet(10, userFlagged: true), isTrue);
    });

    test('hack names the drink and suggests dilution', () {
      final hack = sweetnessHack('Caramel latte', 24)!;
      expect(hack, contains('Caramel latte'));
      expect(hack.toLowerCase(), contains('soda water'));
    });

    test('no hack for a low-sugar drink', () {
      expect(sweetnessHack('Black coffee', 0), isNull);
    });
  });

  group('Evening forecast', () {
    test('cites HRV when it is the strongest positive signal', () {
      final f = computeForecast(ForecastInput(
        rhr: const BaselineResult(today: 60, avg7: 61),
        hrv: const BaselineResult(today: 75, avg7: 60),
        exerciseMinutes: 30,
      ));
      expect(f.headline, contains('solid recovery'));
      expect(f.signal, contains('HRV'));
    });

    test('flags a restless night on hot RHR + dense fuel + late caffeine',
        () {
      final f = computeForecast(ForecastInput(
        rhr: const BaselineResult(today: 70, avg7: 61),
        hrv: const BaselineResult(today: 58, avg7: 60),
        denseFuelCount: 2,
        lateCaffeine: true,
      ));
      expect(f.headline, contains('restless'));
    });

    test('is steady and honest when nothing stands out', () {
      final f = computeForecast(ForecastInput(
        rhr: const BaselineResult(today: 61, avg7: 61),
        hrv: const BaselineResult(today: 60, avg7: 60),
      ));
      expect(f.headline.toLowerCase(), contains('steady'));
      expect(f.signal, isNotEmpty);
    });
  });
}
