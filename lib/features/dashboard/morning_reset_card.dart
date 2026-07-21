import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../health/health_providers.dart';
import '../walk/walk_controller.dart';

final _resetDoneProvider = FutureProvider<bool>((ref) async {
  final now = DateTime.now();
  final v = await ref
      .watch(appDatabaseProvider)
      .getSetting('morning_reset_done_${now.year}-${now.month}-${now.day}');
  return v == 'true';
});

/// Morning Recovery Reset (spec §3): 3-step checklist shown before 11am
/// after a short night or a hot RHR.
class MorningResetCard extends ConsumerWidget {
  const MorningResetCard({super.key});

  static Future<void> _markDone(WidgetRef ref) async {
    final now = DateTime.now();
    await ref.read(appDatabaseProvider).setSetting(
        'morning_reset_done_${now.year}-${now.month}-${now.day}', 'true');
    ref.invalidate(_resetDoneProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(morningResetDueProvider);
    final done = ref.watch(_resetDoneProvider).value ?? true;
    if (!due || done) return const SizedBox.shrink();

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
                  Icon(Icons.wb_twilight, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Morning recovery reset',
                      style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Dismiss',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _markDone(ref),
                  ),
                ],
              ),
              Text(
                'Rough night on the biometrics — three small moves get the '
                'energy back on track.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _Step(
                icon: Icons.water_drop_outlined,
                text: 'Front-load water (+500 ml on today\'s goal)',
                actionLabel: 'Boost goal',
                onTap: () async {
                  final now = DateTime.now();
                  await ref.read(appDatabaseProvider).setSetting(
                      'goal_boost_${now.year}-${now.month}-${now.day}',
                      '500');
                  ref.invalidate(morningBoostProvider);
                },
              ),
              const _Step(
                icon: Icons.egg_alt_outlined,
                text: 'High-protein breakfast — eggs, yogurt, or a shake '
                    'beat anything sweet this morning.',
              ),
              _Step(
                icon: Icons.directions_walk,
                text: '10 easy minutes of movement wakes the system up.',
                actionLabel: 'Start walk',
                onTap: () async {
                  await ref
                      .read(walkControllerProvider.notifier)
                      .start(targetMinutes: 10, source: 'morning_reset');
                  await _markDone(ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
          if (actionLabel != null)
            TextButton(
              onPressed: () => onTap?.call(),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}
