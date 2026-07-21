import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/nutrition_providers.dart';
import '../../theme/pulse_theme.dart';

/// 7-day calorie trend — single-series magnitude bars (brand hue), with a
/// recessive target line and direct value labels on each day. No dual axis.
class MacroTrendChart extends ConsumerWidget {
  const MacroTrendChart({super.key, required this.targetCalories});

  final int targetCalories;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(macroHistoryProvider).value;
    if (history == null) {
      return const SizedBox(
          height: 140, child: Center(child: CircularProgressIndicator()));
    }
    final values = [for (final d in history) d.totals.calories];
    final maxVal = [
      targetCalories,
      ...values,
    ].fold(1, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < history.length; i++)
            Expanded(
              child: _Bar(
                value: values[i],
                fraction: values[i] / maxVal,
                targetFraction: targetCalories / maxVal,
                label: _weekdays[history[i].day.weekday - 1],
                isToday: i == history.length - 1,
                color: PulseColors.pulse,
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.fraction,
    required this.targetFraction,
    required this.label,
    required this.isToday,
    required this.color,
    required this.theme,
  });

  final int value;
  final double fraction;
  final double targetFraction;
  final String label;
  final bool isToday;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value calories',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            SizedBox(
              height: 12,
              child: value > 0
                  ? Text(
                      value >= 1000
                          ? '${(value / 1000).toStringAsFixed(1)}k'
                          : '$value',
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant),
                    )
                  : null,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // recessive target line
                      Positioned(
                        bottom: (targetFraction.clamp(0.0, 1.0)) * h,
                        left: 0,
                        right: 0,
                        child: Container(
                            height: 1.5,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.35)),
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        child: Container(
                          height: (fraction.clamp(0.0, 1.0)) * h,
                          decoration: BoxDecoration(
                            color: isToday
                                ? color
                                : color.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight:
                        isToday ? FontWeight.w800 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
