import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/db/app_database.dart' show FuelQuality;
import '../../data/open_food_facts.dart';
import '../../data/nutrition_providers.dart';
import '../../data/providers.dart';

/// Scan a packaged food's barcode → Open Food Facts → macros, saved as a food
/// entry. On-device scan + a free key-less lookup: $0, no proxy, no model.
class ScanBarcodeScreen extends ConsumerStatefulWidget {
  const ScanBarcodeScreen({super.key});

  @override
  ConsumerState<ScanBarcodeScreen> createState() => _ScanBarcodeScreenState();
}

enum _Phase { scanning, lookup, found, notFound }

class _ScanBarcodeScreenState extends ConsumerState<ScanBarcodeScreen> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  _Phase _phase = _Phase.scanning;
  bool _handled = false;
  String? _code;
  ScannedFood? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;
    _handled = true;
    await _controller.stop();
    setState(() {
      _code = code;
      _phase = _Phase.lookup;
    });
    final found = await ref.read(openFoodFactsProvider).lookup(code);
    if (!mounted) return;
    setState(() {
      _result = found;
      _phase = found == null ? _Phase.notFound : _Phase.found;
    });
  }

  Future<void> _save() async {
    final r = _result!;
    await ref.read(logRepositoryProvider).addFood(
          name: r.label,
          quantity: '1 serving',
          quality: FuelQuality.values.byName(r.macros.quality),
          caloriesKcal: r.macros.caloriesKcal,
          proteinG: r.macros.proteinG,
          fiberG: r.macros.fiberG,
          carbsG: r.macros.carbsG,
          fatG: r.macros.fatG,
          source: 'barcode',
        );
    ref.invalidate(macroHistoryProvider);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _rescan() async {
    setState(() {
      _handled = false;
      _phase = _Phase.scanning;
      _result = null;
      _code = null;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan barcode'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ReticleOverlay(),
          if (_phase != _Phase.scanning)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ResultPanel(
                phase: _phase,
                result: _result,
                code: _code,
                onSave: _save,
                onRescan: _rescan,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReticleOverlay extends StatelessWidget {
  const _ReticleOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Line up the barcode',
                  style: TextStyle(color: Colors.white70)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.phase,
    required this.result,
    required this.code,
    required this.onSave,
    required this.onRescan,
  });

  final _Phase phase;
  final ScannedFood? result;
  final String? code;
  final VoidCallback onSave;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: switch (phase) {
        _Phase.lookup => Row(
            children: [
              const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 14),
              Text('Looking up $code…', style: theme.textTheme.bodyMedium),
            ],
          ),
        _Phase.notFound => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Not in the database',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Barcode $code isn\'t in Open Food Facts. Scan another, or add '
                'it by name from the log sheet.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRescan, child: const Text('Scan again')),
            ],
          ),
        _ => _FoundBody(result: result!, onSave: onSave, onRescan: onRescan),
      },
    );
  }
}

class _FoundBody extends StatelessWidget {
  const _FoundBody({required this.result, required this.onSave, required this.onRescan});

  final ScannedFood result;
  final VoidCallback onSave;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = result.macros;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(result.label,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('per serving', style: theme.textTheme.labelSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip('${m.caloriesKcal} kcal'),
            _Chip('${m.proteinG.round()}g protein'),
            _Chip('${m.carbsG.round()}g carbs'),
            _Chip('${m.fatG.round()}g fat'),
            _Chip('${m.fiberG.round()}g fiber'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: onRescan, child: const Text('Scan again')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                  onPressed: onSave, child: const Text('Add to log')),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}
