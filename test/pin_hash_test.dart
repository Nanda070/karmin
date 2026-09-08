import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/auth/pin_hash.dart';

void main() {
  group('PinHash', () {
    test('hashes 6-digit PIN with 16-byte salt', () {
      final salt = Uint8List.fromList(List<int>.filled(16, 7));
      final a = PinHash.hash('123456', salt);
      final b = PinHash.hash('123456', salt);
      expect(a, b);
      expect(a.length, 64);
      expect(PinHash.matches('123456', salt, a), isTrue);
      expect(PinHash.matches('123457', salt, a), isFalse);
    });

    test('rejects non-6-digit PIN', () {
      final salt = PinHash.generateSalt();
      expect(() => PinHash.hash('12345', salt), throwsArgumentError);
    });
  });
}
