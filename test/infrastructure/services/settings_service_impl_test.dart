import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/log_level.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/infrastructure/services/settings_service_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsServiceImpl', () {
    setUp(() {
      // Use in-memory SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});
    });

    test('loadSettings returns defaults when nothing stored', () async {
      final service = SettingsServiceImpl();
      final result = await service.loadSettings();

      expect(result, isA<Ok<AppSettings>>());
      final settings = (result as Ok<AppSettings>).value;
      expect(settings.outputExt, '.cbz');
      expect(settings.preferPermanentDelete, false);
      expect(settings.skipCjxl, false);
      expect(settings.safeRun, false);
      expect(settings.cjxlPath, 'cjxl');
      expect(settings.lastPreset, ''); // empty when nothing stored
      expect(settings.lastRoot, isNull);
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.logLevel, LogLevel.none);
      expect(settings.postRunAction, PostRunAction.none);
      expect(settings.postRunConfirmEnabled, true);
      expect(settings.postRunConfirmSeconds, 60);
    });

    test('saveSettings and loadSettings round-trip', () async {
      final service = SettingsServiceImpl();

      final original = const AppSettings(
        outputExt: '.cbr',
        skipCjxl: true,
        safeRun: true,
        cjxlPath: '/usr/bin/cjxl',
        lastPreset: 'Lossy',
        lastRoot: r'C:\comics',
        themeMode: ThemeMode.dark,
        logLevel: LogLevel.error,
        postRunAction: PostRunAction.shutdown,
        postRunConfirmEnabled: false,
        postRunConfirmSeconds: 120,
        preferPermanentDelete: true,
      );

      final saveResult = await service.saveSettings(original);
      expect(saveResult, isA<Ok<void>>());

      final loadResult = await service.loadSettings();
      expect(loadResult, isA<Ok<AppSettings>>());
      final loaded = (loadResult as Ok<AppSettings>).value;

      expect(loaded.outputExt, original.outputExt);
      expect(loaded.skipCjxl, original.skipCjxl);
      expect(loaded.safeRun, original.safeRun);
      expect(loaded.cjxlPath, original.cjxlPath);
      expect(loaded.lastPreset, original.lastPreset);
      expect(loaded.lastRoot, original.lastRoot);
      expect(loaded.themeMode, original.themeMode);
      expect(loaded.logLevel, original.logLevel);
      expect(loaded.postRunAction, original.postRunAction);
      expect(loaded.postRunConfirmEnabled, original.postRunConfirmEnabled);
      expect(loaded.postRunConfirmSeconds, original.postRunConfirmSeconds);
      expect(loaded.preferPermanentDelete, original.preferPermanentDelete);
    });

    test('lastRoot null round-trips correctly', () async {
      final service = SettingsServiceImpl();

      // Save with a value
      await service.saveSettings(const AppSettings(lastRoot: r'C:\comics'));
      var loaded = (await service.loadSettings() as Ok<AppSettings>).value;
      expect(loaded.lastRoot, r'C:\comics');

      // Set back to null
      await service.saveSettings(const AppSettings(lastRoot: null));
      loaded = (await service.loadSettings() as Ok<AppSettings>).value;
      expect(loaded.lastRoot, isNull);
    });

    test('clearAll resets to defaults', () async {
      final service = SettingsServiceImpl();

      // First save some custom settings
      await service.saveSettings(
        const AppSettings(outputExt: '.zip', postRunConfirmSeconds: 30),
      );

      // Clear
      final clearResult = await service.clearAll();
      expect(clearResult, isA<Ok<void>>());

      // Load again — should be defaults
      final loadResult = await service.loadSettings();
      final settings = (loadResult as Ok<AppSettings>).value;
      expect(settings.outputExt, '.cbz');
      expect(settings.postRunConfirmSeconds, 60);
    });

    test('raw setters persist and appear in getAllRaw', () async {
      final service = SettingsServiceImpl();

      await service.setRawString('customKey', 'customValue');
      await service.setRawInt('count', 42);

      final all = service.getAllRaw();
      expect(all['customKey'], 'customValue');
      expect(all['count'], 42);
    });
  });
}
