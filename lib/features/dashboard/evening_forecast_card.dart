import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/forecast_providers.dart';

/// Evening forecast card (spec §3) — shown from 7pm, cites its strongest
/// signal to keep the biometric-intelligence promise concrete.
class EveningForecastCard extends ConsumerWidget {
  const EveningForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(forecastVisibleProvider)) return const SizedBox.shrink();
    final forecast = ref.watch(eveningForecastProvider);
    if (forecast == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.nightlight_round,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Evening forecast',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              Text(forecast.headline, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'The signal I\'m watching: ${forecast.signal}.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
