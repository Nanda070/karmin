import 'package:karmin/auth/secure_storage.dart';
import 'package:karmin/auth/secure_storage_keys.dart';

/// Persistence for Neptun credentials and PIN material.
abstract interface class SecureStore {
  Future<void> write(String key, String? value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clearCredentials();
}

/// In-memory store for tests. Never used in production.
class MemorySecureStore implements SecureStore {
  final Map<String, String> data = {};

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
  }

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  Future<void> clearCredentials() async {
    data.remove(SecureStorageKeys.neptunCode);
    data.remove(SecureStorageKeys.neptunPassword);
    data.remove(SecureStorageKeys.pinHash);
    data.remove(SecureStorageKeys.pinSalt);
    data.remove(SecureStorageKeys.bioEnabled);
  }
}

/// Production Keystore / Keychain adapter.
class KeystoreSecureStore implements SecureStore {
  KeystoreSecureStore({KarminSecureStorage? storage})
      : _storage = storage ?? KarminSecureStorage();

  final KarminSecureStorage _storage;

  @override
  Future<void> write(String key, String? value) => _storage.write(key, value);

  @override
  Future<String?> read(String key) => _storage.read(key);

  @override
  Future<void> delete(String key) => _storage.delete(key);

  @override
  Future<void> clearCredentials() => _storage.clearCredentials();
}
