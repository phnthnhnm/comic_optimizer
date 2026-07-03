import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/enums/log_level.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    // Default state; loaded asynchronously in load()
    return const AppSettings();
  }

  Future<void> load() async {
    final service = ref.read(settingsServiceProvider);
    final result = await service.loadSettings();
    switch (result) {
      case Ok(value: final settings):
        state = settings;
      case Err():
        break;
    }
  }

  Future<void> _update(AppSettings Function(AppSettings) transform) async {
    final newSettings = transform(state);
    state = newSettings;
    final service = ref.read(settingsServiceProvider);
    await service.saveSettings(newSettings);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setOutputExt(String ext) =>
      _update((s) => s.copyWith(outputExt: ext));

  Future<void> setSkipCjxl(bool v) => _update((s) => s.copyWith(skipCjxl: v));

  Future<void> setSafeRun(bool v) => _update((s) => s.copyWith(safeRun: v));

  Future<void> setPreferPermanentDelete(bool v) =>
      _update((s) => s.copyWith(preferPermanentDelete: v));

  Future<void> setCjxlPath(String v) => _update((s) => s.copyWith(cjxlPath: v));

  Future<void> setLastPreset(String v) =>
      _update((s) => s.copyWith(lastPreset: v));

  Future<void> setLastRoot(String? v) =>
      _update((s) => s.copyWith(lastRoot: v));

  Future<void> setLogLevel(LogLevel l) =>
      _update((s) => s.copyWith(logLevel: l));

  Future<void> setPostRunAction(PostRunAction v) =>
      _update((s) => s.copyWith(postRunAction: v));

  Future<void> setPostRunConfirmEnabled(bool v) =>
      _update((s) => s.copyWith(postRunConfirmEnabled: v));

  Future<void> setPostRunConfirmSeconds(int v) =>
      _update((s) => s.copyWith(postRunConfirmSeconds: v));

  // For backup/restore data tab
  Future<void> setRawString(String key, String value) async {
    final service = ref.read(settingsServiceProvider);
    await service.setRawString(key, value);
  }

  Future<void> setRawBool(String key, bool value) async {
    final service = ref.read(settingsServiceProvider);
    await service.setRawBool(key, value);
  }

  Future<void> setRawInt(String key, int value) async {
    final service = ref.read(settingsServiceProvider);
    await service.setRawInt(key, value);
  }

  Future<void> setRawDouble(String key, double value) async {
    final service = ref.read(settingsServiceProvider);
    await service.setRawDouble(key, value);
  }

  Future<void> setRawStringList(String key, List<String> value) async {
    final service = ref.read(settingsServiceProvider);
    await service.setRawStringList(key, value);
  }

  Map<String, dynamic> getAllPrefs() {
    final service = ref.read(settingsServiceProvider);
    return service.getAllRaw();
  }

  Future<void> clearAllPrefs() async {
    final service = ref.read(settingsServiceProvider);
    await service.clearAll();
    state = const AppSettings();
  }
}
