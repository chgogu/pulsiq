import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../voice/voice_pipeline.dart';
import '../../widgets/pulse_wave.dart';
import '../../widgets/universal_fab.dart';

/// Hosts every screen behind the universal FAB and the voice-recording
/// overlay, so both persist across navigation (spec §2).
class PulsIQShell extends ConsumerStatefulWidget {
  const PulsIQShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PulsIQShell> createState() => _PulsIQShellState();
}

class _PulsIQShellState extends ConsumerState<PulsIQShell> {
  static const _maxRecordSeconds = 60;

  bool _recording = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    setState(() {
      _recording = true;
      _elapsedSeconds = 0;
    });
    ref.read(voicePipelineProvider.notifier).startListening();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_elapsedSeconds + 1 >= _maxRecordSeconds) {
        _stopRecording();
        return;
      }
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopRecording() {
    _ticker?.cancel();
    _ticker = null;
    if (!_recording) return;
    setState(() => _recording = false);
    ref.read(voicePipelineProvider.notifier).stopAndSubmit();
  }

  Future<void> _quickWater() async {
    HapticFeedback.lightImpact();
    final repo = ref.read(logRepositoryProvider);
    final id = await repo.quickAddWater(8);
    if (!mounted) return;
    _toast(
      GestureDetector(
        onLongPress: () {
          repo.upgradeWater(id, 16);
          _toast(
            const Row(children: [
              Icon(Icons.water_drop_outlined, color: Colors.white70),
              SizedBox(width: 10),
              Expanded(child: Text('Upgraded — +16 oz water logged')),
            ]),
          );
        },
        child: const Row(children: [
          Icon(Icons.water_drop_outlined, color: Colors.white70),
          SizedBox(width: 10),
          Expanded(
            child: Text('+8 oz water logged · hold to make it 16 oz'),
          ),
        ]),
      ),
    );
  }

  void _toast(Widget content) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: content, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Coaching messages arrive whenever the detached LLM round-trip lands.
    ref.listen(voicePipelineProvider, (previous, next) {
      final message = next.coachingMessage;
      if (message != null && message != previous?.coachingMessage) {
        _toast(Text(message));
        ref.read(voicePipelineProvider.notifier).consumeMessage();
      }
    });
    final voice = ref.watch(voicePipelineProvider);
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (voice.phase == VoicePhase.thinking)
            const Positioned(
              right: 20,
              bottom: 96,
              child: _ThinkingChip(),
            ),
          if (_recording)
            _RecordingOverlay(
              elapsedSeconds: _elapsedSeconds,
              transcript: voice.transcript,
            ),
        ],
      ),
      floatingActionButton: UniversalFab(
        onQuickWater: _quickWater,
        onRecordStart: _startRecording,
        onRecordEnd: _stopRecording,
        onMenuScan: () {
          HapticFeedback.selectionClick();
          if (GoRouterState.of(context).uri.path != '/order-hack') {
            context.push('/order-hack');
          }
        },
      ),
    );
  }
}

class _ThinkingChip extends StatelessWidget {
  const _ThinkingChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text('PulsIQ is thinking…', style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay({
    required this.elapsedSeconds,
    required this.transcript,
  });

  final int elapsedSeconds;
  final String transcript;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Listening…',
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const PulseWave(height: 64, strokeWidth: 3),
                    const SizedBox(height: 16),
                    if (transcript.isNotEmpty) ...[
                      Text(
                        transcript,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '0:${elapsedSeconds.toString().padLeft(2, '0')} / 1:00',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Release to submit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
