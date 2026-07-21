import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/pulse_wave.dart';
import 'walk_controller.dart';

/// Active post-meal walk card (spec §2 item 4) — shown on the dashboard
/// only while a walk is running.
class WalkTimerCard extends ConsumerWidget {
  const WalkTimerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walk = ref.watch(walkControllerProvider);
    if (!walk.active) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final remaining = walk.remainingSeconds;
    final mm = (remaining ~/ 60).toString();
    final ss = (remaining % 60).toString().padLeft(2, '0');

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
                  Icon(Icons.directions_walk,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Post-meal walk', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text('$mm:$ss left',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: walk.progress,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              const PulseWave(height: 28),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        ref.read(walkControllerProvider.notifier).cancel(),
                    child: const Text('Stop'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () =>
                        ref.read(walkControllerProvider.notifier).complete(),
                    child: const Text('Done early'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
