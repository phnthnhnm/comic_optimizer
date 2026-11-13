import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:comic_optimizer/core/interfaces/i_settings_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/custom_preset.dart';
import 'package:comic_optimizer/domain/models/preset.dart';

/// Implementation of [ISettingsService] backed by SharedPreferences.
///
/// Retains the legacy getter/setter API for backward compatibility with
/// [SettingsModel] which will be replaced in Phase 4.
final class SettingsServiceImpl implements ISettingsService {
  static const _keyPreferPermanentDelete = 'preferPermanentDelete';
  static const _keyOutputExt = 'outputExt';
  static const _keyLastRoot = 'lastRoot';
  static const _keyLastPreset = 'lastPreset';
  static const _keySkipCjxl = 'skipCjxl';
  static const _keyCjxlPath = 'cjxlPath';
  static const _keySafeRun = 'safeRun';
  static const _keyDeleteNonImageFiles = 'deleteNonImageFiles';
  static const _keyLibraryRoots = 'libraryRoots';
  static const _keyCustomPresets = 'customPresets';
  static const _keyPostRunAction = 'postRunAction';
  static const _keyPostRunConfirmEnabled = 'postRunConfirmEnabled';
  static const _keyPostRunConfirmSeconds = 'postRunConfirmSeconds';

  final SharedPreferences _prefs;

  SettingsServiceImpl(this._prefs);

  // ── ISettingsService interface methods ──────────────────────────────────

  @override
  Future<Result<AppSettings>> loadSettings() async {
    try {
      final settings = AppSettings(
        preferPermanentDelete: getPreferPermanentDelete(),
        outputExt: getOutputExt(),
        skipCjxl: getSkipCjxl(),
        safeRun: getSafeRun(),
        deleteNonImageFiles: getDeleteNonImageFiles(),
        cjxlPath: getCjxlPath(),
        lastPreset: getLastPreset(),
        lastRoot: getLastRoot(),
        libraryRoots: getLibraryRoots(),
        customPresets: getCustomPresets(),
        postRunAction: PostRunActionX.fromName(getPostRunAction()),
        postRunConfirmEnabled: getPostRunConfirmEnabled(),
        postRunConfirmSeconds: getPostRunConfirmSeconds(),
      );
      return Ok(settings);
    } catch (e) {
      return Err('Failed to load settings', cause: e);
    }
  }

  @override
  Future<Result<void>> saveSettings(AppSettings settings) async {
    try {
      await setPreferPermanentDelete(settings.preferPermanentDelete);
      await setOutputExt(settings.outputExt);
      await setSkipCjxl(settings.skipCjxl);
      await setSafeRun(settings.safeRun);
      await setDeleteNonImageFiles(settings.deleteNonImageFiles);
      await setCjxlPath(settings.cjxlPath);
      await setLastPreset(settings.lastPreset);
      await setLastRoot(settings.lastRoot);
      await setLibraryRoots(settings.libraryRoots);
      await setCustomPresets(settings.customPresets);
      await setPostRunAction(settings.postRunAction.toName);
      await setPostRunConfirmEnabled(settings.postRunConfirmEnabled);
      await setPostRunConfirmSeconds(settings.postRunConfirmSeconds);
      return const Ok<void>(null);
    } catch (e) {
      return Err('Failed to save settings', cause: e);
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _prefs.clear();
      return const Ok<void>(null);
    } catch (e) {
      return Err('Failed to clear settings', cause: e);
    }
  }

  @override
  Map<String, dynamic> getAllRaw() {
    final out = <String, dynamic>{};
    for (final k in _prefs.getKeys()) {
      out[k] = _prefs.get(k);
    }
    return out;
  }

  @override
  Future<Result<void>> setRawString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      return const Ok<void>(null);
    } catch (e) {
      return Err('Failed to set $key', cause: e);
    }
  }

  @override
  Future<Result<void>> setRawBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
      return const Ok<void>(null);
    } catch (e) {
      return Err('Failed to set $key', cause: e);
    }
  }

  @override
  Future<Result<void>> setRawInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
      return const Ok<void>(null);
    } catch (e) {
      return Err('Failed to set $key', cause: e);
    }
  }

  @override
  Future<Result<void>> setRawDouble(String key, double value) async {
    try {
      await _prefs.setDouble(key, value);
      return const Ok<void>(null);
    } catch (e) {
      return Err('Failed to set $key', cause: e);
    }
  }

  @override
  Future<Result<void>> setRawStringList(String key, List<String> value) async {
    try {
      await _prefs.setStringList(key, value);
      return const Ok<void>(null);
    } catch (e) {
      return Err('Failed to set $key', cause: e);
    }
  }

  // ── Legacy getters (backward compatible with SettingsModel) ─────────────

  bool getPreferPermanentDelete() =>
      _prefs.getBool(_keyPreferPermanentDelete) ?? false;

  String getOutputExt() => _prefs.getString(_keyOutputExt) ?? '.cbz';
  String? getLastRoot() => _prefs.getString(_keyLastRoot);
  String getLastPreset() =>
      _prefs.getString(_keyLastPreset) ?? Preset.losslessName;
  bool getSkipCjxl() => _prefs.getBool(_keySkipCjxl) ?? false;
  String getCjxlPath() => _prefs.getString(_keyCjxlPath) ?? 'cjxl';
  bool getSafeRun() => _prefs.getBool(_keySafeRun) ?? true;
  bool getDeleteNonImageFiles() =>
      _prefs.getBool(_keyDeleteNonImageFiles) ?? true;

  /// Falls back to the legacy `lastRoot` value on first load after upgrading.
  List<String> getLibraryRoots() {
    final stored = _prefs.getStringList(_keyLibraryRoots);
    if (stored != null) return stored;
    final legacy = getLastRoot();
    return legacy == null ? const [] : [legacy];
  }

  List<CustomPreset> getCustomPresets() {
    final raw = _prefs.getString(_keyCustomPresets);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => CustomPreset.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String getPostRunAction() => _prefs.getString(_keyPostRunAction) ?? 'none';
  bool getPostRunConfirmEnabled() =>
      _prefs.getBool(_keyPostRunConfirmEnabled) ?? true;
  int getPostRunConfirmSeconds() =>
      _prefs.getInt(_keyPostRunConfirmSeconds) ?? 60;

  // ── Legacy setters (backward compatible with SettingsModel) ─────────────

  Future<void> setPreferPermanentDelete(bool v) =>
      _prefs.setBool(_keyPreferPermanentDelete, v);

  Future<void> setOutputExt(String v) => _prefs.setString(_keyOutputExt, v);
  Future<void> setLastRoot(String? v) async {
    if (v == null) {
      await _prefs.remove(_keyLastRoot);
    } else {
      await _prefs.setString(_keyLastRoot, v);
    }
  }

  Future<void> setSkipCjxl(bool v) => _prefs.setBool(_keySkipCjxl, v);
  Future<void> setCjxlPath(String v) => _prefs.setString(_keyCjxlPath, v);
  Future<void> setSafeRun(bool v) => _prefs.setBool(_keySafeRun, v);
  Future<void> setDeleteNonImageFiles(bool v) =>
      _prefs.setBool(_keyDeleteNonImageFiles, v);
  Future<void> setLibraryRoots(List<String> v) =>
      _prefs.setStringList(_keyLibraryRoots, v);
  Future<void> setCustomPresets(List<CustomPreset> presets) => _prefs.setString(
    _keyCustomPresets,
    jsonEncode(presets.map((preset) => preset.toJson()).toList()),
  );

  Future<void> setPostRunAction(String v) =>
      _prefs.setString(_keyPostRunAction, v);
  Future<void> setPostRunConfirmEnabled(bool v) =>
      _prefs.setBool(_keyPostRunConfirmEnabled, v);
  Future<void> setPostRunConfirmSeconds(int v) =>
      _prefs.setInt(_keyPostRunConfirmSeconds, v);

  Future<void> setLastPreset(String v) => _prefs.setString(_keyLastPreset, v);

  // ── Legacy generic setters (used by restore in SettingsModel) ───────────

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // ── Legacy utility methods ──────────────────────────────────────────────

  /// Exposed for backward compatibility with [SettingsModel.getAllPrefs].
  Map<String, dynamic> getAll() => getAllRaw();
}
