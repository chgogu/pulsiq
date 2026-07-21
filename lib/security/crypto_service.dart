import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM sealing for client-side encryption of anything that leaves
/// the device (zero-knowledge backup posture, §4). Output layout:
/// base64(nonce(12) | ciphertext | mac(16)).
class CryptoService {
  CryptoService(List<int> keyBytes)
      : assert(keyBytes.length == 32, 'AES-256 needs a 32-byte key'),
        _key = SecretKey(keyBytes);

  final SecretKey _key;
  static final _algorithm = AesGcm.with256bits();

  Future<String> encryptString(String plaintext) async {
    final box = await _algorithm.encrypt(utf8.encode(plaintext), secretKey: _key);
    final packed = <int>[
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ];
    return base64Encode(packed);
  }

  Future<String> decryptString(String sealed) async {
    final packed = base64Decode(sealed);
    if (packed.length < 12 + 16) {
      throw const FormatException('sealed blob too short');
    }
    final box = SecretBox(
      packed.sublist(12, packed.length - 16),
      nonce: packed.sublist(0, 12),
      mac: Mac(packed.sublist(packed.length - 16)),
    );
    final clear = await _algorithm.decrypt(box, secretKey: _key);
    return utf8.decode(clear);
  }
}
