import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoUtils {
  static final CryptoUtils _instance = CryptoUtils._internal();

  factory CryptoUtils() => _instance;

  CryptoUtils._internal();

  enc.Key _deriveKey(String secret) {
    final bytes = utf8.encode(secret);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  String encrypt(String plainText, String secret) {
    final key = _deriveKey(secret);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);

    return base64.encode(combined);
  }

  String decrypt(String encryptedBase64, String secret) {
    final key = _deriveKey(secret);
    final decoded = base64.decode(encryptedBase64);

    if (decoded.length < 16) {
      throw FormatException('Invalid encrypted data length');
    }

    final ivBytes = Uint8List.fromList(decoded.sublist(0, 16));
    final cipherBytes = Uint8List.fromList(decoded.sublist(16));

    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = enc.Encrypted(cipherBytes);

    return encrypter.decrypt(encrypted, iv: iv);
  }

  String hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
