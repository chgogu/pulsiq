import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/providers.dart';
import '../domain/llm_contract.dart';
import '../llm/llm_client.dart';
import '../services/notification_service.dart';
import 'stt_service.dart';

enum VoicePhase { idle, listening, thinking }

class VoiceState {
  const VoiceState({
    this.phase = VoicePhase.idle,
    this.transcript = '',
    this.coachingMessage,
  });

  final VoicePhase phase;
  final String transcript;

  /// One-shot: the shell shows it as a toast, then calls [VoicePipeline.consumeMessage].
  final String? coachingMessage;

  VoiceState copyWith({
    VoicePhase? phase,
    String? transcript,
    String? coachingMessage,
    bool clearMessage = false,
  }) {
    return VoiceState(
      phase: phase ?? this.phase,
      transcript: transcript ?? this.transcript,
      coachingMessage:
          clearMessage ? null : coachingMessage ?? this.coachingMessage,
    );
  }
}

/// Proxy URL is deployment config (no keys in the app). Until it exists,
/// both chain slots run the deterministic on-device mock so the pipeline
/// stays fully functional offline.
const _proxyUrl = String.fromEnvironment('PULSIQ_PROXY_URL');

final llmCoachProvider = Provider<LlmCoach>((_) {
  if (_proxyUrl.isEmpty) {
    return LlmCoach(
        primary: const MockLlmBackend(), fallback: const MockLlmBackend());
  }
  return LlmCoach(
    primary: ProxyBackend(baseUrl: _proxyUrl, model: 'claude'),
    fallback: ProxyBackend(baseUrl: _proxyUrl, model: 'gemini-flash'),
  );
});

class VoicePipeline extends Notifier<VoiceState> {
  @override
  VoiceState build() => const VoiceState();

  Future<void> startListening() async {
    state = state.copyWith(phase: VoicePhase.listening, transcript: '');
    await ref.read(sttServiceProvider).start((text, confidence, isFinal) {
      state = state.copyWith(transcript: text);
    });
  }

  /// Release-to-submit. Never blocks further logging: the LLM round-trip
  /// runs detached while the phase shows "thinking".
  Future<void> stopAndSubmit() async {
    await ref.read(sttServiceProvider).stop();
    final transcript = state.transcript.trim();
    if (transcript.isEmpty) {
      state = state.copyWith(
        phase: VoicePhase.idle,
        coachingMessage:
            "Didn't catch any words — try again, or use Add below.",
      );
      return;
    }
    state = state.copyWith(phase: VoicePhase.thinking);
    _process(transcript); // deliberately not awaited by callers
  }

  Future<void> _process(String transcript) async {
    final outcome = await ref.read(llmCoachProvider).process(transcript);
    final reply = outcome.reply;
    String message;
    if (reply == null) {
      // Last-resort fallback (spec §1): keep the raw words.
      await ref.read(logRepositoryProvider).addFood(
            name: 'Voice note (unparsed)',
            quantity: transcript,
            quality: FuelQuality.moderate,
          );
      message = 'Coach is unreachable — saved your words to the log.';
    } else if (reply.isEmpty) {
      message = reply.coachingMessage.isNotEmpty
          ? reply.coachingMessage
          : "Heard you, but there was nothing to log in that.";
    } else {
      await _applyReply(reply);
      message = reply.coachingMessage;
    }
    state = state.copyWith(
        phase: VoicePhase.idle, transcript: '', coachingMessage: message);
  }

  /// Contract beverages carry no volume; hydration arrives separately in
  /// hydration_added_ml, so water-type beverages insert with volume 0 (no
  /// double count) and diuretics get typical serving volumes for the
  /// 1:1 hydration-target offset.
  static const _defaultVolumes = {
    'caffeine': 240,
    'alcohol': 330,
    'protein': 300,
    'water': 0,
  };

  Future<void> _applyReply(CoachReply reply) async {
    final repo = ref.read(logRepositoryProvider);
    final summary = reply.logSummary;
    for (final food in summary.foodItems) {
      await repo.addFood(
        name: food.name,
        quantity: food.quantity,
        quality: FuelQuality.values.byName(food.qualityScore),
      );
    }
    var caffeineLogged = false;
    for (final beverage in summary.beverages) {
      caffeineLogged |= beverage.type == 'caffeine';
      await repo.addBeverage(
        name: beverage.name,
        volumeMl: _defaultVolumes[beverage.type] ?? 0,
        sugarContentG: beverage.sugarContentG,
        type: BeverageType.values.byName(beverage.type),
      );
    }
    if (summary.hydrationAddedMl > 0) {
      await repo.addHydration(amountMl: summary.hydrationAddedMl);
    }
    for (final exercise in summary.exerciseLogged) {
      await repo.addExercise(
        activity: exercise.activity,
        durationMinutes: exercise.durationMinutes,
        intensity: ExerciseIntensity.values.byName(exercise.intensity),
      );
    }
    if (caffeineLogged) {
      await ref.read(reminderSchedulerProvider).onCaffeineLogged();
    }
  }

  void consumeMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final voicePipelineProvider =
    NotifierProvider<VoicePipeline, VoiceState>(VoicePipeline.new);
