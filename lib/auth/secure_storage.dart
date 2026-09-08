import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:karmin/auth/secure_storage_keys.dart';

/// Wrapper around OS Keystore / Keychain for Neptun credentials and PIN hash.
///
/// iOS: Keychain accessibility is `first_unlock_this_device` and
/// `synchronizable: false` so the password item does not sync via iCloud.
class KarminSecureStorage {
  KarminSecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            );

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String? value) {
    if (value == null) {
      return _storage.delete(key: key);
    }
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: SecureStorageKeys.neptunCode),
      _storage.delete(key: SecureStorageKeys.neptunPassword),
      _storage.delete(key: SecureStorageKeys.pinHash),
      _storage.delete(key: SecureStorageKeys.pinSalt),
      _storage.delete(key: SecureStorageKeys.bioEnabled),
    ]);
  }

  @visibleForTesting
  FlutterSecureStorage get storage => _storage;
}
