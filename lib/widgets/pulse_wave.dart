import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The PulsIQ waveform motif: a calm baseline ripple with one soft "beat"
/// that drifts across. Deliberately gentle — not an EKG trace.
class PulseWave extends StatefulWidget {
  const PulseWave({
    super.key,
    this.height = 44,
    this.color,
    this.strokeWidth = 2.5,
    this.animate = true,
  });

  final double height;
  final Color? color;
  final double strokeWidth;
  final bool animate;

  @override
  State<PulseWave> createState() => _PulseWaveState();
}

class _PulseWaveState extends State<PulseWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) _controller.repeat();
    if (!animate && _controller.isAnimating) _controller.stop();
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          painter: _PulseWavePainter(
            phase: _controller.value,
            color: color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _PulseWavePainter extends CustomPainter {
  _PulseWavePainter({
    required this.phase,
    required this.color,
    required this.strokeWidth,
  });

  final double phase;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height * 0.62;
    final beatX = size.width * phase;
    final path = Path()..moveTo(0, mid);
    for (double x = 0; x <= size.width; x += 2) {
      final ripple =
          math.sin(x / size.width * math.pi * 4 + phase * 2 * math.pi) *
              size.height *
              0.06;
      final d = (x - beatX) / (size.width * 0.06);
      final beat = math.exp(-d * d) * size.height * 0.34;
      path.lineTo(x, mid + ripple - beat);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PulseWavePainter old) =>
      old.phase != phase || old.color != color;
}
