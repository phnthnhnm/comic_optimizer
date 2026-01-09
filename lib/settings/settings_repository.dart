import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyPreferPermanentDelete = 'preferPermanentDelete';
  static const _keySkipPingo = 'skipPingo';
  static const _keyPingoPath = 'pingoPath';
  static const _keyOutputExt = 'outputExt';
  static const _keyLastRoot = 'lastRoot';
  static const _keyLastPreset = 'lastPreset';
  static const _keyThemeMode = 'theme_mode';

  late final SharedPreferences _prefs;

  SettingsRepository();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // getters
  bool getPreferPermanentDelete() =>
      _prefs.getBool(_keyPreferPermanentDelete) ?? false;
  bool getSkipPingo() => _prefs.getBool(_keySkipPingo) ?? false;
  String getPingoPath() => _prefs.getString(_keyPingoPath) ?? 'pingo';
  String getOutputExt() => _prefs.getString(_keyOutputExt) ?? '.cbz';
  String? getLastRoot() => _prefs.getString(_keyLastRoot);
  String getLastPreset() => _prefs.getString(_keyLastPreset) ?? '';
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'system';

  // setters
  Future<void> setPreferPermanentDelete(bool v) =>
      _prefs.setBool(_keyPreferPermanentDelete, v);
  Future<void> setSkipPingo(bool v) => _prefs.setBool(_keySkipPingo, v);
  Future<void> setPingoPath(String v) => _prefs.setString(_keyPingoPath, v);
  Future<void> setOutputExt(String v) => _prefs.setString(_keyOutputExt, v);
  Future<void> setLastRoot(String? v) async {
    if (v == null) {
      await _prefs.remove(_keyLastRoot);
    } else {
      await _prefs.setString(_keyLastRoot, v);
    }
  }

  Future<void> setLastPreset(String v) => _prefs.setString(_keyLastPreset, v);
  Future<void> setThemeMode(String v) => _prefs.setString(_keyThemeMode, v);

  // Generic setters for unknown keys (used by restore)
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // utility
  Map<String, dynamic> getAll() {
    final out = <String, dynamic>{};
    for (final k in _prefs.getKeys()) {
      out[k] = _prefs.get(k);
    }
    return out;
  }

  Future<void> clearAll() => _prefs.clear();
}
