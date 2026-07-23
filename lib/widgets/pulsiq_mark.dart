import 'package:flutter/material.dart';

import '../theme/pulse_theme.dart';

/// The PulsIQ logo: a ring with an ECG trace cutting through it, stroked in
/// the coral→gold brand gradient.
///
/// This is a hand-port of the `<svg>` mark on pulsiqapp.com — same 27×27
/// viewBox, same path, same gradient — so the app and the site show the exact
/// same logo rather than two drawings that merely resemble each other.
class PulsIQMark extends StatelessWidget {
  const PulsIQMark({super.key, this.size = 28, this.color});

  final double size;

  /// Overrides the brand gradient with a flat colour — for places where the
  /// mark sits inline with text and should inherit its ink.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarkPainter(color),
        isComplex: false,
      ),
    );
  }
}

/// The logo beside the wordmark, as the site's nav renders it.
class PulsIQWordmark extends StatelessWidget {
  const PulsIQWordmark({super.key, this.fontSize = 30, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulsIQMark(size: fontSize * 0.95),
        SizedBox(width: fontSize * 0.3),
        Text(
          'PulsIQ',
          style: TextStyle(
            fontFamily: pulsiqFontFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * fontSize,
            color: ink,
          ),
        ),
      ],
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color? color;

  // Source viewBox from the site's SVG; everything below is scaled from it.
  static const _vb = 27.0;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _vb;
    final rect = Offset.zero & size;

    Paint stroke(double width) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;
      if (color != null) {
        p.color = color!;
      } else {
        p.shader = PulseColors.brandGradient.createShader(rect);
      }
      return p;
    }

    canvas.drawCircle(Offset(13.5 * k, 13.5 * k), 12 * k, stroke(1.7));

    // M4 13.5H9L11.2 8L14.8 19L17 13.5H23
    final trace = Path()
      ..moveTo(4 * k, 13.5 * k)
      ..lineTo(9 * k, 13.5 * k)
      ..lineTo(11.2 * k, 8 * k)
      ..lineTo(14.8 * k, 19 * k)
      ..lineTo(17 * k, 13.5 * k)
      ..lineTo(23 * k, 13.5 * k);
    canvas.drawPath(trace, stroke(2));
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}
