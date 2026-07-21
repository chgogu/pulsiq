import 'package:flutter/material.dart';

import '../theme/pulse_theme.dart';

/// The universal action button (spec §2): tap = quick water, hold = voice
/// note, swipe up = menu scan. Present on every screen inside the shell.
class UniversalFab extends StatefulWidget {
  const UniversalFab({
    super.key,
    required this.onQuickWater,
    required this.onRecordStart,
    required this.onRecordEnd,
    required this.onMenuScan,
  });

  final VoidCallback onQuickWater;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordEnd;
  final VoidCallback onMenuScan;

  @override
  State<UniversalFab> createState() => _UniversalFabState();
}

class _UniversalFabState extends State<UniversalFab> {
  static const _swipeThreshold = -36.0;

  double _dragDy = 0;
  bool _swipeFired = false;
  bool _holding = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'PulsIQ actions: tap to log water, hold to record a voice note, '
          'swipe up to scan a menu',
      child: GestureDetector(
        key: const ValueKey('universal-fab'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onQuickWater,
        onLongPressStart: (_) {
          setState(() => _holding = true);
          widget.onRecordStart();
        },
        onLongPressEnd: (_) {
          setState(() => _holding = false);
          widget.onRecordEnd();
        },
        onVerticalDragStart: (_) {
          _dragDy = 0;
          _swipeFired = false;
        },
        onVerticalDragUpdate: (details) {
          _dragDy += details.delta.dy;
          if (!_swipeFired && _dragDy < _swipeThreshold) {
            _swipeFired = true;
            widget.onMenuScan();
          }
        },
        child: AnimatedScale(
          scale: _holding ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PulseColors.pulse, PulseColors.pulseDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: PulseColors.pulse.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _holding ? Icons.mic : Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
