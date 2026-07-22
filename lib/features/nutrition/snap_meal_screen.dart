import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/db/app_database.dart';
import '../../data/food_image_classifier.dart';
import '../../data/meal_estimator.dart' show foodDbProvider;
import '../../data/nutrition_providers.dart';
import '../../data/providers.dart';
import '../../domain/meal_vision.dart';
import '../../voice/voice_pipeline.dart';

/// Snap-a-meal: photo (+ optional hint) → Claude vision on the proxy →
/// editable per-item nutrition → confirm → food entries with macros.
class SnapMealScreen extends ConsumerStatefulWidget {
  const SnapMealScreen({super.key});

  @override
  ConsumerState<SnapMealScreen> createState() => _SnapMealScreenState();
}

enum _Phase { intro, analyzing, review, error }

class _SnapMealScreenState extends ConsumerState<SnapMealScreen> {
  _Phase _phase = _Phase.intro;
  final _hint = TextEditingController();
  List<MealItem> _items = [];
  String _note = '';
  bool _lowConfidence = false;
  bool _onDevice = false; // identified locally (free) — offer AI re-analyze
  String? _pendingImage; // base64 kept so the review can escalate to Gemini

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    setState(() => _phase = _Phase.analyzing);
    final bytes = await file.readAsBytes();
    final image = base64Encode(bytes);

    // C4: on-device first pass. A confident single food (banana, pizza slice)
    // resolves free; anything the labeler can't name escalates to Gemini.
    if (_hint.text.trim().isEmpty) {
      final db = await ref.read(foodDbProvider);
      final local =
          await ref.read(foodImageClassifierProvider).classify(file.path, db);
      if (local != null && mounted) {
        setState(() {
          _items = local.items;
          _note = local.note;
          _lowConfidence = false;
          _onDevice = true;
          _pendingImage = image;
          _phase = _Phase.review;
        });
        return;
      }
    }
    await _analyze(image);
  }

  Future<void> _analyzeHintOnly() async {
    if (_hint.text.trim().isEmpty) return;
    setState(() => _phase = _Phase.analyzing);
    await _analyze('');
  }

  Future<void> _analyze(String base64Image) async {
    setState(() => _phase = _Phase.analyzing);
    final raw = await ref
        .read(llmCoachProvider)
        .analyzeMeal(base64Image: base64Image, hint: _hint.text.trim());
    if (raw == null) {
      setState(() => _phase = _Phase.error);
      return;
    }
    try {
      final result = parseMealVision(raw);
      setState(() {
        _items = result.items;
        _note = result.note;
        _lowConfidence = result.lowConfidence;
        _onDevice = false;
        _phase = _Phase.review;
      });
    } catch (_) {
      setState(() => _phase = _Phase.error);
    }
  }

  Future<void> _confirm() async {
    final repo = ref.read(logRepositoryProvider);
    for (final item in _items) {
      await repo.addFood(
        name: item.name,
        quantity: item.portion,
        quality: FuelQuality.values.byName(item.qualityScore),
        caloriesKcal: item.caloriesKcal,
        proteinG: item.proteinG,
        fiberG: item.fiberG,
        carbsG: item.carbsG,
        fatG: item.fatG,
        source: 'photo',
      );
    }
    ref.invalidate(macroHistoryProvider);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Snap a meal'),
        backgroundColor: Colors.transparent,
      ),
      body: switch (_phase) {
        _Phase.analyzing => const _Busy(),
        _Phase.review => _Review(
            items: _items,
            note: _note,
            lowConfidence: _lowConfidence,
            onDevice: _onDevice,
            onReanalyze: _onDevice && _pendingImage != null
                ? () => _analyze(_pendingImage!)
                : null,
            onChanged: (i, item) => setState(() => _items[i] = item),
            onRemove: (i) => setState(() => _items.removeAt(i)),
            onConfirm: _items.isEmpty ? null : _confirm,
          ),
        _Phase.error => _ErrorView(onRetry: () {
            setState(() => _phase = _Phase.intro);
          }),
        _Phase.intro => _Intro(
            hint: _hint,
            onCamera: () => _pick(ImageSource.camera),
            onGallery: () => _pick(ImageSource.gallery),
            onHintOnly: _analyzeHintOnly,
          ),
      },
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.hint,
    required this.onCamera,
    required this.onGallery,
    required this.onHintOnly,
  });

  final TextEditingController hint;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onHintOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
      children: [
        Icon(Icons.restaurant, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('Photograph your plate', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'PulsIQ reads the photo and estimates calories, protein, fiber, '
          'carbs, and fat for each item. You can fix anything before it '
          'saves.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onCamera,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Take a photo'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Pick from gallery'),
        ),
        const SizedBox(height: 24),
        Text('Add a hint (helps accuracy)',
            style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: hint,
          decoration: const InputDecoration(
            hintText: 'e.g. chicken burrito bowl with guac',
            border: OutlineInputBorder(),
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 8),
          Text(
            'On this web preview, estimates come from your hint (the camera '
            'runs the real vision model on device).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onHintOnly,
            child: const Text('Estimate from hint'),
          ),
        ],
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({
    required this.items,
    required this.note,
    required this.lowConfidence,
    required this.onChanged,
    required this.onRemove,
    required this.onConfirm,
    this.onDevice = false,
    this.onReanalyze,
  });

  final List<MealItem> items;
  final String note;
  final bool lowConfidence;
  final bool onDevice;
  final VoidCallback? onReanalyze;
  final void Function(int, MealItem) onChanged;
  final void Function(int) onRemove;
  final VoidCallback? onConfirm;

  int get _totalCal => items.fold(0, (s, i) => s + i.caloriesKcal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              if (lowConfidence)
                Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "I wasn't fully sure on this one — tap any item "
                            'to correct the estimate before saving.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (onDevice)
                Card(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.offline_bolt_outlined, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Identified on your device — free.',
                              style: theme.textTheme.bodySmall),
                        ),
                        if (onReanalyze != null)
                          TextButton(
                              onPressed: onReanalyze,
                              child: const Text('Re-analyze with AI')),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text('Estimated $_totalCal kcal across ${items.length} '
                  'item${items.length == 1 ? '' : 's'}',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final (i, item) in items.indexed)
                _ItemCard(
                  item: item,
                  onEdit: () async {
                    final edited = await _editItem(context, item);
                    if (edited != null) onChanged(i, edited);
                  },
                  onRemove: () => onRemove(i),
                ),
              if (note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(note,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Add to today'),
            ),
          ),
        ),
      ],
    );
  }

  Future<MealItem?> _editItem(BuildContext context, MealItem item) {
    final name = TextEditingController(text: item.name);
    final cal = TextEditingController(text: '${item.caloriesKcal}');
    final pro = TextEditingController(text: '${item.proteinG.round()}');
    final fib = TextEditingController(text: '${item.fiberG.round()}');
    return showModalBottomSheet<MealItem>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Correct item', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: cal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: pro,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein g'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: fib,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fiber g'),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                item.copyWith(
                  name: name.text.trim().isEmpty ? item.name : name.text.trim(),
                  caloriesKcal: int.tryParse(cal.text) ?? item.caloriesKcal,
                  proteinG: double.tryParse(pro.text) ?? item.proteinG,
                  fiberG: double.tryParse(fib.text) ?? item.fiberG,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(
      {required this.item, required this.onEdit, required this.onRemove});

  final MealItem item;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onEdit,
        title: Text(item.name),
        subtitle: Text(
          '${item.caloriesKcal} kcal · ${item.proteinG.round()}g protein · '
          '${item.fiberG.round()}g fiber · ${item.carbsG.round()}g carbs · '
          '${item.fatG.round()}g fat',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Reading your plate…',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text("Couldn't read that meal",
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Try a clearer photo in good light, or add a hint describing '
              'the dish.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
