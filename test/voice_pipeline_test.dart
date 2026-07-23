import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/providers.dart';
import 'package:pulsiq/llm/llm_client.dart';
import 'package:pulsiq/voice/stt_service.dart';
import 'package:pulsiq/voice/voice_pipeline.dart';

class FakeStt implements SttService {
  FakeStt(this.transcript);

  final String transcript;
  SttResultHandler? _handler;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> start(SttResultHandler onResult) async {
    _handler = onResult;
    onResult(transcript, 0.92, false);
  }

  @override
  Future<void> stop() async {
    _handler?.call(transcript, 0.92, true);
  }
}

class DeadBackend implements LlmBackend {
  const DeadBackend();

  @override
  String get name => 'dead';

  @override
  Future<String> complete(String userText) async =>
      throw Exception('offline');

  @override
  Future<String> analyzeMenu(String menuText) async =>
      throw Exception('offline');

  @override
  Future<String> analyzeMealImage({
    required String base64Image,
    String hint = '',
  }) async =>
      throw Exception('offline');
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  ProviderContainer makeContainer(String transcript, {LlmCoach? coach}) {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      sttServiceProvider.overrideWithValue(FakeStt(transcript)),
      // Always override: the real provider now points at the production API
      // by default, so without this the pipeline would try to reach the
      // network from a unit test.
      llmCoachProvider.overrideWithValue(coach ??
          LlmCoach(
              primary: const MockLlmBackend(),
              fallback: const MockLlmBackend())),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('voice note becomes structured DB rows and a coaching message',
      () async {
    container =
        makeContainer('had a bowl of pasta and 500 ml water after a walk');
    final pipeline = container.read(voicePipelineProvider.notifier);

    await pipeline.startListening();
    expect(container.read(voicePipelineProvider).transcript,
        contains('pasta'));

    await pipeline.stopAndSubmit();
    await _settle();

    final state = container.read(voicePipelineProvider);
    expect(state.phase, VoicePhase.idle);
    expect(state.coachingMessage, isNotEmpty);

    expect((await db.watchTodayFoods().first).single.qualityScore,
        FuelQuality.dense);
    expect(await db.watchTodayHydrationMl().first, 500);
    expect((await db.watchTodayExercise().first).single.activity, 'walk');

    final audit = await db.watchAudit().first;
    expect(audit.map((e) => e.dataType),
        containsAll(['food', 'hydration', 'exercise']));
  });

  test('empty transcript never calls the LLM and nudges the user',
      () async {
    container = makeContainer('');
    final pipeline = container.read(voicePipelineProvider.notifier);
    await pipeline.startListening();
    await pipeline.stopAndSubmit();
    await _settle();

    final state = container.read(voicePipelineProvider);
    expect(state.coachingMessage, contains("Didn't catch"));
    expect(await db.watchTodayFoods().first, isEmpty);
  });

  test('dead backends fall back to raw-text logging', () async {
    container = makeContainer(
      'two eggs and toast',
      coach: LlmCoach(
          primary: const DeadBackend(), fallback: const DeadBackend()),
    );
    final pipeline = container.read(voicePipelineProvider.notifier);
    await pipeline.startListening();
    await pipeline.stopAndSubmit();
    await _settle();

    final foods = await db.watchTodayFoods().first;
    expect(foods.single.name, 'Voice note (unparsed)');
    expect(foods.single.quantity, 'two eggs and toast');
  });
}
