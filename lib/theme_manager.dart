import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const _key = 'theme_mode';

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static late SharedPreferences _prefs;
  static bool _initialized = false;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final s = _prefs.getString(_key) ?? 'system';
    themeMode.value = _stringToMode(s);
    _initialized = true;
  }

  static ThemeMode _stringToMode(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    return ThemeMode.system;
  }

  static String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      if (!_initialized) {
        await init();
      }
      final ok = await _prefs.setString(_key, _modeToString(mode));
      if (!ok) {
        debugPrint('ThemeManager: failed to persist theme_mode=$mode');
      } else {
        debugPrint('ThemeManager: persisted theme_mode=${_modeToString(mode)}');
      }
    } catch (e) {
      debugPrint('ThemeManager: error persisting theme mode: $e');
    }
  }
}
