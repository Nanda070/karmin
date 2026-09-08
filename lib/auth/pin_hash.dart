import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// 6-digit PIN hashing helpers.
///
/// Store `sha256(pin + salt)` only — never the PIN plaintext.
/// Salt: 16 random bytes kept in Keystore under `karmin.pin.salt`.
abstract final class PinHash {
  static const pinLength = 6;
  static const saltByteLength = 16;

  static bool isValidPin(String pin) =>
      RegExp(r'^\d{6}$').hasMatch(pin);

  /// Returns a new cryptographically random 16-byte salt.
  static Uint8List generateSalt([Random? random]) {
    final rng = random ?? Random.secure();
    return Uint8List.fromList(
      List<int>.generate(saltByteLength, (_) => rng.nextInt(256)),
    );
  }

  static String encodeSalt(Uint8List salt) => base64Encode(salt);

  static Uint8List decodeSalt(String encoded) =>
      Uint8List.fromList(base64Decode(encoded));

  /// `sha256(utf8(pin) || salt)` as lowercase hex.
  static String hash(String pin, Uint8List salt) {
    if (!isValidPin(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must be exactly 6 digits');
    }
    if (salt.length != saltByteLength) {
      throw ArgumentError.value(
        salt.length,
        'salt.length',
        'Salt must be $saltByteLength bytes',
      );
    }
    final bytes = BytesBuilder(copy: false)
      ..add(utf8.encode(pin))
      ..add(salt);
    return sha256.convert(bytes.toBytes()).toString();
  }

  /// Constant-time comparison of two hex digests.
  static bool matches(String pin, Uint8List salt, String expectedHex) {
    final actual = hash(pin, salt);
    if (actual.length != expectedHex.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHex.codeUnitAt(i);
    }
    return diff == 0;
  }
}
