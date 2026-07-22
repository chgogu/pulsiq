import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/whoop.dart';
import '../../health/whoop/whoop_client.dart';
import '../../health/whoop/whoop_providers.dart';

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

/// Dashboard "Body signals" card: recovery, HRV, resting HR, strain, sleep and
/// more from the connected wearable, each with its 60-day average. Hidden
/// until a wearable is linked. (Deliberately not branded "WHOOP" — it's the
/// user's body data, whatever the source.)
class WhoopCard extends ConsumerWidget {
  const WhoopCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(whoopBodyProvider);
    return async.when(
      loading: () => const _Shell(child: _Loading()),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        if (result == null) return const SizedBox.shrink(); // not linked
        return switch (result.status) {
          WhoopFetchStatus.ok => _Shell(
              onRefresh: () => ref.invalidate(whoopBodyProvider),
              child: _Signals(body: result.body!),
            ),
          WhoopFetchStatus.empty => const _Shell(
              child: _Note(
                icon: Icons.hourglass_empty,
                text: 'Connected — waiting for your next sync. Recovery and '
                    'sleep appear after your next logged night.',
              ),
            ),
          WhoopFetchStatus.noAccess => _Shell(
              child: _Note(
                icon: Icons.link_off,
                text: 'Your wearable session expired. Reconnect in Settings to '
                    'keep your signals flowing in.',
                action: ('Settings', () => context.push('/settings')),
              ),
            ),
          WhoopFetchStatus.error => _Shell(
              onRefresh: () => ref.invalidate(whoopBodyProvider),
              child: const _Note(
                icon: Icons.cloud_off,
                text: "Couldn't reach your wearable's data. Check the analysis "
                    'server is running and you\'re on the same Wi-Fi, then retry.',
              ),
            ),
        };
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.onRefresh});

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
                  Text('Body signals',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3)),
                  const Spacer(),
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
          Text('Reading your recovery and history…',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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

class _Signals extends StatelessWidget {
  const _Signals({required this.body});

  final WhoopBody body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = body.latest!;
    final band = s.band;
    final colors = band == null
        ? (ring: theme.colorScheme.primary, tint: theme.colorScheme.primary.withValues(alpha: 0.1))
        : _bandColors(band, theme.brightness);

    String avgOf(num? Function(WhoopDay) pick, {int dp = 0, String suffix = ''}) {
      final a = body.average(pick);
      return a == null ? '—' : '${a.toStringAsFixed(dp)}$suffix';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RecoveryRing(pct: s.recoveryPct, color: colors.ring, band: band),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: [
                  _Metric(
                    label: 'HRV',
                    value: s.hrvMs,
                    unit: 'ms',
                    avg: avgOf((d) => d.hrvMs),
                  ),
                  const SizedBox(height: 11),
                  _Metric(
                    label: 'Resting HR',
                    value: s.restingHr,
                    unit: 'bpm',
                    avg: avgOf((d) => d.restingHr),
                  ),
                  const SizedBox(height: 11),
                  _Metric(
                    label: 'Day strain',
                    value: s.strain,
                    unit: '',
                    decimals: 1,
                    avg: avgOf((d) => d.strain, dp: 1),
                  ),
                  const SizedBox(height: 11),
                  _Metric(
                    label: 'Sleep',
                    value: s.sleepHours,
                    unit: 'h',
                    decimals: 1,
                    avg: avgOf((d) => d.sleepHours, dp: 1),
                  ),
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
          child: Text(whoopInsight(s),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
        ),
        const SizedBox(height: 16),
        Text('60-day averages',
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AvgChip(label: 'Recovery', value: avgOf((d) => d.recoveryPct, suffix: '%')),
            _AvgChip(label: 'HRV', value: avgOf((d) => d.hrvMs, suffix: ' ms')),
            _AvgChip(label: 'Rest HR', value: avgOf((d) => d.restingHr, suffix: ' bpm')),
            _AvgChip(label: 'Strain', value: avgOf((d) => d.strain, dp: 1)),
            _AvgChip(label: 'Sleep', value: avgOf((d) => d.sleepHours, dp: 1, suffix: ' h')),
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
        const SizedBox(height: 12),
        Text(
          'Steps show in the WHOOP app but aren\'t in its developer API yet, so '
          'they can\'t sync here — connect Apple Health for step counts.',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text('${_asOf(s.day)} · ${body.scoredRecoveryDays} days of history',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  static String _asOf(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'As of today';
    if (diff == 1) return 'As of yesterday';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (diff < 7) return 'As of ${names[day.weekday - 1]}';
    return 'As of $diff days ago';
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
