import 'dart:math';

import 'secret_store.dart';

/// Owns the device-held keys (§4): the SQLCipher database key and the
/// AES-GCM data key for client-side encryption of any cloud-bound blob.
/// Keys are generated on device, never leave the SecretStore, and are not
/// recoverable if every device is lost (documented product stance).
class KeyVault {
  KeyVault(this._store);

  final SecretStore _store;

  static const _dbKeyName = 'pulsiq.db_key.v1';
  static const _dataKeyName = 'pulsiq.data_key.v1';

  static String _randomHex(int bytes) {
    final rng = Random.secure();
    final b = List<int>.generate(bytes, (_) => rng.nextInt(256));
    return b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<String> _getOrCreate(String name) async {
    final existing = await _store.read(name);
    if (existing != null) return existing;
    final fresh = _randomHex(32);
    await _store.write(name, fresh);
    return fresh;
  }

  /// 64 hex chars — used as `PRAGMA key = "x'<hex>'"` by SQLCipher.
  Future<String> databaseKeyHex() => _getOrCreate(_dbKeyName);

  /// 32-byte key for [CryptoService], hex-encoded at rest.
  Future<List<int>> dataKeyBytes() async {
    final hex = await _getOrCreate(_dataKeyName);
    return [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
  }

  Future<void> wipe() async {
    await _store.delete(_dbKeyName);
    await _store.delete(_dataKeyName);
  }
}
