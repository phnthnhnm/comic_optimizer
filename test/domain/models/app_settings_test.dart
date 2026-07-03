import 'package:comic_optimizer/domain/enums/log_level.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('default values are correct', () {
      const settings = AppSettings();
      expect(settings.preferPermanentDelete, false);
      expect(settings.outputExt, '.cbz');
      expect(settings.skipCjxl, false);
      expect(settings.safeRun, false);
      expect(settings.cjxlPath, 'cjxl');
      expect(settings.lastPreset, 'Lossless');
      expect(settings.lastRoot, isNull);
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.logLevel, LogLevel.none);
      expect(settings.postRunAction, PostRunAction.none);
      expect(settings.postRunConfirmEnabled, true);
      expect(settings.postRunConfirmSeconds, 60);
    });

    test('copyWith updates individual fields', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        outputExt: '.zip',
        preferPermanentDelete: true,
        postRunConfirmSeconds: 120,
      );
      expect(updated.outputExt, '.zip');
      expect(updated.preferPermanentDelete, true);
      expect(updated.postRunConfirmSeconds, 120);
      // Unchanged fields stay the same
      expect(updated.skipCjxl, false);
      expect(updated.cjxlPath, 'cjxl');
    });

    test('copyWith handles lastRoot null and non-null', () {
      const settings = AppSettings();
      final withRoot = settings.copyWith(lastRoot: 'C:\\comics');
      expect(withRoot.lastRoot, 'C:\\comics');

      final nulled = withRoot.copyWith(lastRoot: null);
      expect(nulled.lastRoot, isNull);
    });

    group('toJson / fromJson', () {
      test('round-trips with default values', () {
        const settings = AppSettings();
        final json = settings.toJson();
        final restored = AppSettings.fromJson(json);
        expect(restored.preferPermanentDelete, settings.preferPermanentDelete);
        expect(restored.outputExt, settings.outputExt);
        expect(restored.themeMode, settings.themeMode);
        expect(restored.logLevel, settings.logLevel);
        expect(restored.postRunAction, settings.postRunAction);
      });

      test('round-trips with custom values', () {
        final settings = AppSettings(
          outputExt: '.cbr',
          skipCjxl: true,
          postRunConfirmSeconds: 30,
          lastRoot: '/some/path',
        );
        final json = settings.toJson();
        final restored = AppSettings.fromJson(json);
        expect(restored.outputExt, '.cbr');
        expect(restored.skipCjxl, true);
        expect(restored.postRunConfirmSeconds, 30);
        expect(restored.lastRoot, '/some/path');
      });
    });
  });
}
