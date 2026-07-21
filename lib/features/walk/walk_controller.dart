import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../services/notification_service.dart';

class WalkState {
  const WalkState({
    this.active = false,
    this.targetMinutes = 0,
    this.elapsedSeconds = 0,
    this.sessionId,
  });

  final bool active;
  final int targetMinutes;
  final int elapsedSeconds;
  final int? sessionId;

  int get targetSeconds => targetMinutes * 60;
  double get progress =>
      targetSeconds == 0 ? 0 : (elapsedSeconds / targetSeconds).clamp(0.0, 1.0);
  int get remainingSeconds => (targetSeconds - elapsedSeconds).clamp(0, 1 << 31);
  bool get complete => active && elapsedSeconds >= targetSeconds;

  WalkState copyWith({
    bool? active,
    int? targetMinutes,
    int? elapsedSeconds,
    int? sessionId,
  }) =>
      WalkState(
        active: active ?? this.active,
        targetMinutes: targetMinutes ?? this.targetMinutes,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        sessionId: sessionId ?? this.sessionId,
      );
}

/// Runs the active post-meal walk (spec §3): an in-app timer card plus an
/// ongoing notification (Android foreground-service style / iOS Live
/// Activity stand-in). Completing it marks the WalkSessions row done, which
/// feeds the PulsIQ Score.
class WalkController extends Notifier<WalkState> {
  Timer? _ticker;

  @override
  WalkState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const WalkState();
  }

  Future<void> start({required int targetMinutes, String source = 'nudge'}) async {
    if (state.active) return;
    final id = await ref
        .read(logRepositoryProvider)
        .startWalk(targetMinutes: targetMinutes, source: source);
    state = WalkState(
      active: true,
      targetMinutes: targetMinutes,
      elapsedSeconds: 0,
      sessionId: id,
    );
    _pushActivity();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.active) return;
    state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    if (state.elapsedSeconds % 15 == 0 || state.complete) _pushActivity();
    if (state.complete) complete();
  }

  void _pushActivity() {
    final mins = (state.remainingSeconds / 60).ceil();
    ref.read(notificationServiceProvider).showWalkActivity(
          body: state.complete
              ? 'Walk complete — nice work.'
              : '$mins min left · keep the energy steady',
          progressMax: state.targetSeconds,
          progress: state.elapsedSeconds,
        );
  }

  Future<void> complete() async {
    if (!state.active) return;
    _ticker?.cancel();
    final id = state.sessionId;
    if (id != null) {
      await ref.read(appDatabaseProvider).markWalkComplete(id);
    }
    await ref.read(notificationServiceProvider).clearWalkActivity();
    state = const WalkState();
    // The completed walk now counts toward today's active minutes and score.
    ref.invalidate(todayExerciseMinutesProvider);
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    await ref.read(notificationServiceProvider).clearWalkActivity();
    state = const WalkState();
  }
}

final walkControllerProvider =
    NotifierProvider<WalkController, WalkState>(WalkController.new);
