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

/// Face ID fires as soon as this appears — the user opened the app, which is
/// the request to unlock; making them tap a button first just added a step in
/// front of the system prompt.
///
/// The manual control stays for the retry case: if authentication is
/// cancelled or fails there has to be a way back in, and silently re-prompting
/// in a loop is worse than asking.
class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  bool _prompting = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Post-frame: initState runs during build, and unlock() ends up writing
    // provider state.
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _prompting = true;
      _failed = false;
    });
    final ok = await ref.read(appLockProvider.notifier).unlock();
    if (!mounted) return;
    // On success the gate unmounts this screen; only the failure path needs
    // to render anything.
    setState(() {
      _prompting = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _LockScreenBody(
      prompting: _prompting,
      failed: _failed,
      onRetry: _authenticate,
    );
  }
}

class _LockScreenBody extends StatelessWidget {
  const _LockScreenBody({
    required this.prompting,
    required this.failed,
    required this.onRetry,
  });

  final bool prompting;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
              if (prompting)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white70),
                )
              else ...[
                if (failed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Face ID didn\'t complete.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14),
                    ),
                  ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: PulseColors.pulse,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(failed ? 'Try again' : 'Unlock'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
