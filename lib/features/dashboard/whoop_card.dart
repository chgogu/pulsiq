import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/whoop.dart';
import '../../health/body_signals.dart';
import '../../health/health_providers.dart';
import '../../health/whoop/whoop_client.dart';
import '../../health/whoop/whoop_providers.dart';
import 'metric_trend_chart.dart';

/// Recovery band → colour (theme-aware): green / amber / red.
({Color ring, Color tint}) _bandColors(RecoveryBand band, Brightness b) {
  final dark = b == Brightness.dark;
  final c = switch (band) {
    RecoveryBand.green => dark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
    RecoveryBand.yellow => dark ? const Color(0xFFEAB308) : const Color(0xFFCA8A04),
    RecoveryBand.red => dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
  };
  return (ring: c, tint: c.withValues(alpha: dark ? 0.16 : 0.10));
}

/// WHOOP's own card: recovery, strain, HRV, resting HR and sleep against their
/// 60-day averages. Hidden unless WHOOP is linked.
///
/// This and [PlatformHealthCard] are deliberately separate widgets fed by
/// separate providers, so disconnecting one source never blanks the other's
/// analytics.
class WhoopCard extends ConsumerWidget {
  const WhoopCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(whoopBodyProvider);
    return async.when(
      loading: () => const _Shell(title: 'Body signals', child: _Loading()),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        if (result == null) return const SizedBox.shrink(); // not linked
        return switch (result.status) {
          WhoopFetchStatus.ok => _Shell(
              title: 'Body signals',
              onRefresh: () => ref.invalidate(whoopBodyProvider),
              child: _Signals(
                signals: BodySignals(
                  body: result.body!,
                  source: BodySignalSource.whoop,
                  windowDays: 60,
                ),
              ),
            ),
          WhoopFetchStatus.empty => const _Shell(
              title: 'Body signals',
              child: _Note(
                icon: Icons.hourglass_empty,
                text: 'Connected — waiting for your next sync. Recovery and '
                    'sleep appear after your next logged night.',
              ),
            ),
          WhoopFetchStatus.noAccess => _Shell(
              title: 'Body signals',
              child: _Note(
                icon: Icons.link_off,
                text: 'Your wearable session expired. Reconnect in Settings to '
                    'keep your signals flowing in.',
                action: ('Settings', () => context.push('/settings')),
              ),
            ),
          WhoopFetchStatus.error => _Shell(
              title: 'Body signals',
              onRefresh: () => ref.invalidate(whoopBodyProvider),
              child: const _Note(
                icon: Icons.cloud_off,
                text: "Couldn't reach your wearable's data. Check your "
                    'connection, then retry.',
              ),
            ),
        };
      },
    );
  }
}

/// Apple Health / Health Connect's own card: HRV, resting HR, sleep, steps and
/// active minutes over the last 30 days. Stands alone — it renders whether or
/// not WHOOP is connected.
class PlatformHealthCard extends ConsumerWidget {
  const PlatformHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(platformBodySignalsProvider);
    return async.when(
      error: (_, _) => const SizedBox.shrink(),
      loading: () => const _Shell(title: 'Health analytics', child: _Loading()),
      data: (signals) {
        if (signals == null || signals.isEmpty) {
          return const SizedBox.shrink(); // not connected, or nothing synced
        }
        return _Shell(
          title: '${signals.source.label} analytics',
          onRefresh: () => ref.invalidate(platformBodySignalsProvider),
          child: _Signals(signals: signals),
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.child, this.onRefresh});

  final String title;
  final Widget child;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.monitor_heart_outlined,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  // Titles vary in length now that each source names itself;
                  // an unconstrained Text here overflowed at phone width.
                  Expanded(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.3)),
                  ),
                  if (onRefresh != null)
                    IconButton(
                      tooltip: 'Refresh',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: onRefresh,
                    ),
                ],
              ),
              Padding(padding: const EdgeInsets.only(right: 8), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const SizedBox(
              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Reading your recovery and history…',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (action != null)
                  TextButton(onPressed: action!.$2, child: Text(action!.$1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A metric the connected source actually recorded, with how to read and
/// format it. Built once and reused for the rows, the chips, and the chart so
/// the three can't disagree about what's available.
class _TrackedMetric {
  const _TrackedMetric(this.label, this.pick,
      {this.unit = '', this.decimals = 0});

  final String label;
  final num? Function(WhoopDay) pick;
  final String unit;
  final int decimals;
}

class _Signals extends StatelessWidget {
  const _Signals({required this.signals});

  final BodySignals signals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = signals.body;
    final source = signals.source;
    final s = body.latest!;
    final band = s.band;
    final colors = band == null
        ? (ring: theme.colorScheme.primary, tint: theme.colorScheme.primary.withValues(alpha: 0.1))
        : _bandColors(band, theme.brightness);

    String avgOf(num? Function(WhoopDay) pick, {int dp = 0, String suffix = ''}) {
      final a = body.average(pick);
      return a == null ? '—' : '${a.toStringAsFixed(dp)}$suffix';
    }

    // A row is shown only when the source actually recorded that metric.
    // Apple Health has no HRV unless a watch or strap writes it, and a row
    // reading "—" tells the user nothing except that we asked.
    final tracked = <_TrackedMetric>[
      if (body.samples((d) => d.hrvMs) > 0)
        _TrackedMetric('HRV', (d) => d.hrvMs, unit: 'ms'),
      if (body.samples((d) => d.restingHr) > 0)
        _TrackedMetric('Resting HR', (d) => d.restingHr, unit: 'bpm'),
      if (source.hasRecoveryAndStrain && body.samples((d) => d.strain) > 0)
        _TrackedMetric('Day strain', (d) => d.strain, decimals: 1),
      if (body.samples((d) => d.sleepHours) > 0)
        _TrackedMetric('Sleep', (d) => d.sleepHours, unit: 'h', decimals: 1),
      if (body.samples((d) => d.steps) > 0)
        _TrackedMetric('Steps', (d) => d.steps),
      if (body.samples((d) => d.exerciseMinutes) > 0)
        _TrackedMetric('Active', (d) => d.exerciseMinutes, unit: 'min'),
    ];

    final metrics = [
      for (final m in tracked)
        _Metric(
          label: m.label,
          value: m.pick(s)?.toDouble(),
          unit: m.unit,
          decimals: m.decimals,
          avg: avgOf(m.pick, dp: m.decimals),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (source.hasRecoveryAndStrain) ...[
              _RecoveryRing(pct: s.recoveryPct, color: colors.ring, band: band),
              const SizedBox(width: 18),
            ],
            Expanded(
              child: Column(
                children: [
                  for (final (i, m) in metrics.indexed) ...[
                    if (i > 0) const SizedBox(height: 11),
                    m,
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration:
              BoxDecoration(color: colors.tint, borderRadius: BorderRadius.circular(12)),
          child: Text(
              source.hasRecoveryAndStrain
                  ? whoopInsight(s)
                  : platformInsight(s, body),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
        ),
        const SizedBox(height: 16),
        Text('${signals.windowDays}-day averages · ${source.label}',
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (source.hasRecoveryAndStrain) ...[
              _AvgChip(
                  label: 'Recovery',
                  value: avgOf((d) => d.recoveryPct, suffix: '%')),
              _AvgChip(label: 'Strain', value: avgOf((d) => d.strain, dp: 1)),
            ],
            _AvgChip(label: 'HRV', value: avgOf((d) => d.hrvMs, suffix: ' ms')),
            _AvgChip(label: 'Rest HR', value: avgOf((d) => d.restingHr, suffix: ' bpm')),
            _AvgChip(label: 'Sleep', value: avgOf((d) => d.sleepHours, dp: 1, suffix: ' h')),
            if (body.samples((d) => d.steps) > 0)
              _AvgChip(label: 'Steps', value: avgOf((d) => d.steps)),
            if (body.samples((d) => d.exerciseMinutes) > 0)
              _AvgChip(
                  label: 'Active',
                  value: avgOf((d) => d.exerciseMinutes, suffix: ' min')),
            if (body.samples((d) => d.respiratoryRate) > 0)
              _AvgChip(
                  label: 'Resp',
                  value: avgOf((d) => d.respiratoryRate, dp: 1, suffix: '/min')),
            if (body.samples((d) => d.spo2Pct) > 0)
              _AvgChip(label: 'SpO₂', value: avgOf((d) => d.spo2Pct, suffix: '%')),
            if (body.samples((d) => d.calories) > 0)
              _AvgChip(label: 'Burn', value: avgOf((d) => d.calories, suffix: ' kcal')),
          ],
        ),
        if (tracked.isNotEmpty) ...[
          const SizedBox(height: 18),
          _TrendSection(
            body: body,
            metrics: tracked,
            windowDays: signals.windowDays,
          ),
        ],
        if (source.footnote case final note?) ...[
          const SizedBox(height: 12),
          Text(
            note,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

}

/// The trend chart plus its metric selector. One series at a time — two
/// metrics on one plot would need two y-scales, and a dual-axis chart makes
/// any crossing point look meaningful when it isn't.
class _TrendSection extends StatefulWidget {
  const _TrendSection({
    required this.body,
    required this.metrics,
    required this.windowDays,
  });

  final WhoopBody body;
  final List<_TrackedMetric> metrics;
  final int windowDays;

  @override
  State<_TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends State<_TrendSection> {
  int _selected = 0;

  @override
  void didUpdateWidget(_TrendSection old) {
    super.didUpdateWidget(old);
    // A refresh can change which metrics have data; don't hold an index past
    // the end of the new list.
    if (_selected >= widget.metrics.length) _selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metric = widget.metrics[_selected];

    // Every day in the window gets a slot, so gaps in the source's history
    // render as gaps instead of being silently compressed away.
    final byDay = {
      for (final d in widget.body.days)
        DateTime(d.day.year, d.day.month, d.day.day): d,
    };
    final today = DateTime.now();
    final points = [
      for (var i = widget.windowDays - 1; i >= 0; i--)
        () {
          final day = DateTime(today.year, today.month, today.day)
              .subtract(Duration(days: i));
          return MetricTrendPoint(day, byDay[day] == null
              ? null
              : metric.pick(byDay[day]!)?.toDouble());
        }(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trend',
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (widget.metrics.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, m) in widget.metrics.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m.label),
                      selected: i == _selected,
                      onSelected: (_) => setState(() => _selected = i),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: i == _selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        MetricTrendChart(
          key: ValueKey(metric.label),
          points: points,
          label: metric.label,
          unit: metric.unit.isEmpty ? '' : ' ${metric.unit}',
          decimals: metric.decimals,
        ),
      ],
    );
  }
}

class _RecoveryRing extends StatelessWidget {
  const _RecoveryRing({required this.pct, required this.color, required this.band});

  final int? pct;
  final Color color;
  final RecoveryBand? band;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (pct ?? 0) / 100,
          color: color,
          track: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(pct == null ? '—' : '$pct%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800, height: 1, color: color)),
              const SizedBox(height: 2),
              Text(band?.label ?? 'Recovery',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    required this.avg,
    this.decimals = 0,
  });

  final String label;
  final double? value;
  final String unit;
  final String avg; // preformatted 60-day average
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value;
    final text = v == null
        ? '—'
        : '${v.toStringAsFixed(decimals)}${unit.isEmpty ? '' : ' $unit'}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('avg $avg',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7))),
            ],
          ),
        ),
        Text(text,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AvgChip extends StatelessWidget {
  const _AvgChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value,
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final inset = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(inset, 0, math.pi * 2, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = track);
    canvas.drawArc(
      inset, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
