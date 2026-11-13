import 'package:comic_optimizer/core/providers/shared_preferences_provider.dart';
import 'package:comic_optimizer/domain/models/custom_preset.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsNotifier', () {
    late ProviderContainer container;
    late SharedPreferences prefs;
    late SettingsNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      notifier = container.read(settingsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with the AppSettings defaults', () {
      final settings = container.read(settingsProvider);
      expect(settings.outputExt, '.cbz');
      expect(settings.lastPreset, 'Lossless');
      expect(settings.cjxlPath, 'cjxl');
      expect(settings.safeRun, true);
      expect(settings.deleteNonImageFiles, true);
      expect(settings.libraryRoots, isEmpty);
    });

    test('load reads values persisted by the service', () async {
      await notifier.setOutputExt('.zip');
      await notifier.setLastRoot(r'C:\comics');

      // A fresh container resolves a new service over the same preferences.
      final second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      await second.read(settingsProvider.notifier).load();

      final loaded = second.read(settingsProvider);
      expect(loaded.outputExt, '.zip');
      expect(loaded.lastRoot, r'C:\comics');
      expect(loaded.lastPreset, 'Lossless');
    });

    test('setters update state and persist immediately', () async {
      await notifier.setSkipCjxl(true);
      expect(container.read(settingsProvider).skipCjxl, true);
      expect(prefs.getBool('skipCjxl'), true);

      await notifier.setCjxlPath(r'C:\tools\cjxl.exe');
      expect(container.read(settingsProvider).cjxlPath, r'C:\tools\cjxl.exe');
      expect(prefs.getString('cjxlPath'), r'C:\tools\cjxl.exe');
    });

    test('clearAllPrefs resets the state to defaults', () async {
      await notifier.setSafeRun(false);
      await notifier.clearAllPrefs();

      expect(container.read(settingsProvider).safeRun, true);
      expect(prefs.getBool('safeRun'), isNull);
    });

    test('library roots are added once and can be removed', () async {
      await notifier.addLibraryRoot(r'C:\comics');
      await notifier.addLibraryRoot(r'C:\comics');
      await notifier.addLibraryRoot(r'D:\manga');

      expect(container.read(settingsProvider).libraryRoots, [
        r'C:\comics',
        r'D:\manga',
      ]);
      expect(prefs.getStringList('libraryRoots'), [r'C:\comics', r'D:\manga']);

      await notifier.removeLibraryRoot(r'C:\comics');
      expect(container.read(settingsProvider).libraryRoots, [r'D:\manga']);
    });

    test('custom presets can be saved, renamed and removed', () async {
      const preset = CustomPreset(name: 'Mine', distance: 2.0);
      await notifier.saveCustomPreset(preset);

      expect(container.read(settingsProvider).customPresets, [preset]);
      expect(prefs.getString('customPresets'), contains('Mine'));

      await notifier.setLastPreset('Mine');
      const renamed = CustomPreset(name: 'Renamed', distance: 3.0);
      await notifier.saveCustomPreset(renamed, previousName: 'Mine');

      expect(container.read(settingsProvider).customPresets, [renamed]);
      expect(container.read(settingsProvider).lastPreset, 'Renamed');

      await notifier.removeCustomPreset('Renamed');
      expect(container.read(settingsProvider).customPresets, isEmpty);
      expect(container.read(settingsProvider).lastPreset, 'Lossless');
    });
  });
}
