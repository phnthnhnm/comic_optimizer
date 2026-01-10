import 'package:flutter/material.dart';

import '../presets.dart';
import 'settings_repository.dart';

class SettingsModel extends ChangeNotifier {
  final SettingsRepository _repo;

  bool preferPermanentDelete = false;
  bool skipPingo = false;
  String pingoPath = 'pingo';
  String outputExt = '.cbz';
  String? lastRoot;
  String lastPreset = '';
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

  Future<void> setSkipPingo(bool v) async {
    skipPingo = v;
    notifyListeners();
    await _repo.setSkipPingo(v);
  }

  Future<void> setPingoPath(String v) async {
    pingoPath = v;
    notifyListeners();
    await _repo.setPingoPath(v);
  }

  Future<void> setOutputExt(String v) async {
    outputExt = v;
    notifyListeners();
    await _repo.setOutputExt(v);
  }

  Future<void> setLastRoot(String? v) async {
    lastRoot = v;
    notifyListeners();
    await _repo.setLastRoot(v);
  }

  Future<void> setLastPreset(String v) async {
    lastPreset = v;
    notifyListeners();
    await _repo.setLastPreset(v);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await _repo.setThemeMode(_modeToString(m));
  }

  // Custom presets managed by the user
  List<Preset> customPresets = [];

  // load custom presets alongside other prefs
  Future<void> load() async {
    await _repo.init();
    preferPermanentDelete = _repo.getPreferPermanentDelete();
    skipPingo = _repo.getSkipPingo();
    pingoPath = _repo.getPingoPath();
    outputExt = _repo.getOutputExt();
    lastRoot = _repo.getLastRoot();
    lastPreset = _repo.getLastPreset();
    final s = _repo.getThemeMode();
    themeMode = _stringToMode(s);
    // load custom presets
    customPresets = _repo.getCustomPresets();
    notifyListeners();
  }

  Future<void> addPreset(Preset p) async {
    customPresets.add(p);
    notifyListeners();
    await _repo.setCustomPresets(customPresets);
  }

  Future<void> updatePreset(int idx, Preset p) async {
    if (idx < 0 || idx >= customPresets.length) return;
    customPresets[idx] = p;
    notifyListeners();
    await _repo.setCustomPresets(customPresets);
  }

  Future<void> removePreset(int idx) async {
    if (idx < 0 || idx >= customPresets.length) return;
    customPresets.removeAt(idx);
    notifyListeners();
    await _repo.setCustomPresets(customPresets);
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
