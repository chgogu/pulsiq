import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/log_repository.dart';
import '../../data/providers.dart';
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
  final _volume = TextEditingController();
  final _sugar = TextEditingController();
  final _amount = TextEditingController(text: '250');
  final _activity = TextEditingController();
  final _minutes = TextEditingController();

  FuelQuality _quality = FuelQuality.clean;
  BeverageType _beverageType = BeverageType.water;
  ExerciseIntensity _intensity = ExerciseIntensity.moderate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing?.entity;
    switch (e) {
      case FoodEntry():
        _name.text = e.name;
        _quantity.text = e.quantity;
        _quality = e.qualityScore;
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
      _name, _quantity, _volume, _sugar, _amount, _activity, _minutes,
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
          await repo.addFood(
            name: _name.text.trim(),
            quantity: _quantity.text.trim(),
            quality: _quality,
          );
        case LogKind.beverage:
          await repo.addBeverage(
            name: _name.text.trim(),
            volumeMl: int.tryParse(_volume.text) ?? 0,
            sugarContentG: double.tryParse(_sugar.text) ?? 0,
            type: _beverageType,
          );
          if (_beverageType == BeverageType.caffeine) {
            await ref.read(reminderSchedulerProvider).onCaffeineLogged();
          }
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
    if (mounted) Navigator.of(context).maybePop();
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
