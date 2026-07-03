import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/providers/shared_preferences_provider.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockOptimizerService extends Mock implements IOptimizerService {}

class FakeDirectory extends Fake implements Directory {}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDirectory());
  });

  group('OptimizationNotifier', () {
    late ProviderContainer container;
    late MockOptimizerService mockOptimizer;
    late OptimizationNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      mockOptimizer = MockOptimizerService();
      notifier = container.read(optimizationProvider.notifier);
      notifier.createOptimizer = () => mockOptimizer;
      notifier.onConfirmStart = () async => true;
    });

    tearDown(() {
      container.dispose();
    });

    group('initial state', () {
      test('running is false, paused is false', () {
        expect(notifier.state.running, false);
        expect(notifier.state.paused, false);
        expect(notifier.state.starting, false);
      });

      test('selectedPreset defaults to Lossless', () {
        expect(notifier.state.selectedPreset, Preset.losslessName);
      });

      test('outputExt defaults to .cbz', () {
        expect(notifier.state.outputExt, '.cbz');
      });

      test('postRunAction defaults to none', () {
        expect(notifier.state.postRunAction, PostRunAction.none);
      });
    });

    group('setters', () {
      test('setSelectedPreset updates state', () {
        notifier.setSelectedPreset('Lossy');
        expect(notifier.state.selectedPreset, 'Lossy');
      });

      test('setSelectedPreset with null defaults to Lossless', () {
        notifier.setSelectedPreset(null);
        expect(notifier.state.selectedPreset, Preset.losslessName);
      });

      test('setSkipCjxl toggles', () {
        notifier.setSkipCjxl(true);
        expect(notifier.state.skipCjxl, true);
        notifier.setSkipCjxl(false);
        expect(notifier.state.skipCjxl, false);
      });

      test('setSkipCjxl with null defaults to false', () {
        notifier.setSkipCjxl(null);
        expect(notifier.state.skipCjxl, false);
      });

      test('setPreferPermanentDelete toggles', () {
        notifier.setPreferPermanentDelete(true);
        expect(notifier.state.preferPermanentDelete, true);
      });

      test('setSafeRun toggles', () {
        notifier.setSafeRun(true);
        expect(notifier.state.safeRun, true);
      });

      test('setOutputExt updates', () {
        notifier.setOutputExt('.zip');
        expect(notifier.state.outputExt, '.zip');
        notifier.setOutputExt(null);
        expect(notifier.state.outputExt, '.cbz');
      });

      test('setPostRunAction updates', () {
        notifier.setPostRunAction(PostRunAction.shutdown);
        expect(notifier.state.postRunAction, PostRunAction.shutdown);
      });

      test('setPostRunAction with null defaults to none', () {
        notifier.setPostRunAction(PostRunAction.quit);
        notifier.setPostRunAction(null);
        expect(notifier.state.postRunAction, PostRunAction.none);
      });

      test('setPostRunConfirmEnabled toggles', () {
        notifier.setPostRunConfirmEnabled(false);
        expect(notifier.state.postRunConfirmEnabled, false);
      });

      test('setPostRunConfirmSeconds updates', () {
        notifier.setPostRunConfirmSeconds(120);
        expect(notifier.state.postRunConfirmSeconds, 120);
        notifier.setPostRunConfirmSeconds(null);
        expect(notifier.state.postRunConfirmSeconds, 60);
      });
    });

    group('state transitions', () {
      test('cancel sets paused to false', () {
        notifier.cancel();
        expect(notifier.state.paused, false);
      });

      test('pause sets paused to true', () {
        notifier.pause();
        expect(notifier.state.paused, true);
      });

      test('resume sets paused to false', () {
        notifier.pause();
        expect(notifier.state.paused, true);
        notifier.resume();
        expect(notifier.state.paused, false);
      });
    });

    group('addLog', () {
      test('adds a log line under General when no folder selected', () {
        notifier.addLog('test message');
        expect(notifier.state.logs['General'], contains('test message'));
      });

      test('accumulates multiple log lines', () {
        notifier.addLog('first');
        notifier.addLog('second');
        expect(notifier.state.logs['General']!.length, greaterThan(1));
      });
    });

    group('start confirmation behaviour', () {
      test(
        'start with onConfirmStart returning false does not set running',
        () async {
          notifier.onConfirmStart = () async => false;
          notifier.state = notifier.state.copyWith(rootPath: '/tmp');

          await notifier.start(null);

          expect(notifier.state.running, false);
        },
      );

      test(
        'start with onConfirmStart returning true invokes optimizer',
        () async {
          when(
            () => mockOptimizer.optimizeRoot(
              any(),
              presetArgs: any(named: 'presetArgs'),
              skipCjxl: any(named: 'skipCjxl'),
              cjxlPath: any(named: 'cjxlPath'),
              safeRun: any(named: 'safeRun'),
              outputExtension: any(named: 'outputExtension'),
              preferPermanentDelete: any(named: 'preferPermanentDelete'),
              onLog: any(named: 'onLog'),
              onFolderStart: any(named: 'onFolderStart'),
              onFolderDone: any(named: 'onFolderDone'),
            ),
          ).thenAnswer((_) async => const Ok<void>(null));

          notifier.state = notifier.state.copyWith(rootPath: '/tmp');

          await notifier.start(null);

          // State cleaned up by finally block
          expect(notifier.state.running, false);
          expect(notifier.state.paused, false);
          expect(notifier.state.starting, false);
        },
      );

      test(
        'start with null rootPath logs and returns without running',
        () async {
          await notifier.start(null);

          expect(notifier.state.running, false);
          expect(
            notifier.state.logs['General']!.any(
              (l) => l.contains('root folder'),
            ),
            true,
          );
        },
      );

      test('cancel does not throw when no optimizer is active', () {
        expect(() => notifier.cancel(), returnsNormally);
      });

      test('pause does not throw when no optimizer is active', () {
        expect(() => notifier.pause(), returnsNormally);
        expect(notifier.state.paused, true);
      });

      test('resume does not throw when no optimizer is active', () {
        notifier.pause();
        expect(() => notifier.resume(), returnsNormally);
        expect(notifier.state.paused, false);
      });
    });
  });
}
