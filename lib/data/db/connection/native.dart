import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../security/key_vault.dart';
import '../../../security/secret_store.dart';

/// SQLCipher-encrypted database (§0: all health data encrypted at rest).
/// The cipher build is selected in pubspec.yaml (hooks → sqlite3 →
/// source: sqlcipher); the per-device key comes from the platform
/// keychain/keystore via [KeyVault] and never leaves the device.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pulsiq.sqlite'));
    final key = await KeyVault(const PlatformSecretStore()).databaseKeyHex();
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA key = "x\'$key\'";');
      },
    );
  });
}
