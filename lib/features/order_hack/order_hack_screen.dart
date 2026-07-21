import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/menu_hack.dart';
import '../../voice/voice_pipeline.dart';
import 'ocr_service.dart';

class OrderHackScreen extends ConsumerStatefulWidget {
  const OrderHackScreen({super.key});

  @override
  ConsumerState<OrderHackScreen> createState() => _OrderHackScreenState();
}

enum _Phase { intro, scanning, thinking, results, error }

class _OrderHackScreenState extends ConsumerState<OrderHackScreen> {
  _Phase _phase = _Phase.intro;
  OrderHackResult? _result;
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _fromCamera(ImageSource source) async {
    setState(() => _phase = _Phase.scanning);
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) {
      setState(() => _phase = _Phase.intro);
      return;
    }
    final text = await ref.read(ocrServiceProvider).extractText(file.path);
    if (text.trim().isEmpty) {
      setState(() => _phase = _Phase.error);
      return;
    }
    await _analyze(text);
  }

  Future<void> _analyze(String menuText) async {
    setState(() => _phase = _Phase.thinking);
    final raw = await ref.read(llmCoachProvider).orderHack(menuText);
    if (raw == null) {
      setState(() => _phase = _Phase.error);
      return;
    }
    try {
      final parsed = parseOrderHack(raw);
      setState(() {
        _result = parsed;
        _phase = _Phase.results;
      });
    } catch (_) {
      setState(() => _phase = _Phase.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Order Hack'),
        backgroundColor: Colors.transparent,
      ),
      body: switch (_phase) {
        _Phase.thinking => const _Busy(label: 'Reading the menu…'),
        _Phase.scanning => const _Busy(label: 'Scanning…'),
        _Phase.results => _Results(
            result: _result!,
            onReset: () => setState(() => _phase = _Phase.intro),
          ),
        _Phase.error => _ErrorView(onRetry: () => setState(() {
              _phase = _Phase.intro;
            })),
        _Phase.intro => _Intro(
            manual: _manual,
            onCamera: () => _fromCamera(ImageSource.camera),
            onGallery: () => _fromCamera(ImageSource.gallery),
            onManual: () {
              if (_manual.text.trim().isNotEmpty) _analyze(_manual.text);
            },
          ),
      },
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    required this.manual,
    required this.onCamera,
    required this.onGallery,
    required this.onManual,
  });

  final TextEditingController manual;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
      children: [
        Icon(Icons.restaurant_menu,
            size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('Point it at a menu', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'PulsIQ reads it and hands you the top 3 picks for long, steady '
          'energy — with a one-line why for each.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        if (!kIsWeb) ...[
          FilledButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Scan with camera'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pick a photo'),
          ),
          const SizedBox(height: 20),
          Text('Or paste menu text',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
        ] else
          Text('Paste menu text (camera + OCR run on device)',
              style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: manual,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Grilled salmon bowl, cheeseburger, caesar salad, '
                'fried chicken sandwich…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onManual,
          child: const Text('Hack this menu'),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.onReset});

  final OrderHackResult result;
  final VoidCallback onReset;

  static const _ratingColors = {
    'steady': Colors.green,
    'moderate': Colors.orange,
    'spike': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(result.headline, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        for (final (i, pick) in result.picks.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pick.name,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(pick.why,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (_ratingColors[pick.energyRating] ??
                                    Colors.grey)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            switch (pick.energyRating) {
                              'steady' => 'Steady energy',
                              'moderate' => 'Moderate',
                              _ => 'Energy spike',
                            },
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: _ratingColors[pick.energyRating]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Scan another'),
        ),
      ],
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
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
            Icon(Icons.no_meals_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text("Couldn't read that menu",
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Try a clearer photo, better light, or paste the text '
              'directly.',
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
