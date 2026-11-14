import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/custom_preset.dart';
import 'package:comic_optimizer/domain/models/library_entry.dart';
import 'package:comic_optimizer/infrastructure/services/settings_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsServiceImpl', () {
    late SharedPreferences prefs;

    setUp(() async {
      // Use in-memory SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('loadSettings returns defaults when nothing stored', () async {
      final service = SettingsServiceImpl(prefs);
      final result = await service.loadSettings();

      expect(result, isA<Ok<AppSettings>>());
      final settings = (result as Ok<AppSettings>).value;
      expect(settings.outputExt, '.cbz');
      expect(settings.preferPermanentDelete, false);
      expect(settings.skipCjxl, false);
      expect(settings.safeRun, true);
      expect(settings.deleteNonImageFiles, true);
      expect(settings.cjxlPath, 'cjxl');
      expect(settings.lastPreset, 'Lossless');
      expect(settings.lastRoot, isNull);
      expect(settings.libraries, isEmpty);
      expect(settings.customPresets, isEmpty);
      expect(settings.outputMode, OutputMode.besideSource);
      expect(settings.namingTemplate, '{folder}');
      expect(settings.collisionPolicy, CollisionPolicy.overwrite);
      expect(settings.skipExistingArchives, false);
      expect(settings.maxParallelEncodes, 2);
      expect(settings.preventSleep, true);
      expect(settings.postRunAction, PostRunAction.none);
      expect(settings.postRunConfirmEnabled, true);
      expect(settings.postRunConfirmSeconds, 60);
      expect(settings.tutorialCompleted, false);
      expect(settings.animationsEnabled, true);
    });

    test('saveSettings and loadSettings round-trip', () async {
      final service = SettingsServiceImpl(prefs);

      final original = const AppSettings(
        outputExt: '.cbr',
        skipCjxl: true,
        safeRun: true,
        deleteNonImageFiles: false,
        cjxlPath: '/usr/bin/cjxl',
        lastPreset: 'Lossy',
        lastRoot: r'C:\comics',
        libraries: [
          LibraryEntry(
            path: r'C:\comics',
            preset: 'Lossy',
            outputDirectory: r'D:\optimized',
            safeRunOverride: false,
          ),
          LibraryEntry(path: r'D:\manga'),
        ],
        customPresets: [
          CustomPreset(
            name: 'Archival',
            distance: 1.5,
            losslessJpeg: true,
            extraArgs: '--effort=7',
          ),
        ],
        postRunAction: PostRunAction.shutdown,
        postRunConfirmEnabled: false,
        postRunConfirmSeconds: 120,
        preferPermanentDelete: true,
        tutorialCompleted: true,
        animationsEnabled: false,
        outputMode: OutputMode.custom,
        outputDirectory: r'D:\optimized',
        namingTemplate: '{folder} ({preset})',
        collisionPolicy: CollisionPolicy.suffix,
        skipExistingArchives: true,
        maxParallelEncodes: 3,
        preventSleep: false,
      );

      final saveResult = await service.saveSettings(original);
      expect(saveResult, isA<Ok<void>>());

      final loadResult = await service.loadSettings();
      expect(loadResult, isA<Ok<AppSettings>>());
      final loaded = (loadResult as Ok<AppSettings>).value;

      expect(loaded.outputExt, '.cbz');
      expect(loaded.skipCjxl, original.skipCjxl);
      expect(loaded.safeRun, original.safeRun);
      expect(loaded.deleteNonImageFiles, original.deleteNonImageFiles);
      expect(loaded.cjxlPath, original.cjxlPath);
      expect(loaded.lastPreset, original.lastPreset);
      expect(loaded.lastRoot, original.lastRoot);
      expect(loaded.libraries, original.libraries);
      expect(loaded.customPresets, original.customPresets);
      expect(loaded.outputMode, original.outputMode);
      expect(loaded.outputDirectory, original.outputDirectory);
      expect(loaded.namingTemplate, original.namingTemplate);
      expect(loaded.collisionPolicy, original.collisionPolicy);
      expect(loaded.skipExistingArchives, original.skipExistingArchives);
      expect(loaded.maxParallelEncodes, original.maxParallelEncodes);
      expect(loaded.preventSleep, original.preventSleep);
      expect(loaded.postRunAction, original.postRunAction);
      expect(loaded.postRunConfirmEnabled, original.postRunConfirmEnabled);
      expect(loaded.postRunConfirmSeconds, original.postRunConfirmSeconds);
      expect(loaded.preferPermanentDelete, original.preferPermanentDelete);
      expect(loaded.tutorialCompleted, original.tutorialCompleted);
      expect(loaded.animationsEnabled, original.animationsEnabled);
    });

    test('lastRoot null round-trips correctly', () async {
      final service = SettingsServiceImpl(prefs);

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
      final service = SettingsServiceImpl(prefs);

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
      final service = SettingsServiceImpl(prefs);

      await service.setRawString('customKey', 'customValue');
      await service.setRawInt('count', 42);

      final all = service.getAllRaw();
      expect(all['customKey'], 'customValue');
      expect(all['count'], 42);
    });

    test('migrates the legacy lastRoot into the library queue', () async {
      SharedPreferences.setMockInitialValues({'lastRoot': r'C:\comics'});
      final migratedPrefs = await SharedPreferences.getInstance();
      final settings =
          (await SettingsServiceImpl(migratedPrefs).loadSettings()
                  as Ok<AppSettings>)
              .value;

      expect(settings.libraries.single.path, r'C:\comics');
    });

    test('migrates the legacy path list into structured libraries', () async {
      SharedPreferences.setMockInitialValues({
        'libraryRoots': [r'C:\comics', r'D:\manga'],
      });
      final migratedPrefs = await SharedPreferences.getInstance();
      final settings =
          (await SettingsServiceImpl(migratedPrefs).loadSettings()
                  as Ok<AppSettings>)
              .value;

      expect(settings.libraries.map((entry) => entry.path), [
        r'C:\comics',
        r'D:\manga',
      ]);
    });

    test('normalizes a legacy .cbr output preference to .cbz', () async {
      SharedPreferences.setMockInitialValues({'outputExt': '.cbr'});
      final migratedPrefs = await SharedPreferences.getInstance();
      final settings =
          (await SettingsServiceImpl(migratedPrefs).loadSettings()
                  as Ok<AppSettings>)
              .value;
      expect(settings.outputExt, '.cbz');
    });
  });
}
