import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../data/providers.dart';

const appLockSettingKey = 'app_lock_enabled';

final appLockEnabledProvider = FutureProvider<bool>((ref) async {
  final value =
      await ref.watch(appDatabaseProvider).getSetting(appLockSettingKey);
  return value != 'false'; // default ON once a profile exists (spec §0)
});

/// True while the UI must be covered by the lock screen.
class AppLockController extends Notifier<bool> {
  final _auth = LocalAuthentication();

  @override
  bool build() => false;

  Future<bool> _biometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported() ||
          await _auth.canCheckBiometrics;
    } catch (_) {
      return false; // plugin unavailable (tests, desktop) → never lock out
    }
  }

  /// Called on cold start and on foreground-return past the grace period.
  Future<void> lockIfPossible() async {
    final enabled =
        await ref.read(appLockEnabledProvider.future).catchError((_) => false);
    if (!enabled) return;
    if (!await _biometricsAvailable()) return;
    state = true;
  }

  Future<bool> unlock() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock PulsIQ',
      );
      if (ok) {
        state = false;
        await ref.read(appDatabaseProvider).logAudit(
              action: 'read',
              dataType: 'app_lock',
              source: 'biometric_prompt',
              purpose: 'unlock',
            );
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}

final appLockProvider =
    NotifierProvider<AppLockController, bool>(AppLockController.new);
