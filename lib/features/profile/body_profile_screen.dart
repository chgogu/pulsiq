import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/nutrition_providers.dart';
import '../../data/providers.dart';
import '../../domain/body_profile.dart';
import '../../domain/nutrition.dart';
import '../../theme/macro_colors.dart';
import '../../theme/pulse_theme.dart';

/// Body profile editor. Every control recomputes the fuel numbers live, so
/// the relationship between "what my body is" and "what I should eat" is
/// visible rather than buried in a formula.
class BodyProfileScreen extends ConsumerStatefulWidget {
  const BodyProfileScreen({super.key});

  @override
  ConsumerState<BodyProfileScreen> createState() => _BodyProfileScreenState();
}

class _BodyProfileScreenState extends ConsumerState<BodyProfileScreen> {
  BodyProfile? _draft;

  /// Defaults for a first-time profile — deliberately median, not aspirational.
  static const _blank = BodyProfile(heightCm: 170, weightKg: 70, age: 30);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stored = ref.watch(bodyProfileProvider);
    final profile = _draft ?? stored.value ?? _blank;
    final metric = profile.metric;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Your body'),
        backgroundColor: Colors.transparent,
        actions: [
          // Save lives here rather than in a FAB — the app shell already owns
          // the bottom-right corner with the universal capture button.
          if (_draft != null)
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          _DerivedHero(profile: profile),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Measurements',
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      SegmentedButton<bool>(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        segments: const [
                          ButtonSegment(value: false, label: Text('lb / ft')),
                          ButtonSegment(value: true, label: Text('kg / cm')),
                        ],
                        selected: {metric},
                        onSelectionChanged: (s) =>
                            _update(profile.copyWith(metric: s.first)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SliderRow(
                    label: 'Weight',
                    value: profile.weightKg,
                    min: 35,
                    max: 200,
                    divisions: 330,
                    readout: metric
                        ? '${profile.weightKg.toStringAsFixed(1)} kg'
                        : '${kgToLb(profile.weightKg).round()} lb',
                    onChanged: (v) => _update(profile.copyWith(weightKg: v)),
                  ),
                  _SliderRow(
                    label: 'Height',
                    value: profile.heightCm,
                    min: 140,
                    max: 215,
                    divisions: 75,
                    readout: metric
                        ? '${profile.heightCm.round()} cm'
                        : _feetInches(profile.heightCm),
                    onChanged: (v) => _update(profile.copyWith(heightCm: v)),
                  ),
                  _SliderRow(
                    label: 'Age',
                    value: profile.age.toDouble(),
                    min: 13,
                    max: 100,
                    divisions: 87,
                    readout: '${profile.age}',
                    onChanged: (v) =>
                        _update(profile.copyWith(age: v.round())),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: SizedBox(
                            width: 64,
                            child: Text('Sex',
                                style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              for (final s in BodySex.values)
                                ChoiceChip(
                                  label: Text(s == BodySex.unspecified
                                      ? 'Unspecified'
                                      : s.label),
                                  selected: profile.sex == s,
                                  onSelected: (_) =>
                                      _update(profile.copyWith(sex: s)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Activity',
            child: Column(
              children: [
                for (final level in ActivityLevel.values)
                  _PickRow(
                    title: level.label,
                    subtitle: level.blurb,
                    selected: profile.activity == level,
                    onTap: () => _update(profile.copyWith(activity: level)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Goal',
            child: Column(
              children: [
                for (final goal in FuelGoal.values)
                  _PickRow(
                    title: goal.label,
                    subtitle: goal.blurb,
                    selected: profile.goal == goal,
                    onTap: () => _update(profile.copyWith(goal: goal)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'PulsIQ estimates these from published equations '
              '(Mifflin–St Jeor for resting burn). They are a starting point '
              'for a healthy adult, not medical advice — and you can override '
              'any of them by hand on the Nutrition screen.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _draft == null ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Save profile'),
          ),
        ],
      ),
    );
  }

  void _update(BodyProfile next) => setState(() => _draft = next);

  Future<void> _save() async {
    final profile = _draft;
    if (profile == null) return;
    final db = ref.read(appDatabaseProvider);
    for (final entry in profile.toSettings().entries) {
      await db.setSetting(entry.key, entry.value);
    }
    // Saving a body profile means the user wants derived numbers again.
    await db.setSetting(targetsModeKey, 'auto');
    ref
      ..invalidate(bodyProfileProvider)
      ..invalidate(nutritionTargetsProvider);
    if (!mounted) return;
    setState(() => _draft = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content: Text('Fuel targets now personalized to your body.')));
  }
}

String _feetInches(double cm) {
  final totalInches = cmToInches(cm).round();
  final feet = totalInches ~/ 12;
  final inches = totalInches % 12;
  return "$feet' $inches\"";
}

/// Live readout of everything the profile implies. Sits above the controls so
/// the numbers visibly react as you move them.
class _DerivedHero extends StatelessWidget {
  const _DerivedHero({required this.profile});

  final BodyProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = profile.derivedTargets;
    final (lowKg, highKg) = profile.healthyWeightRangeKg;
    final metric = profile.metric;
    final range = metric
        ? '${lowKg.round()}–${highKg.round()} kg'
        : '${kgToLb(lowKg).round()}–${kgToLb(highKg).round()} lb';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your daily fuel target',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  tween: Tween(
                      begin: targets.calories.toDouble(),
                      end: targets.calories.toDouble()),
                  builder: (_, v, _) => Text(
                    '${v.round()}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: PulseColors.pulse,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('kcal',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MacroChip(
                    kind: MacroKind.protein, grams: targets.proteinG),
                _MacroChip(kind: MacroKind.carbs, grams: targets.carbsG),
                _MacroChip(kind: MacroKind.fat, grams: targets.fatG),
                _MacroChip(kind: MacroKind.fiber, grams: targets.fiberG),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                _Stat(
                    label: 'Resting burn', value: '${profile.bmr.round()}'),
                _Stat(label: 'Daily burn', value: '${profile.tdee.round()}'),
                _Stat(
                    label: 'BMI', value: profile.bmi.toStringAsFixed(1)),
                _Stat(label: 'Water', value: '${profile.baseHydrationMl} ml'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'A BMI band of 18.5–24.9 for your height is $range. '
              'BMI is a population screen, not a verdict on any one body.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.kind, required this.grams});

  final MacroKind kind;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = MacroColors.of(kind, theme.brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text('${MacroColors.label(kind)} ${grams.round()}g',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.readout,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String readout;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $readout',
      container: true,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              readout,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? PulseColors.pulse : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? PulseColors.pulse
                      : theme.colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
