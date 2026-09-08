import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:karmin/auth/prefs.dart';
import 'package:karmin/auth/providers.dart';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(ThemeMode.dark) {
    _hydrate();
  }

  final PrefsStore _prefs;

  Future<void> _hydrate() async {
    state = await _prefs.getThemeMode();
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
  }

  Future<void> cycle() async {
    final next = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
      ThemeMode.system => ThemeMode.dark,
    };
    await setMode(next);
  }
}

final themeModeControllerProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(prefsStoreProvider));
});
