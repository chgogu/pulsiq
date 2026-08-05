import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/health_profile_providers.dart';
import '../../domain/health_goal.dart';

/// Pick the goals and conditions that shape the "can I eat this?" verdict on
/// snapped meals and scanned products. Multi-select — several can apply at once.
class HealthGoalsScreen extends ConsumerStatefulWidget {
  const HealthGoalsScreen({super.key});

  @override
  ConsumerState<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends ConsumerState<HealthGoalsScreen> {
  Set<HealthGoal>? _goals;
  final _note = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(saveHealthProfileProvider)(HealthProfile(
      goals: _goals ?? {},
      conditionsNote: _note.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(healthProfileProvider);

    // Seed the local state once from the saved profile.
    if (!_loaded && profile.hasValue) {
      _goals = {...profile.value!.goals};
      _note.text = profile.value!.conditionsNote;
      _loaded = true;
    }
    final goals = _goals ?? {};

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Health goals'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Tell PulsIQ what you\'re working toward. When you snap a meal or '
              'scan a product, it\'ll flag whether it fits.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          for (final g in HealthGoal.values)
            Card(
              child: CheckboxListTile(
                value: goals.contains(g),
                onChanged: (on) {
                  setState(() {
                    if (on == true) {
                      goals.add(g);
                    } else {
                      goals.remove(g);
                    }
                    _goals = {...goals};
                  });
                  _save();
                },
                title: Text(g.label),
                subtitle: Text(g.blurb),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anything else?', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Allergies or conditions not listed — e.g. "gluten '
                    'intolerance", "kidney disease".',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _note,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _save(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'PulsIQ is a wellness companion, not a medical device. Its food '
              'guidance is general and not a substitute for advice from your '
              'doctor or dietitian.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
