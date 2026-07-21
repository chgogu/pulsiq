import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/providers.dart';

enum AuthMethod { none, google, passkey, local }

class AuthState {
  const AuthState({required this.method, this.displayName});

  final AuthMethod method;
  final String? displayName;

  bool get signedIn => method != AuthMethod.none;
}

final authStateProvider = FutureProvider<AuthState>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final method = await db.getSetting('auth_method');
  final name = await db.getSetting('auth_display_name');
  return AuthState(
    method: AuthMethod.values
        .where((m) => m.name == method)
        .firstOrNull ??
        AuthMethod.none,
    displayName: name,
  );
});

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.message);

  final String message;
}

/// No password auth anywhere (spec §0): Google OAuth, passkeys, or an
/// explicit local-only profile. Google/passkey complete once the OAuth
/// client IDs and the Supabase relying-party deployment exist — both are
/// deployment configuration, not code.
class AuthService {
  AuthService(this._ref);

  final Ref _ref;

  Future<void> _persist(AuthMethod method, String? name) async {
    final db = _ref.read(appDatabaseProvider);
    await db.setSetting('auth_method', method.name);
    await db.setSetting('auth_display_name', name ?? '');
    await db.logAudit(
      action: 'write',
      dataType: 'auth',
      source: 'auth_service',
      purpose: 'sign_in_${method.name}',
    );
    _ref.invalidate(authStateProvider);
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final account = await GoogleSignIn.instance.authenticate();
      await _persist(
          AuthMethod.google, account.displayName ?? account.email);
      return const AuthSuccess();
    } catch (_) {
      return const AuthFailure(
          'Google Sign-In needs its OAuth client IDs — pending backend '
          'setup. Use a local profile for now.');
    }
  }

  Future<AuthResult> signInWithPasskey() async {
    return const AuthFailure(
        'Passkeys arrive with the Supabase relying-party deployment. '
        'Use a local profile for now.');
  }

  Future<AuthResult> continueLocally() async {
    await _persist(AuthMethod.local, 'Local profile');
    return const AuthSuccess();
  }

  Future<void> signOut() async {
    final db = _ref.read(appDatabaseProvider);
    await db.setSetting('auth_method', AuthMethod.none.name);
    await db.setSetting('auth_display_name', '');
    await db.logAudit(
      action: 'write',
      dataType: 'auth',
      source: 'auth_service',
      purpose: 'sign_out',
    );
    _ref.invalidate(authStateProvider);
  }
}

final authServiceProvider = Provider<AuthService>(AuthService.new);
