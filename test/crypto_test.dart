import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/security/crypto_service.dart';
import 'package:pulsiq/security/key_vault.dart';
import 'package:pulsiq/security/secret_store.dart';

void main() {
  group('KeyVault', () {
    test('creates keys once and returns them stably', () async {
      final vault = KeyVault(InMemorySecretStore());
      final k1 = await vault.databaseKeyHex();
      final k2 = await vault.databaseKeyHex();
      expect(k1, k2);
      expect(k1.length, 64); // 32 bytes hex
      final data = await vault.dataKeyBytes();
      expect(data.length, 32);
    });

    test('database and data keys are distinct; wipe regenerates', () async {
      final vault = KeyVault(InMemorySecretStore());
      final db1 = await vault.databaseKeyHex();
      final data1 = await vault.dataKeyBytes();
      expect(db1, isNot(data1.map((b) => b.toRadixString(16)).join()));
      await vault.wipe();
      expect(await vault.databaseKeyHex(), isNot(db1));
    });
  });

  group('CryptoService (AES-256-GCM)', () {
    test('round-trips a string', () async {
      final vault = KeyVault(InMemorySecretStore());
      final crypto = CryptoService(await vault.dataKeyBytes());
      const plaintext = 'late pasta → RHR up 6 over baseline 🍝';
      final sealed = await crypto.encryptString(plaintext);
      expect(sealed, isNot(contains('pasta')));
      expect(await crypto.decryptString(sealed), plaintext);
    });

    test('same plaintext encrypts to different blobs (fresh nonces)',
        () async {
      final crypto =
          CryptoService(await KeyVault(InMemorySecretStore()).dataKeyBytes());
      final a = await crypto.encryptString('hydrate');
      final b = await crypto.encryptString('hydrate');
      expect(a, isNot(b));
    });

    test('tampering is detected', () async {
      final crypto =
          CryptoService(await KeyVault(InMemorySecretStore()).dataKeyBytes());
      final sealed = await crypto.encryptString('secret log entry');
      final bytes = sealed.codeUnits.toList();
      bytes[20] = bytes[20] == 65 ? 66 : 65; // flip a character
      final tampered = String.fromCharCodes(bytes);
      await expectLater(
        () => crypto.decryptString(tampered),
        throwsA(anything),
      );
    });

    test('wrong key cannot decrypt', () async {
      final crypto1 =
          CryptoService(await KeyVault(InMemorySecretStore()).dataKeyBytes());
      final crypto2 =
          CryptoService(await KeyVault(InMemorySecretStore()).dataKeyBytes());
      final sealed = await crypto1.encryptString('for my eyes only');
      await expectLater(
        () => crypto2.decryptString(sealed),
        throwsA(anything),
      );
    });
  });
}
