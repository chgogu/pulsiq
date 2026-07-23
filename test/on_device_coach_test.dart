import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/foundation_model.dart';
import 'package:pulsiq/domain/llm_contract.dart';
import 'package:pulsiq/llm/llm_client.dart';

/// Stand-in for the platform channel: returns canned JSON so the backend and
/// the coach chain can be exercised without a device.
class _FakeFm implements FoundationModel {
  _FakeFm({this.voice, this.meal});
  final String? voice;
  final String? meal;

  @override
  Future<bool> available() async => voice != null || meal != null;
  @override
  Future<String?> parseVoiceLog(String transcript) async => voice;
  @override
  Future<String?> estimateMeal(String description) async => meal;
}

void main() {
  const voiceJson = '{"log_summary":{"food_items":[{"name":"Chicken biryani",'
      '"quantity":"1 plate","quality_score":"dense","calories":600,'
      '"protein_g":25,"fiber_g":4,"carbs_g":78,"fat_g":22}],"beverages":[],'
      '"hydration_added_ml":0,"exercise_logged":[]},"energy_impact_analysis":'
      '{"glycemic_load_estimate":"high_spike","post_meal_action_required":true,'
      '"recommended_walk_minutes":12},"coaching_message":"Logged — a short '
      'walk keeps that biryani steady."}';

  test('on-device backend returns the model reply for a voice log', () async {
    final backend = OnDeviceCoachBackend(_FakeFm(voice: voiceJson));
    final out = await backend.complete('I had chicken biryani');
    expect(parseCoachReply(out).logSummary.foodItems.single.name,
        'Chicken biryani');
  });

  test('coach chain parses an on-device reply into a real log', () async {
    final coach = LlmCoach(
      primary: OnDeviceCoachBackend(_FakeFm(voice: voiceJson)),
      fallback: const MockLlmBackend(),
    );
    final outcome = await coach.process('I had chicken biryani');
    expect(outcome.backendUsed, 'apple-on-device');
    expect(outcome.reply, isNotNull);
    expect(outcome.reply!.logSummary.foodItems.single.caloriesKcal, 600);
  });

  test('falls back to the keyword mock when the model is unavailable',
      () async {
    // Older device: parseVoiceLog returns null → backend throws → the chain
    // uses the mock, which still logs something from keywords.
    final coach = LlmCoach(
      primary: OnDeviceCoachBackend(_FakeFm()),
      fallback: const MockLlmBackend(),
    );
    final outcome = await coach.process('had a salad and 500 ml water');
    expect(outcome.backendUsed, 'on-device-mock');
    expect(outcome.reply, isNotNull);
    expect(outcome.reply!.logSummary.hydrationAddedMl, 500);
  });

  test('meal estimate uses the model reply when the table misses', () async {
    const mealJson = '{"confidence":"medium","note":"",'
        '"items":[{"name":"Paneer tikka","portion":"1 serving","calories":350,'
        '"protein_g":18,"fiber_g":2,"carbs_g":10,"fat_g":26,'
        '"quality_score":"moderate"}]}';
    final backend = OnDeviceCoachBackend(_FakeFm(meal: mealJson));
    final out =
        await backend.analyzeMealImage(base64Image: '', hint: 'paneer tikka');
    expect(out, contains('Paneer tikka'));
  });
}
