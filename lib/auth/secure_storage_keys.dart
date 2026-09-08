/// Keystore key names (see docs/PLAN.md §4.5).
abstract final class SecureStorageKeys {
  static const neptunCode = 'karmin.neptun.code';
  static const neptunPassword = 'karmin.neptun.password';
  static const pinHash = 'karmin.pin.hash';
  static const pinSalt = 'karmin.pin.salt';
  static const bioEnabled = 'karmin.lock.bio_enabled';
}
