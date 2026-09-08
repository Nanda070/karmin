import 'package:shared_preferences/shared_preferences.dart';

import 'package:karmin/data/cache_store.dart';

class PrefsCacheStore implements CacheStore {
  // ignore: prefer_initializing_formals
  PrefsCacheStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _prefix = 'karmin.cache.';

  Future<SharedPreferences> get _ready async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<String?> read(String key) async {
    final prefs = await _ready;
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await _ready;
    await prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await _ready;
    await prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    final prefs = await _ready;
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
