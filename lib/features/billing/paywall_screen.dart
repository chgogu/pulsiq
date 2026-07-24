import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/subscription_service.dart';
import '../../theme/pulse_theme.dart';
import '../../widgets/pulsiq_mark.dart';

/// PulsIQ Plus paywall. Free is genuinely useful (on-device AI, all health
/// integrations, all analytics); Plus adds the cloud model for sharper
/// estimates and photo snap-a-meal, whose small per-call cost it funds.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.watch(subscriptionServiceProvider);
    final isPlus = ref.watch(isPlusProvider);

    // Dismiss automatically once the entitlement lands.
    ref.listen(isPlusProvider, (_, now) {
      if (now && context.mounted) Navigator.of(context).maybePop();
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('PulsIQ Plus'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          const Center(child: PulsIQMark(size: 64)),
          const SizedBox(height: 16),
          Text(
            'Sharper meal AI, for the price of a coffee refill.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
          ),
          const SizedBox(height: 24),
          _Feature(
            icon: Icons.camera_alt_outlined,
            title: 'Snap a photo, get the meal read for you',
            body: 'Point at your plate — the cloud model identifies every food '
                'and its nutrition. Free logging is on-device and text-based.',
          ),
          _Feature(
            icon: Icons.auto_awesome_outlined,
            title: 'Sharper estimates for any cuisine',
            body: 'Best-in-class accuracy for the dishes a compact on-device '
                'model is less sure about.',
          ),
          _Feature(
            icon: Icons.lock_outline,
            title: 'Everything else stays free',
            body: 'Voice and typed logging, Apple Health and WHOOP, and all '
                'your analytics work without Plus.',
          ),
          const SizedBox(height: 24),
          if (isPlus)
            Card(
              color: theme.colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text("You're on PulsIQ Plus — thank you!",
                    textAlign: TextAlign.center),
              ),
            )
          else ...[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PulseColors.pulse,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _busy || service.product == null ? null : _buy,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Get Plus — ${service.priceLabel}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                service.product == null
                    ? 'Loading subscription…'
                    : 'Auto-renews monthly. Cancel anytime in Settings.',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _restore,
              child: const Text('Restore purchase'),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Payment is charged to your Apple ID. See the Privacy Policy at '
              'pulsiqapp.com and Apple\'s standard subscription terms.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    final ok = await ref.read(subscriptionServiceProvider).buy();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Couldn\'t start the purchase. Try again in a moment.'),
        ));
    }
    // Success arrives on the purchase stream → isPlusProvider → auto-dismiss.
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    await ref.read(subscriptionServiceProvider).restore();
    if (mounted) setState(() => _busy = false);
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
