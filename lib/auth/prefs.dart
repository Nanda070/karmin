import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret preferences (disclaimer, theme).
abstract interface class PrefsStore {
  Future<bool> getDisclaimerAccepted();
  Future<void> setDisclaimerAccepted(bool value);
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}

class MemoryPrefsStore implements PrefsStore {
  bool disclaimerAccepted = false;
  ThemeMode themeMode = ThemeMode.dark;

  @override
  Future<bool> getDisclaimerAccepted() async => disclaimerAccepted;

  @override
  Future<void> setDisclaimerAccepted(bool value) async {
    disclaimerAccepted = value;
  }

  @override
  Future<ThemeMode> getThemeMode() async => themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
  }
}

class SharedPrefsStore implements PrefsStore {
  // ignore: prefer_initializing_formals
  SharedPrefsStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const disclaimerKey = 'karmin.disclaimer.accepted';
  static const themeKey = 'karmin.theme.mode';

  Future<SharedPreferences> get _ready async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<bool> getDisclaimerAccepted() async {
    final prefs = await _ready;
    return prefs.getBool(disclaimerKey) ?? false;
  }

  @override
  Future<void> setDisclaimerAccepted(bool value) async {
    final prefs = await _ready;
    await prefs.setBool(disclaimerKey, value);
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await _ready;
    return themeModeFromName(prefs.getString(themeKey));
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _ready;
    await prefs.setString(themeKey, themeModeName(mode));
  }
}

String themeModeName(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
    ThemeMode.dark => 'dark',
  };
}

ThemeMode themeModeFromName(String? name) {
  return switch (name) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };
}
