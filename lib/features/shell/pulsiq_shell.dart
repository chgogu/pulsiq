import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/pulse_wave.dart';
import '../../widgets/universal_fab.dart';

/// Hosts every screen behind the universal FAB and the voice-recording
/// overlay, so both persist across navigation (spec §2).
class PulsIQShell extends StatefulWidget {
  const PulsIQShell({super.key, required this.child});

  final Widget child;

  @override
  State<PulsIQShell> createState() => _PulsIQShellState();
}

class _PulsIQShellState extends State<PulsIQShell> {
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
    _toast(const Text('Voice note captured — transcription lands in M4.'));
  }

  void _quickWater(int oz) {
    HapticFeedback.lightImpact();
    _toast(
      GestureDetector(
        onLongPress: oz == 8 ? () => _quickWater(16) : null,
        child: Row(
          children: [
            const Icon(Icons.water_drop_outlined, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                oz == 8
                    ? '+8 oz water logged · hold to make it 16 oz'
                    : '+16 oz water logged',
              ),
            ),
          ],
        ),
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
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_recording)
            _RecordingOverlay(elapsedSeconds: _elapsedSeconds),
        ],
      ),
      floatingActionButton: UniversalFab(
        onQuickWater: () => _quickWater(8),
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

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay({required this.elapsedSeconds});

  final int elapsedSeconds;

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
