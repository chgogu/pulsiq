import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/llm_contract.dart';
import 'package:pulsiq/llm/llm_client.dart';

const _validJson = '''
{
  "log_summary": {
    "food_items": [{"name": "Burrito bowl", "quantity": "1", "quality_score": "moderate"}],
    "beverages": [{"name": "Latte", "sugar_content_g": 9, "type": "caffeine"}],
    "hydration_added_ml": 500,
    "exercise_logged": [{"activity": "walk", "duration_minutes": 25, "intensity": "moderate"}]
  },
  "energy_impact_analysis": {
    "glycemic_load_estimate": "steady",
    "post_meal_action_required": false,
    "recommended_walk_minutes": 0
  },
  "coaching_message": "Solid, steady fuel."
}
''';

class ScriptedBackend implements LlmBackend {
  ScriptedBackend(this.replies, {this.name = 'scripted'});

  final List<String> replies;
  final List<String> prompts = [];
  @override
  final String name;

  @override
  Future<String> complete(String userText) async {
    prompts.add(userText);
    if (replies.isEmpty) throw Exception('backend down');
    return replies.removeAt(0);
  }
}

void main() {
  group('parseCoachReply', () {
    test('parses bare JSON', () {
      final reply = parseCoachReply(_validJson);
      expect(reply.logSummary.foodItems.single.qualityScore, 'moderate');
      expect(reply.logSummary.hydrationAddedMl, 500);
      expect(reply.energyImpact.glycemicLoadEstimate, 'steady');
      expect(reply.coachingMessage, 'Solid, steady fuel.');
    });

    test('parses JSON inside fences with prose around it', () {
      final wrapped =
          'Nice log! Here it is:\n```json\n$_validJson\n```\nKeep going!';
      expect(parseCoachReply(wrapped).logSummary.beverages.single.type,
          'caffeine');
    });

    test('parses JSON embedded mid-prose without fences', () {
      final wrapped = 'Logged it. $_validJson That walk helps.';
      expect(
          parseCoachReply(wrapped).logSummary.exerciseLogged.single.activity,
          'walk');
    });

    test('missing required section throws', () {
      expect(() => parseCoachReply('{"coaching_message": "hi"}'),
          throwsFormatException);
    });

    test('invalid enum value throws', () {
      final bad = _validJson.replaceFirst('"steady"', '"turbo"');
      expect(() => parseCoachReply(bad), throwsFormatException);
    });

    test('empty lists are tolerated', () {
      const minimal = '''
      {"log_summary": {"food_items": [], "beverages": [],
        "hydration_added_ml": 0, "exercise_logged": []},
       "energy_impact_analysis": {"glycemic_load_estimate": "flat",
        "post_meal_action_required": false, "recommended_walk_minutes": 0},
       "coaching_message": "Nothing to log."}''';
      expect(parseCoachReply(minimal).isEmpty, isTrue);
    });
  });

  group('LlmCoach fallback chain', () {
    test('primary succeeds on first try', () async {
      final primary = ScriptedBackend([_validJson], name: 'claude');
      final fallback = ScriptedBackend([], name: 'gemini');
      final outcome = await LlmCoach(primary: primary, fallback: fallback)
          .process('lunch');
      expect(outcome.backendUsed, 'claude');
      expect(outcome.reply, isNotNull);
      expect(fallback.prompts, isEmpty);
    });

    test('invalid first reply triggers one fix-the-JSON retry', () async {
      final primary =
          ScriptedBackend(['not json at all', _validJson], name: 'claude');
      final outcome = await LlmCoach(
              primary: primary, fallback: ScriptedBackend([]))
          .process('lunch');
      expect(outcome.backendUsed, 'claude');
      expect(primary.prompts, hasLength(2));
      expect(primary.prompts[1], contains('valid JSON'));
    });

    test('primary failing twice falls back to gemini', () async {
      final primary = ScriptedBackend(['nope', 'still nope'], name: 'claude');
      final fallback = ScriptedBackend([_validJson], name: 'gemini');
      final outcome = await LlmCoach(primary: primary, fallback: fallback)
          .process('lunch');
      expect(outcome.backendUsed, 'gemini');
      expect(outcome.reply, isNotNull);
    });

    test('both backends down yields raw-text outcome', () async {
      final outcome = await LlmCoach(
        primary: ScriptedBackend([]),
        fallback: ScriptedBackend([]),
      ).process('two eggs and toast');
      expect(outcome.reply, isNull);
      expect(outcome.rawText, 'two eggs and toast');
    });
  });

  group('MockLlmBackend', () {
    test('extracts drink, water, and exercise from a transcript', () async {
      final raw = await const MockLlmBackend()
          .complete('had a latte, 500 ml water and a 20 minute run');
      final reply = parseCoachReply(raw);
      expect(reply.logSummary.beverages.single.type, 'caffeine');
      expect(reply.logSummary.hydrationAddedMl, 500);
      expect(reply.logSummary.exerciseLogged.single.durationMinutes, 20);
      expect(reply.logSummary.exerciseLogged.single.intensity, 'vigorous');
    });

    test('carb-dense meal flags a post-meal walk', () async {
      final raw =
          await const MockLlmBackend().complete('big bowl of pasta');
      final reply = parseCoachReply(raw);
      expect(reply.energyImpact.glycemicLoadEstimate, 'high_spike');
      expect(reply.energyImpact.postMealActionRequired, isTrue);
      expect(reply.energyImpact.recommendedWalkMinutes, greaterThan(0));
    });
  });
}
