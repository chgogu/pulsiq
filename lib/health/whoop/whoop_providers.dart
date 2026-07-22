import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../security/secret_store.dart';
import 'whoop_client.dart';

/// Device keychain seam. Shared so anything needing secure storage resolves
/// the same implementation (and tests can override it).
final secretStoreProvider =
    Provider<SecretStore>((_) => const PlatformSecretStore());

/// Singleton so the in-memory access-token cache survives across reads.
final whoopAuthProvider =
    Provider<WhoopAuth>((ref) => WhoopAuth(store: ref.read(secretStoreProvider)));

/// True once a refresh token is stored — i.e. WHOOP is linked.
final whoopConnectedProvider =
    FutureProvider<bool>((ref) => ref.read(whoopAuthProvider).isConnected());

/// Launches the OAuth flow; returns whether the link succeeded. Audited like
/// every health-data access.
final whoopConnectorProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final ok = await ref.read(whoopAuthProvider).connect();
    await ref.read(appDatabaseProvider).logAudit(
          action: 'read',
          dataType: 'health_permissions',
          source: 'whoop',
          purpose: ok ? 'granted' : 'denied',
        );
    if (ok) ref.invalidate(whoopConnectedProvider);
    return ok;
  };
});

final whoopDisconnectProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(whoopAuthProvider).disconnect();
    ref.invalidate(whoopConnectedProvider);
  };
});
