// `show Value` only — drift's top-level Column/Table would collide with
// Flutter's.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/app_database.dart';
import '../../data/log_repository.dart';
import '../../data/meal_estimator.dart';
import '../../data/providers.dart';
import '../../domain/sweetness.dart';
import '../../services/notification_service.dart';

Future<void> showEntrySheet(BuildContext context, {LogItem? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SingleChildScrollView(child: EntrySheet(existing: existing)),
    ),
  );
}

class EntrySheet extends ConsumerStatefulWidget {
  const EntrySheet({super.key, this.existing});

  final LogItem? existing;

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  late LogKind _kind = widget.existing?.kind ?? LogKind.food;

  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _volume = TextEditingController();
  final _sugar = TextEditingController();
  final _amount = TextEditingController(text: '250');
  final _activity = TextEditingController();
  final _minutes = TextEditingController();

  FuelQuality _quality = FuelQuality.clean;
  BeverageType _beverageType = BeverageType.water;
  ExerciseIntensity _intensity = ExerciseIntensity.moderate;
  String? _sweetnessHack;

  bool _estimating = false;
  // Full estimate from the last "Estimate" tap — carries fiber/carbs/fat,
  // which have no visible fields, through to the save.
  MealEstimate? _estimate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing?.entity;
    switch (e) {
      case FoodEntry():
        _name.text = e.name;
        _quantity.text = e.quantity;
        _quality = e.qualityScore;
        _calories.text = e.caloriesKcal?.toString() ?? '';
        _protein.text = e.proteinG?.round().toString() ?? '';
      case BeverageEntry():
        _name.text = e.name;
        _volume.text = '${e.volumeMl}';
        _sugar.text = e.sugarContentG == 0 ? '' : '${e.sugarContentG}';
        _beverageType = e.type;
      case HydrationEntry():
        _amount.text = '${e.amountMl}';
      case ExerciseEntry():
        _activity.text = e.activity;
        _minutes.text = '${e.durationMinutes}';
        _intensity = e.intensity;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _quantity, _calories, _protein, _volume, _sugar, _amount,
      _activity, _minutes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => switch (_kind) {
        LogKind.food => _name.text.trim().isNotEmpty,
        LogKind.beverage => _name.text.trim().isNotEmpty,
        LogKind.hydration => (int.tryParse(_amount.text) ?? 0) > 0,
        LogKind.exercise => _activity.text.trim().isNotEmpty &&
            (int.tryParse(_minutes.text) ?? 0) > 0,
      };

  Future<void> _save() async {
    final repo = ref.read(logRepositoryProvider);
    final existing = widget.existing;
    if (existing == null) {
      switch (_kind) {
        case LogKind.food:
          await _saveFood(repo);
        case LogKind.beverage:
          final sugar = double.tryParse(_sugar.text) ?? 0;
          await repo.addBeverage(
            name: _name.text.trim(),
            volumeMl: int.tryParse(_volume.text) ?? 0,
            sugarContentG: sugar,
            type: _beverageType,
          );
          if (_beverageType == BeverageType.caffeine) {
            await ref.read(reminderSchedulerProvider).onCaffeineLogged();
          }
          _sweetnessHack = sweetnessHack(_name.text.trim(), sugar);
        case LogKind.hydration:
          await repo.addHydration(amountMl: int.parse(_amount.text));
        case LogKind.exercise:
          await repo.addExercise(
            activity: _activity.text.trim(),
            durationMinutes: int.parse(_minutes.text),
            intensity: _intensity,
          );
      }
    } else {
      switch (existing.entity) {
        case final FoodEntry e:
          await repo.updateFood(e.copyWith(
            name: _name.text.trim(),
            quantity: _quantity.text.trim(),
            qualityScore: _quality,
            caloriesKcal: Value(int.tryParse(_calories.text.trim())),
            proteinG: Value(double.tryParse(_protein.text.trim())),
          ));
        case final BeverageEntry e:
          await repo.updateBeverage(e.copyWith(
            name: _name.text.trim(),
            volumeMl: int.tryParse(_volume.text) ?? e.volumeMl,
            sugarContentG: double.tryParse(_sugar.text) ?? e.sugarContentG,
            type: _beverageType,
          ));
        case final HydrationEntry e:
          await repo.updateHydration(
              e.copyWith(amountMl: int.parse(_amount.text)));
        case final ExerciseEntry e:
          await repo.updateExercise(e.copyWith(
            activity: _activity.text.trim(),
            durationMinutes: int.parse(_minutes.text),
            intensity: _intensity,
          ));
      }
    }
    if (!mounted) return;
    final hack = _sweetnessHack;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    if (hack != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(hack), duration: const Duration(seconds: 5)));
    } else if (_autoEstimateStarted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Estimating calories from your description…'),
        ));
    }
  }

  /// A new food entry. Numbers come from, in order: what the user typed, a
  /// prior "Estimate" tap, or — if calories are still blank — a background
  /// estimate that patches the row moments after it's saved. Logging is never
  /// blocked on the network: the row lands immediately either way.
  String get _foodDescription =>
      [_name.text.trim(), _quantity.text.trim()].where((s) => s.isNotEmpty).join(', ');

  Future<void> _saveFood(LogRepository repo) async {
    final manualCal = int.tryParse(_calories.text.trim());
    final manualPro = double.tryParse(_protein.text.trim());
    final est = _estimate;

    if (manualCal != null) {
      // A number is present (typed, or filled by the Estimate button). Keep
      // any fiber/carbs/fat from the estimate so those macros aren't lost.
      await repo.addFood(
        name: _name.text.trim(),
        quantity: _quantity.text.trim(),
        quality: _quality,
        caloriesKcal: manualCal,
        proteinG: manualPro ?? est?.proteinG,
        fiberG: est?.fiberG,
        carbsG: est?.carbsG,
        fatG: est?.fatG,
      );
      return;
    }

    // No number yet: save now, estimate in the background, patch when it
    // lands. Runs through the provider so it survives this sheet closing.
    final id = await repo.addFood(
      name: _name.text.trim(),
      quantity: _quantity.text.trim(),
      quality: _quality,
    );
    final description = _foodDescription;
    ref.read(mealEstimatorProvider).estimateAndPatch(id, description);
    _autoEstimateStarted = true;
  }

  bool _autoEstimateStarted = false;

  Future<void> _runEstimate() async {
    final description = _foodDescription;
    if (description.isEmpty) return;
    setState(() => _estimating = true);
    final est = await ref.read(mealEstimatorProvider).estimate(description);
    if (!mounted) return;
    setState(() {
      _estimating = false;
      if (est != null) {
        _estimate = est;
        _calories.text = '${est.caloriesKcal}';
        _protein.text = '${est.proteinG.round()}';
        _quality = est.quality;
      }
    });
    if (est == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text(
              "Couldn't estimate that one — type the calories, or use Snap "
              'a meal for a photo estimate.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.existing != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editing ? 'Edit entry' : 'Log something',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            if (!editing) ...[
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).maybePop();
                  context.push('/snap-meal');
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Snap a meal — auto calories & macros'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46)),
              ),
              const SizedBox(height: 12),
            ],
            if (!editing)
              SegmentedButton<LogKind>(
                segments: const [
                  ButtonSegment(
                      value: LogKind.food,
                      label: Text('Food'),
                      icon: Icon(Icons.restaurant_outlined)),
                  ButtonSegment(
                      value: LogKind.beverage,
                      label: Text('Drink'),
                      icon: Icon(Icons.local_cafe_outlined)),
                  ButtonSegment(
                      value: LogKind.hydration,
                      label: Text('Water'),
                      icon: Icon(Icons.water_drop_outlined)),
                  ButtonSegment(
                      value: LogKind.exercise,
                      label: Text('Move'),
                      icon: Icon(Icons.directions_walk)),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
            const SizedBox(height: 16),
            ..._fieldsFor(_kind),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _valid ? _save : null,
              child: Text(editing ? 'Save changes' : 'Add to log'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fieldsFor(LogKind kind) {
    switch (kind) {
      case LogKind.food:
        return [
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'What did you eat?'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            decoration:
                const InputDecoration(labelText: 'Quantity (optional)'),
          ),
          const SizedBox(height: 12),
          // The automatic path: type the dish, let the model do the numbers.
          // Leaving these fields blank and saving triggers the same estimate
          // in the background, so this button is a preview, not a gate.
          OutlinedButton.icon(
            onPressed: _estimating || _name.text.trim().isEmpty
                ? null
                : _runEstimate,
            icon: _estimating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_estimating
                ? 'Estimating…'
                : 'Estimate calories from description'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
          ),
          const SizedBox(height: 12),
          // Hand-editable, and auto-filled by the button above. Blank is fine
          // — saving estimates in the background rather than logging zeros.
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Calories', hintText: 'auto'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Protein (g)', hintText: 'auto'),
                ),
              ),
            ],
          ),
          if (_estimate != null && !_estimating) ...[
            const SizedBox(height: 8),
            _EstimateSummary(estimate: _estimate!),
          ],
          const SizedBox(height: 12),
          SegmentedButton<FuelQuality>(
            segments: const [
              ButtonSegment(value: FuelQuality.clean, label: Text('Clean')),
              ButtonSegment(
                  value: FuelQuality.moderate, label: Text('Moderate')),
              ButtonSegment(value: FuelQuality.dense, label: Text('Dense')),
            ],
            selected: {_quality},
            onSelectionChanged: (s) => setState(() => _quality = s.first),
          ),
        ];
      case LogKind.beverage:
        return [
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Drink name'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _volume,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Volume (ml)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sugar,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Sugar (g)'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SegmentedButton<BeverageType>(
            segments: const [
              ButtonSegment(value: BeverageType.water, label: Text('Water')),
              ButtonSegment(
                  value: BeverageType.caffeine, label: Text('Caffeine')),
              ButtonSegment(
                  value: BeverageType.alcohol, label: Text('Alcohol')),
              ButtonSegment(
                  value: BeverageType.protein, label: Text('Protein')),
            ],
            selected: {_beverageType},
            onSelectionChanged: (s) =>
                setState(() => _beverageType = s.first),
          ),
        ];
      case LogKind.hydration:
        return [
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Amount (ml)'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final ml in [250, 500, 750])
                ActionChip(
                  label: Text('$ml ml'),
                  onPressed: () => setState(() => _amount.text = '$ml'),
                ),
            ],
          ),
        ];
      case LogKind.exercise:
        return [
          TextField(
            controller: _activity,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Activity'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Minutes'),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ExerciseIntensity>(
            segments: const [
              ButtonSegment(value: ExerciseIntensity.low, label: Text('Low')),
              ButtonSegment(
                  value: ExerciseIntensity.moderate, label: Text('Moderate')),
              ButtonSegment(
                  value: ExerciseIntensity.vigorous, label: Text('Vigorous')),
            ],
            selected: {_intensity},
            onSelectionChanged: (s) => setState(() => _intensity = s.first),
          ),
        ];
    }
  }
}

/// The macros an estimate resolved to, shown under the fields so the user can
/// sanity-check the number before saving.
class _EstimateSummary extends StatelessWidget {
  const _EstimateSummary({required this.estimate});

  final MealEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = estimate;
    final parts = [
      'Fiber ${e.fiberG.round()}g',
      'Carbs ${e.carbsG.round()}g',
      'Fat ${e.fatG.round()}g',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated across ${e.itemCount} '
            '${e.itemCount == 1 ? 'item' : 'items'} · ${parts.join(' · ')}',
            style: theme.textTheme.bodySmall,
          ),
          if (e.lowConfidence) ...[
            const SizedBox(height: 4),
            Text(
              'Low confidence — worth a quick check or a photo.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
