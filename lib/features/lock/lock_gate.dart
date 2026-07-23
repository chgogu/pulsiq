import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../security/app_lock.dart';
import '../../services/notification_service.dart';
import '../../theme/pulse_theme.dart';
import '../../widgets/pulse_wave.dart';

/// Sits above the router (MaterialApp.builder) so the lock covers every
/// screen. Locks on cold start and when returning after >60s in background.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;
  static const _grace = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(
        () => ref.read(appLockProvider.notifier).lockIfPossible());
    // LockGate wraps every route, so its init is the one reliable "app
    // started" hook. Re-arming the daily reminders here keeps them alive
    // across reinstalls, reboots, and timezone changes.
    Future.microtask(
        () => ref.read(reminderSchedulerProvider).syncDailyReminders());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // Consume the timestamp on resume. The Face ID sheet itself churns the
      // lifecycle (inactive→resumed, sometimes paused→resumed); without
      // clearing this, a stale "backgrounded long ago" value re-locks the app
      // the instant Face ID succeeds — an unlock loop that only a force-quit
      // escaped. Clearing it means that dismissal resume computes ~0 away.
      final at = _backgroundedAt;
      _backgroundedAt = null;
      if (at != null && DateTime.now().difference(at) > _grace) {
        ref.read(appLockProvider.notifier).lockIfPossible();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockProvider);
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (locked) const _LockScreen(),
      ],
    );
  }
}

class _LockScreen extends ConsumerWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: PulseColors.deepNight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PulsIQ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 240,
                child: PulseWave(height: 44, color: PulseColors.pulse),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: PulseColors.pulse,
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    ref.read(appLockProvider.notifier).unlock(),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
