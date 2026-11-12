import 'package:comic_optimizer/core/providers/shared_preferences_provider.dart';
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
      await notifier.setSafeRun(true);
      await notifier.clearAllPrefs();

      expect(container.read(settingsProvider).safeRun, false);
      expect(prefs.getBool('safeRun'), isNull);
    });
  });
}
