import 'package:flutter/material.dart';

import '../presets.dart';
import 'settings_repository.dart';

enum LogLevel { none, normal, error }

enum PostRunAction { none, quit, sleep, hibernate, shutdown, restart }

String _postRunActionToName(PostRunAction a) {
  switch (a) {
    case PostRunAction.quit:
      return 'quit';
    case PostRunAction.sleep:
      return 'sleep';
    case PostRunAction.hibernate:
      return 'hibernate';
    case PostRunAction.shutdown:
      return 'shutdown';
    case PostRunAction.restart:
      return 'restart';
    case PostRunAction.none:
      return 'none';
  }
}

PostRunAction _postRunActionFromName(String s) {
  switch (s) {
    case 'quit':
      return PostRunAction.quit;
    case 'sleep':
      return PostRunAction.sleep;
    case 'hibernate':
      return PostRunAction.hibernate;
    case 'shutdown':
      return PostRunAction.shutdown;
    case 'restart':
      return PostRunAction.restart;
    default:
      return PostRunAction.none;
  }
}

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
  // Logging settings
  LogLevel logLevel = LogLevel.none;

  // post-run action settings
  PostRunAction postRunAction = PostRunAction.none;
  bool postRunConfirmEnabled = true;
  int postRunConfirmSeconds = 60;

  SettingsModel(this._repo);

  // Log level conversions
  String _logLevelToName(LogLevel l) {
    switch (l) {
      case LogLevel.none:
        return 'none';
      case LogLevel.normal:
        return 'normal';
      case LogLevel.error:
        return 'error';
    }
  }

  LogLevel _logLevelFromName(String s) {
    switch (s) {
      case 'normal':
        return LogLevel.normal;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.none;
    }
  }

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
    if (m == ThemeMode.light) return 'light';
    if (m == ThemeMode.dark) return 'dark';
    return 'system';
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

  Future<void> setPostRunAction(PostRunAction v) async {
    postRunAction = v;
    notifyListeners();
    await _repo.setPostRunAction(_postRunActionToName(v));
  }

  Future<void> setPostRunConfirmEnabled(bool v) async {
    postRunConfirmEnabled = v;
    notifyListeners();
    await _repo.setPostRunConfirmEnabled(v);
  }

  Future<void> setPostRunConfirmSeconds(int v) async {
    postRunConfirmSeconds = v;
    notifyListeners();
    await _repo.setPostRunConfirmSeconds(v);
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

  Future<void> setLogLevel(LogLevel l) async {
    logLevel = l;
    notifyListeners();
    await _repo.setLogLevel(_logLevelToName(l));
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

    // load post-run settings
    postRunAction = _postRunActionFromName(_repo.getPostRunAction());
    postRunConfirmEnabled = _repo.getPostRunConfirmEnabled();
    postRunConfirmSeconds = _repo.getPostRunConfirmSeconds();

    final s = _repo.getThemeMode();
    themeMode = _stringToMode(s);

    // load logging setting
    final ls = _repo.getLogLevel();
    logLevel = _logLevelFromName(ls);

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
