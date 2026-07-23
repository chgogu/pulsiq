import 'package:flutter/material.dart';

/// One metric's day-by-day trend across the card's window.
///
/// A single series, so there's no legend — the selector chip above names it.
/// Only the extremes and the scrubbed point get labels; a number on every
/// point would be noise at this size. Days the source never recorded stay
/// gaps: the line breaks rather than inventing a straight edge through them.
class MetricTrendPoint {
  const MetricTrendPoint(this.day, this.value);
  final DateTime day;

  /// Null when the source recorded nothing that day.
  final double? value;
}

class MetricTrendChart extends StatefulWidget {
  const MetricTrendChart({
    super.key,
    required this.points,
    required this.label,
    this.decimals = 0,
    this.unit = '',
    this.height = 132,
  });

  final List<MetricTrendPoint> points;
  final String label;
  final int decimals;
  final String unit;
  final double height;

  @override
  State<MetricTrendChart> createState() => _MetricTrendChartState();
}

class _MetricTrendChartState extends State<MetricTrendChart> {
  int? _scrubIndex;

  String _fmt(double v) =>
      '${v.toStringAsFixed(widget.decimals)}${widget.unit}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withValues = [
      for (final p in widget.points)
        if (p.value != null) p.value!,
    ];
    if (withValues.length < 2) return const SizedBox.shrink();

    final avg = withValues.reduce((a, b) => a + b) / withValues.length;
    final scrubbed = _scrubIndex == null ? null : widget.points[_scrubIndex!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Readout doubles as the scrub display, so the chart never needs a
        // floating tooltip that would clip inside a card.
        SizedBox(
          height: 20,
          child: Row(
            children: [
              Text(
                scrubbed?.value != null
                    ? _fmt(scrubbed!.value!)
                    : _fmt(withValues.last),
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
              const SizedBox(width: 8),
              Text(
                scrubbed != null ? _dayLabel(scrubbed.day) : 'latest',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text('avg ${_fmt(avg)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Semantics(
          label: '${widget.label} trend over ${widget.points.length} days. '
              'Latest ${_fmt(withValues.last)}, average ${_fmt(avg)}.',
          child: GestureDetector(
            onHorizontalDragUpdate: (d) => _scrub(d.localPosition.dx),
            onHorizontalDragEnd: (_) => setState(() => _scrubIndex = null),
            onHorizontalDragCancel: () => setState(() => _scrubIndex = null),
            onTapDown: (d) => _scrub(d.localPosition.dx),
            onTapUp: (_) => setState(() => _scrubIndex = null),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPainter(
                  points: widget.points,
                  average: avg,
                  scrubIndex: _scrubIndex,
                  line: theme.colorScheme.primary,
                  surface: theme.cardTheme.color ?? theme.colorScheme.surface,
                  axis: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.points.length} days ago',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text('today',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  void _scrub(double dx) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    if (width <= 0 || widget.points.length < 2) return;
    final i = ((dx / width) * (widget.points.length - 1))
        .round()
        .clamp(0, widget.points.length - 1);
    if (i != _scrubIndex) setState(() => _scrubIndex = i);
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.average,
    required this.scrubIndex,
    required this.line,
    required this.surface,
    required this.axis,
  });

  final List<MetricTrendPoint> points;
  final double average;
  final int? scrubIndex;
  final Color line;
  final Color surface;
  final Color axis;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      for (final p in points)
        if (p.value != null) p.value!,
    ];
    if (values.length < 2) return;

    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);
    if (max - min < 1e-9) {
      // A flat series would divide by zero; give it a band to sit in.
      min -= 1;
      max += 1;
    }
    // Headroom so the top mark and its label don't touch the card edge.
    const padTop = 14.0;
    const padBottom = 8.0;
    final h = size.height - padTop - padBottom;

    double x(int i) => points.length == 1
        ? 0
        : size.width * (i / (points.length - 1));
    double y(double v) => padTop + h - ((v - min) / (max - min)) * h;

    // Average reference line, recessive and dashed — context, not a series.
    final avgY = y(average);
    final dash = Paint()
      ..color = axis
      ..strokeWidth = 1;
    for (var dx = 0.0; dx < size.width; dx += 6) {
      canvas.drawLine(Offset(dx, avgY), Offset(dx + 3, avgY), dash);
    }

    // Contiguous runs only: a gap in the data stays a gap in the line.
    final runs = <List<({double dx, double dy})>>[];
    var run = <({double dx, double dy})>[];
    for (var i = 0; i < points.length; i++) {
      final v = points[i].value;
      if (v == null) {
        if (run.length > 1) runs.add(run);
        run = [];
        continue;
      }
      run.add((dx: x(i), dy: y(v)));
    }
    if (run.length > 1) runs.add(run);

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (final r in runs) {
      final path = Path()..moveTo(r.first.dx, r.first.dy);
      for (final p in r.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }

      // Area fill under the run, fading out so it reads as depth not a second
      // series.
      final fill = Path.from(path)
        ..lineTo(r.last.dx, size.height)
        ..lineTo(r.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.20), line.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(path, stroke);
    }

    // Latest point, ringed in the surface colour so it stays legible over the
    // line and fill.
    final lastIndex = points.lastIndexWhere((p) => p.value != null);
    if (lastIndex >= 0) {
      final c = Offset(x(lastIndex), y(points[lastIndex].value!));
      canvas.drawCircle(c, 5.5, Paint()..color = surface);
      canvas.drawCircle(c, 4, Paint()..color = line);
    }

    // Scrub marker: vertical rule + point, drawn last so it sits on top.
    final i = scrubIndex;
    if (i != null && points[i].value != null) {
      final sx = x(i);
      canvas.drawLine(
        Offset(sx, padTop - 6),
        Offset(sx, size.height),
        Paint()
          ..color = line.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
      final c = Offset(sx, y(points[i].value!));
      canvas.drawCircle(c, 6.5, Paint()..color = surface);
      canvas.drawCircle(c, 5, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.scrubIndex != scrubIndex ||
      old.points != points ||
      old.line != line;
}
