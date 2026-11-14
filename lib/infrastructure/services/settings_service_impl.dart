import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:comic_optimizer/core/interfaces/i_settings_service.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/custom_preset.dart';
import 'package:comic_optimizer/domain/models/library_entry.dart';
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
  static const _keyLibraries = 'libraries';
  static const _keyCustomPresets = 'customPresets';
  static const _keyOutputMode = 'outputMode';
  static const _keyOutputDirectory = 'outputDirectory';
  static const _keyNamingTemplate = 'namingTemplate';
  static const _keyCollisionPolicy = 'collisionPolicy';
  static const _keySkipExistingArchives = 'skipExistingArchives';
  static const _keyMaxParallelEncodes = 'maxParallelEncodes';
  static const _keyPreventSleep = 'preventSleep';
  static const _keyPostRunAction = 'postRunAction';
  static const _keyPostRunConfirmEnabled = 'postRunConfirmEnabled';
  static const _keyPostRunConfirmSeconds = 'postRunConfirmSeconds';
  static const _keyTutorialCompleted = 'tutorialCompleted';
  static const _keyAnimationsEnabled = 'animationsEnabled';

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
        libraries: getLibraries(),
        customPresets: getCustomPresets(),
        outputMode: getOutputMode(),
        outputDirectory: getOutputDirectory(),
        namingTemplate: getNamingTemplate(),
        collisionPolicy: getCollisionPolicy(),
        skipExistingArchives: getSkipExistingArchives(),
        maxParallelEncodes: getMaxParallelEncodes(),
        preventSleep: getPreventSleep(),
        postRunAction: PostRunActionX.fromName(getPostRunAction()),
        postRunConfirmEnabled: getPostRunConfirmEnabled(),
        postRunConfirmSeconds: getPostRunConfirmSeconds(),
        tutorialCompleted: getTutorialCompleted(),
        animationsEnabled: getAnimationsEnabled(),
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
      await setLibraries(settings.libraries);
      await setCustomPresets(settings.customPresets);
      await setOutputMode(settings.outputMode);
      await setOutputDirectory(settings.outputDirectory);
      await setNamingTemplate(settings.namingTemplate);
      await setCollisionPolicy(settings.collisionPolicy);
      await setSkipExistingArchives(settings.skipExistingArchives);
      await setMaxParallelEncodes(settings.maxParallelEncodes);
      await setPreventSleep(settings.preventSleep);
      await setPostRunAction(settings.postRunAction.toName);
      await setPostRunConfirmEnabled(settings.postRunConfirmEnabled);
      await setPostRunConfirmSeconds(settings.postRunConfirmSeconds);
      await setTutorialCompleted(settings.tutorialCompleted);
      await setAnimationsEnabled(settings.animationsEnabled);
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

  String getOutputExt() {
    final ext = _prefs.getString(_keyOutputExt) ?? '.cbz';
    return ext.toLowerCase() == '.cbr' ? '.cbz' : ext;
  }

  String? getLastRoot() => _prefs.getString(_keyLastRoot);
  String getLastPreset() =>
      _prefs.getString(_keyLastPreset) ?? Preset.losslessName;
  bool getSkipCjxl() => _prefs.getBool(_keySkipCjxl) ?? false;
  String getCjxlPath() => _prefs.getString(_keyCjxlPath) ?? 'cjxl';
  bool getSafeRun() => _prefs.getBool(_keySafeRun) ?? true;
  bool getDeleteNonImageFiles() =>
      _prefs.getBool(_keyDeleteNonImageFiles) ?? true;

  /// Reads the structured queue, migrating the legacy path-only list.
  List<LibraryEntry> getLibraries() {
    final raw = _prefs.getString(_keyLibraries);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map(
                (item) => LibraryEntry.fromJson(item.cast<String, dynamic>()),
              )
              .toList();
        }
      } catch (_) {}
    }

    final legacy = _prefs.getStringList(_keyLibraryRoots);
    if (legacy != null && legacy.isNotEmpty) {
      return legacy.map((path) => LibraryEntry(path: path)).toList();
    }

    final lastRoot = getLastRoot();
    return lastRoot == null ? const [] : [LibraryEntry(path: lastRoot)];
  }

  OutputMode getOutputMode() {
    final raw = _prefs.getString(_keyOutputMode);
    return OutputMode.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => OutputMode.besideSource,
    );
  }

  String getOutputDirectory() => _prefs.getString(_keyOutputDirectory) ?? '';
  String getNamingTemplate() =>
      _prefs.getString(_keyNamingTemplate) ?? '{folder}';

  CollisionPolicy getCollisionPolicy() {
    final raw = _prefs.getString(_keyCollisionPolicy);
    return CollisionPolicy.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => CollisionPolicy.overwrite,
    );
  }

  bool getSkipExistingArchives() =>
      _prefs.getBool(_keySkipExistingArchives) ?? false;
  int getMaxParallelEncodes() => _prefs.getInt(_keyMaxParallelEncodes) ?? 2;
  bool getPreventSleep() => _prefs.getBool(_keyPreventSleep) ?? true;

  /// Legacy helper retained for old callers.
  List<String> getLibraryRoots() =>
      getLibraries().map((entry) => entry.path).toList();

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
  bool getTutorialCompleted() => _prefs.getBool(_keyTutorialCompleted) ?? false;
  bool getAnimationsEnabled() => _prefs.getBool(_keyAnimationsEnabled) ?? true;

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
  Future<void> setLibraryRoots(List<String> v) async {
    await _prefs.setStringList(_keyLibraryRoots, v);
    await setLibraries(v.map((path) => LibraryEntry(path: path)).toList());
  }

  Future<void> setLibraries(List<LibraryEntry> libraries) async {
    await _prefs.setString(
      _keyLibraries,
      jsonEncode(libraries.map((entry) => entry.toJson()).toList()),
    );
    // Keep the legacy key populated for one release so downgrades keep the
    // queue paths (overrides are intentionally not representable there).
    await _prefs.setStringList(
      _keyLibraryRoots,
      libraries.map((entry) => entry.path).toList(),
    );
  }

  Future<void> setOutputMode(OutputMode v) =>
      _prefs.setString(_keyOutputMode, v.name);
  Future<void> setOutputDirectory(String v) =>
      _prefs.setString(_keyOutputDirectory, v);
  Future<void> setNamingTemplate(String v) =>
      _prefs.setString(_keyNamingTemplate, v);
  Future<void> setCollisionPolicy(CollisionPolicy v) =>
      _prefs.setString(_keyCollisionPolicy, v.name);
  Future<void> setSkipExistingArchives(bool v) =>
      _prefs.setBool(_keySkipExistingArchives, v);
  Future<void> setMaxParallelEncodes(int v) =>
      _prefs.setInt(_keyMaxParallelEncodes, v);
  Future<void> setPreventSleep(bool v) => _prefs.setBool(_keyPreventSleep, v);
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
  Future<void> setTutorialCompleted(bool v) =>
      _prefs.setBool(_keyTutorialCompleted, v);
  Future<void> setAnimationsEnabled(bool v) =>
      _prefs.setBool(_keyAnimationsEnabled, v);

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
