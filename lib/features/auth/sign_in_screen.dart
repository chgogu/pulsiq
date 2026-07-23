import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_service.dart';
import '../../widgets/pulse_wave.dart';
import '../../widgets/pulsiq_mark.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;

  Future<void> _run(Future<AuthResult> Function() action) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case AuthSuccess():
        context.go('/home');
      case AuthFailure(:final message):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.read(authServiceProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: PulsIQWordmark(fontSize: 36)),
              const SizedBox(height: 8),
              const PulseWave(height: 40),
              const SizedBox(height: 8),
              Text(
                'Sign in to unlock encrypted backup and sync. '
                'No passwords, ever.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(auth.signInWithGoogle),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(auth.signInWithPasskey),
                icon: const Icon(Icons.key_outlined),
                label: const Text('Continue with a passkey'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _busy ? null : () => _run(auth.continueLocally),
                child: const Text('Continue without an account'),
              ),
              Text(
                'Your data stays on this device, encrypted at rest. '
                'You can connect an account later in Settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
