import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/nutrition_providers.dart';
import '../../domain/nutrition.dart';
import '../../theme/macro_colors.dart';
import '../../theme/pulse_theme.dart';

/// Dashboard "Today's fuel" card — calorie ring (hero magnitude, brand hue)
/// plus protein/fiber/carbs/fat bars, each vs its target. Taps into the
/// nutrition detail screen.
class FuelCard extends ConsumerWidget {
  const FuelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals =
        ref.watch(macroTotalsProvider).value ?? const MacroTotals.zero();
    final targets =
        ref.watch(nutritionTargetsProvider).value ?? const NutritionTargets();

    if (totals.isEmpty) {
      return _EmptyFuelCard(
        theme: theme,
        personalized: targets.source != TargetSource.defaults,
      );
    }

    final calProgress =
        (totals.calories / targets.calories).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/nutrition'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Today's fuel",
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    if (targets.source == TargetSource.derived) ...[
                      const SizedBox(width: 8),
                      const _PersonalizedBadge(),
                    ],
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _CalorieRing(
                      progress: calProgress,
                      consumed: totals.calories,
                      target: targets.calories,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _MacroBar(
                            kind: MacroKind.protein,
                            value: totals.proteinG,
                            target: targets.proteinG,
                            unit: 'g',
                          ),
                          const SizedBox(height: 10),
                          _MacroBar(
                            kind: MacroKind.fiber,
                            value: totals.fiberG,
                            target: targets.fiberG,
                            unit: 'g',
                          ),
                          const SizedBox(height: 10),
                          _MacroBar(
                            kind: MacroKind.carbs,
                            value: totals.carbsG,
                            target: targets.carbsG,
                            unit: 'g',
                          ),
                          const SizedBox(height: 10),
                          _MacroBar(
                            kind: MacroKind.fat,
                            value: totals.fatG,
                            target: targets.fatG,
                            unit: 'g',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _RemainingStrip(
                  remaining: targets.calories - totals.calories,
                  personalized: targets.source != TargetSource.defaults,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The single most actionable number on the card: what's left in the budget.
class _RemainingStrip extends StatelessWidget {
  const _RemainingStrip({required this.remaining, required this.personalized});

  final int remaining;
  final bool personalized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = remaining < 0;
    final color = over ? Colors.orange.shade700 : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(over ? Icons.trending_up : Icons.battery_charging_full,
              size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              over
                  ? '${-remaining} kcal over your target'
                  : '$remaining kcal left today',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (!personalized)
            Text('Add your body →',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _PersonalizedBadge extends StatelessWidget {
  const _PersonalizedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: PulseColors.pulse.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'For you',
        style: theme.textTheme.labelSmall?.copyWith(
          color: PulseColors.pulse,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.progress,
    required this.consumed,
    required this.target,
  });

  final double progress;
  final int consumed;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 108,
      height: 108,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: PulseColors.pulse,
          track: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$consumed',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1),
              ),
              Text(
                'of $target kcal',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.kind,
    required this.value,
    required this.target,
    required this.unit,
  });

  final MacroKind kind;
  final double value;
  final double? target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = MacroColors.of(kind, theme.brightness);
    final fraction =
        target == null || target == 0 ? 0.0 : (value / target!).clamp(0.0, 1.0);
    final over = target != null && value > target!;
    return Semantics(
      label: '${MacroColors.label(kind)} ${value.round()} $unit'
          '${target != null ? ' of ${target!.round()} target' : ''}',
      container: true,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(MacroColors.label(kind),
                style: theme.textTheme.labelSmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 7,
                child: Stack(
                  children: [
                    Container(color: theme.colorScheme.surfaceContainerHighest),
                    FractionallySizedBox(
                      widthFactor: target == null ? 1.0 : fraction,
                      child: Container(
                        color: target == null
                            ? color.withValues(alpha: 0.35)
                            : color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              target == null
                  ? '${value.round()} $unit'
                  : '${value.round()}/${target!.round()}',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: over ? Colors.orange.shade700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFuelCard extends StatelessWidget {
  const _EmptyFuelCard({required this.theme, required this.personalized});

  final ThemeData theme;
  final bool personalized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Snap a meal or log food and today's calories, protein, "
                      'fiber, and more show up here.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              if (!personalized)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/settings/body'),
                    icon: const Icon(Icons.straighten, size: 18),
                    label: const Text('Size these to my body'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final inset = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      inset,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    canvas.drawArc(
      inset,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
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
