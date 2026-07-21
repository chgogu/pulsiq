import 'package:flutter/material.dart';

import '../../domain/pulsiq_score.dart';
import '../../widgets/pulse_wave.dart';

const _componentNames = {
  ScoreComponent.cardiac: 'Cardiac recovery',
  ScoreComponent.sleep: 'Sleep',
  ScoreComponent.fuel: 'Fuel quality',
  ScoreComponent.hydration: 'Hydration',
};

class ScoreHero extends StatelessWidget {
  const ScoreHero({super.key, required this.result});

  final PulsIQScoreResult result;

  String get _statusWord {
    final s = result.score;
    if (s == null) return 'No data yet';
    if (s >= 80) return 'Primed';
    if (s >= 65) return 'Steady';
    if (s >= 50) return 'Building';
    return 'Recharge';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showBreakdown(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'PulsIQ Score',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (result.isFuelOnly) ...[
                    _FuelOnlyChip(theme: theme),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.score ?? '—'}',
                    style: theme.textTheme.displayLarge
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _statusWord,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const PulseWave(height: 44),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _ScoreBreakdownSheet(result: result),
    );
  }
}

class _FuelOnlyChip extends StatelessWidget {
  const _FuelOnlyChip({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Fuel-only',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
      ),
    );
  }
}

class _ScoreBreakdownSheet extends StatelessWidget {
  const _ScoreBreakdownSheet({required this.result});

  final PulsIQScoreResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score breakdown', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              result.isFuelOnly
                  ? 'No wearable data yet — the score is renormalized over '
                      'fuel and hydration only, so it never fakes biometric '
                      'confidence.'
                  : 'Weighted across the signals PulsIQ has today.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final entry in result.componentValues.entries) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _componentNames[entry.key]!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${(result.effectiveWeights[entry.key]! * 100).round()}% '
                    'weight',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: entry.value,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
