import 'package:flutter/material.dart';

import '../presets.dart';
import 'settings_repository.dart';

class SettingsModel extends ChangeNotifier {
  final SettingsRepository _repo;

  bool preferPermanentDelete = false;
  String outputExt = '.cbz';
  bool skipCjxl = false;
  bool safeRun = false;
  String cjxlPath = 'cjxl';
  String lastPreset = Preset.losslessName;
  String? lastRoot;
  ThemeMode themeMode = ThemeMode.system;

  SettingsModel(this._repo);

  ThemeMode _stringToMode(String s) {
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

  String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  // setters that persist
  Future<void> setPreferPermanentDelete(bool v) async {
    preferPermanentDelete = v;
    notifyListeners();
    await _repo.setPreferPermanentDelete(v);
  }

  Future<void> setOutputExt(String v) async {
    outputExt = v;
    notifyListeners();
    await _repo.setOutputExt(v);
  }

  Future<void> setSkipCjxl(bool v) async {
    skipCjxl = v;
    notifyListeners();
    await _repo.setSkipCjxl(v);
  }

  Future<void> setSafeRun(bool v) async {
    safeRun = v;
    notifyListeners();
    await _repo.setSafeRun(v);
  }

  Future<void> setCjxlPath(String v) async {
    cjxlPath = v;
    notifyListeners();
    await _repo.setCjxlPath(v);
  }

  Future<void> setLastPreset(String v) async {
    lastPreset = v;
    notifyListeners();
    await _repo.setLastPreset(v);
  }

  Future<void> setLastRoot(String? v) async {
    lastRoot = v;
    notifyListeners();
    await _repo.setLastRoot(v);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await _repo.setThemeMode(_modeToString(m));
  }

  // load preferences
  Future<void> load() async {
    await _repo.init();
    preferPermanentDelete = _repo.getPreferPermanentDelete();
    outputExt = _repo.getOutputExt();
    skipCjxl = _repo.getSkipCjxl();
    safeRun = _repo.getSafeRun();
    cjxlPath = _repo.getCjxlPath();
    lastRoot = _repo.getLastRoot();
    lastPreset = _repo.getLastPreset().isNotEmpty
        ? _repo.getLastPreset()
        : Preset.losslessName;

    final s = _repo.getThemeMode();
    themeMode = _stringToMode(s);

    notifyListeners();
  }

  // Generic setters exposing repository functionality for restore
  Future<void> setRawString(String key, String value) =>
      _repo.setString(key, value);
  Future<void> setRawBool(String key, bool value) => _repo.setBool(key, value);
  Future<void> setRawInt(String key, int value) => _repo.setInt(key, value);
  Future<void> setRawDouble(String key, double value) =>
      _repo.setDouble(key, value);
  Future<void> setRawStringList(String key, List<String> value) =>
      _repo.setStringList(key, value);

  Map<String, dynamic> getAllPrefs() => _repo.getAll();
  Future<void> clearAllPrefs() => _repo.clearAll();
}
