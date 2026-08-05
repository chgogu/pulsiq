import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/db/app_database.dart' show FuelQuality;
import '../../data/health_profile_providers.dart';
import '../../data/meal_estimator.dart' show foodDbProvider;
import '../../data/nutrition_providers.dart';
import '../../data/open_food_facts.dart';
import '../../data/food_image_classifier.dart';
import '../../data/providers.dart';
import '../../domain/food_safety.dart';
import 'safety_banner.dart';

/// "Can I eat this?" — a check, not a log. Scan a barcode or snap a photo, get
/// a straight Yes/No against your goals, and only log it if you decide to.
/// Distinct from Snap-a-meal, whose job is to put food *in* the diary.
class CheckFoodScreen extends ConsumerStatefulWidget {
  const CheckFoodScreen({super.key});

  @override
  ConsumerState<CheckFoodScreen> createState() => _CheckFoodScreenState();
}

enum _Phase { intro, scanning, analyzing, result, notFound }

/// The subject of a check, whether it came from a barcode or a photo.
class _Subject {
  const _Subject({
    required this.name,
    required this.caloriesKcal,
    required this.sugarG,
    required this.quality,
    required this.proteinG,
    required this.fiberG,
    required this.carbsG,
    required this.fatG,
    this.saturatedFatG,
    this.sodiumMg,
    this.ingredients,
  });

  final String name;
  final int caloriesKcal;
  final double sugarG;
  final String quality;
  final double proteinG, fiberG, carbsG, fatG;
  final double? saturatedFatG, sodiumMg;
  final String? ingredients;

  FoodSafetyInput toSafetyInput() => FoodSafetyInput(
        name: name,
        caloriesKcal: caloriesKcal,
        sugarG: sugarG,
        saturatedFatG: saturatedFatG,
        sodiumMg: sodiumMg,
        ingredients: ingredients,
      );
}

class _CheckFoodScreenState extends ConsumerState<CheckFoodScreen> {
  _Phase _phase = _Phase.intro;
  _Subject? _subject;
  MobileScannerController? _scanner;
  bool _handled = false;

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  void _startScan() {
    _handled = false;
    _scanner = MobileScannerController(formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ]);
    setState(() => _phase = _Phase.scanning);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    _handled = true;
    await _scanner?.stop();
    setState(() => _phase = _Phase.analyzing);
    final found = await ref.read(openFoodFactsProvider).lookup(code);
    if (!mounted) return;
    if (found == null) {
      setState(() => _phase = _Phase.notFound);
      return;
    }
    final m = found.macros;
    setState(() {
      _subject = _Subject(
        name: found.label,
        caloriesKcal: m.caloriesKcal,
        sugarG: m.sugarG,
        quality: m.quality,
        proteinG: m.proteinG,
        fiberG: m.fiberG,
        carbsG: m.carbsG,
        fatG: m.fatG,
        saturatedFatG: found.saturatedFatG,
        sodiumMg: found.sodiumMg,
        ingredients: found.ingredients,
      );
      _phase = _Phase.result;
    });
  }

  Future<void> _snap(ImageSource source) async {
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    setState(() => _phase = _Phase.analyzing);
    final db = await ref.read(foodDbProvider);
    final local =
        await ref.read(foodImageClassifierProvider).classify(file.path, db);
    if (!mounted) return;
    if (local == null || local.items.isEmpty) {
      setState(() => _phase = _Phase.notFound);
      return;
    }
    final it = local.items;
    setState(() {
      _subject = _Subject(
        name: it.map((i) => i.name).join(', '),
        caloriesKcal: it.fold(0, (s, i) => s + i.caloriesKcal),
        sugarG: it.fold(0.0, (s, i) => s + i.sugarG),
        quality: it.first.qualityScore,
        proteinG: it.fold(0.0, (s, i) => s + i.proteinG),
        fiberG: it.fold(0.0, (s, i) => s + i.fiberG),
        carbsG: it.fold(0.0, (s, i) => s + i.carbsG),
        fatG: it.fold(0.0, (s, i) => s + i.fatG),
      );
      _phase = _Phase.result;
    });
  }

  Future<void> _logIt() async {
    final s = _subject!;
    await ref.read(logRepositoryProvider).addFood(
          name: s.name,
          quantity: '1 serving',
          quality: FuelQuality.values.byName(s.quality),
          caloriesKcal: s.caloriesKcal,
          proteinG: s.proteinG,
          fiberG: s.fiberG,
          carbsG: s.carbsG,
          fatG: s.fatG,
          sugarG: s.sugarG,
          source: 'check',
        );
    ref.invalidate(macroHistoryProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Logged ${s.name}.')));
      Navigator.of(context).maybePop();
    }
  }

  void _reset() {
    setState(() {
      _subject = null;
      _phase = _Phase.intro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(healthProfileProvider).value?.goals ?? const {};
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Can I eat this?'),
        backgroundColor: Colors.transparent,
      ),
      body: goals.isEmpty
          ? const _NoGoals()
          : switch (_phase) {
              _Phase.intro => _Intro(onScan: _startScan, onSnap: _snap),
              _Phase.scanning => _Scanner(
                  controller: _scanner!, onDetect: _onDetect),
              _Phase.analyzing => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking…'),
                    ],
                  ),
                ),
              _Phase.notFound => _NotFound(onRetry: _reset),
              _Phase.result => _Result(
                  subject: _subject!,
                  verdict: assessFood(_subject!.toSafetyInput(), goals),
                  onLog: _logIt,
                  onAgain: _reset,
                ),
            },
    );
  }
}

class _NoGoals extends StatelessWidget {
  const _NoGoals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Set a goal first', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'A yes/no needs to know what you\'re working toward — weight, '
              'diabetes, pregnancy, heart health.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/settings/goals'),
              child: const Text('Set health goals'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onScan, required this.onSnap});

  final VoidCallback onScan;
  final void Function(ImageSource) onSnap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      children: [
        Icon(Icons.fact_check_outlined,
            size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('Check before you eat',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'Scan a product or snap a dish and get a straight yes or no for your '
          'goals. This won\'t add it to your log — it\'s just a check.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan a barcode'),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => onSnap(ImageSource.camera),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Take a photo'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => onSnap(ImageSource.gallery),
          icon: const Icon(Icons.image_outlined),
          label: const Text('Choose from library'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ],
    );
  }
}

class _Scanner extends StatelessWidget {
  const _Scanner({required this.controller, required this.onDetect});

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: controller, onDetect: onDetect),
        Center(
          child: Container(
            width: 240,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Text('Point at the barcode',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onRetry});

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
            Icon(Icons.search_off,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text("Couldn't identify that", style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Try the barcode instead of a photo, or a clearer shot.',
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

class _Result extends StatelessWidget {
  const _Result({
    required this.subject,
    required this.verdict,
    required this.onLog,
    required this.onAgain,
  });

  final _Subject subject;
  final SafetyVerdict verdict;
  final VoidCallback onLog;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        Text(subject.name,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        // The answer, front and center.
        SafetyBanner(verdict: verdict),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip('${subject.caloriesKcal} kcal'),
            _Chip('${subject.sugarG.round()} g sugar'),
            if (subject.sodiumMg != null)
              _Chip('${subject.sodiumMg!.round()} mg sodium'),
            if (subject.saturatedFatG != null)
              _Chip('${subject.saturatedFatG!.round()} g sat fat'),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onLog,
          icon: const Icon(Icons.add),
          label: const Text('Log it'),
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onAgain,
          icon: const Icon(Icons.refresh),
          label: const Text('Check another'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: theme.textTheme.labelMedium),
    );
  }
}
