import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/core/providers/shared_preferences_provider.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/home/providers/optimization_provider.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
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
    late SettingsNotifier settings;

    void stubOptimizer({
      required Result<void> result,
      bool runCallbacks = false,
    }) {
      when(
        () => mockOptimizer.optimizeRoot(
          any(),
          presetArgs: any(named: 'presetArgs'),
          skipCjxl: any(named: 'skipCjxl'),
          deleteNonImageFiles: any(named: 'deleteNonImageFiles'),
          cjxlPath: any(named: 'cjxlPath'),
          safeRun: any(named: 'safeRun'),
          outputExtension: any(named: 'outputExtension'),
          preferPermanentDelete: any(named: 'preferPermanentDelete'),
          onLog: any(named: 'onLog'),
          onFolderStart: any(named: 'onFolderStart'),
          onFolderDone: any(named: 'onFolderDone'),
        ),
      ).thenAnswer((invocation) async {
        if (runCallbacks) {
          final onStart =
              invocation.namedArguments[#onFolderStart]
                  as void Function(String);
          final onDone =
              invocation.namedArguments[#onFolderDone]
                  as void Function(
                    String,
                    bool,
                    int?,
                    int?,
                    Map<String, Map<String, int?>>?,
                  );
          onStart('/tmp/comics/Comic A');
          onDone('/tmp/comics/Comic A', true, 1000, 400, null);
        }
        return result;
      });
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      mockOptimizer = MockOptimizerService();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          optimizerServiceProvider.overrideWithValue(mockOptimizer),
        ],
      );
      notifier = container.read(optimizationProvider.notifier);
      settings = container.read(settingsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('initial state', () {
      test('is idle with no logs', () {
        expect(notifier.state.running, false);
        expect(notifier.state.starting, false);
        expect(notifier.state.paused, false);
        expect(notifier.state.logs, isEmpty);
        expect(notifier.state.currentLogFolder, isNull);
      });
    });

    group('start', () {
      test('without a root logs a hint and does not run', () async {
        await notifier.start();

        expect(notifier.state.running, false);
        expect(
          notifier.state.logs['General']!.any(
            (line) => line.contains('root folder'),
          ),
          true,
        );
      });

      test('forwards the persisted settings to the optimizer', () async {
        await settings.setLastRoot('/tmp/comics');
        await settings.setLastPreset(Preset.lossyName);
        await settings.setSkipCjxl(true);
        await settings.setOutputExt('.zip');
        await settings.setSafeRun(true);
        await settings.setPreferPermanentDelete(true);
        stubOptimizer(result: const Ok<void>(null));

        await notifier.start();

        verify(
          () => mockOptimizer.optimizeRoot(
            any(),
            presetArgs: Preset.lossy.args,
            skipCjxl: true,
            deleteNonImageFiles: true,
            cjxlPath: 'cjxl',
            safeRun: true,
            outputExtension: '.zip',
            preferPermanentDelete: true,
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
          ),
        ).called(1);
        expect(notifier.state.running, false);
        expect(notifier.state.paused, false);
      });

      test('iterates the whole library queue', () async {
        await settings.setLibraryRoots(['/tmp/a', '/tmp/b', '/tmp/c']);
        stubOptimizer(result: const Ok<void>(null));

        await notifier.start();

        verify(
          () => mockOptimizer.optimizeRoot(
            any(),
            presetArgs: any(named: 'presetArgs'),
            skipCjxl: any(named: 'skipCjxl'),
            deleteNonImageFiles: any(named: 'deleteNonImageFiles'),
            cjxlPath: any(named: 'cjxlPath'),
            safeRun: any(named: 'safeRun'),
            outputExtension: any(named: 'outputExtension'),
            preferPermanentDelete: any(named: 'preferPermanentDelete'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
          ),
        ).called(3);
        expect(notifier.state.rootsTotal, 3);
        expect(notifier.state.rootsDone, 3);
        expect(notifier.state.currentRoot, isNull);
        expect(notifier.state.running, false);
      });

      test('cancelling after the current root stops the queue', () async {
        await settings.setLibraryRoots(['/tmp/a', '/tmp/b']);
        when(
          () => mockOptimizer.optimizeRoot(
            any(),
            presetArgs: any(named: 'presetArgs'),
            skipCjxl: any(named: 'skipCjxl'),
            deleteNonImageFiles: any(named: 'deleteNonImageFiles'),
            cjxlPath: any(named: 'cjxlPath'),
            safeRun: any(named: 'safeRun'),
            outputExtension: any(named: 'outputExtension'),
            preferPermanentDelete: any(named: 'preferPermanentDelete'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
          ),
        ).thenAnswer((_) async {
          notifier.cancel();
          return const Ok<void>(null);
        });

        await notifier.start();

        verify(
          () => mockOptimizer.optimizeRoot(
            any(),
            presetArgs: any(named: 'presetArgs'),
            skipCjxl: any(named: 'skipCjxl'),
            deleteNonImageFiles: any(named: 'deleteNonImageFiles'),
            cjxlPath: any(named: 'cjxlPath'),
            safeRun: any(named: 'safeRun'),
            outputExtension: any(named: 'outputExtension'),
            preferPermanentDelete: any(named: 'preferPermanentDelete'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
          ),
        ).called(1);
        expect(notifier.state.rootsDone, 1);
        expect(notifier.state.running, false);
      });

      test('folder callbacks populate per-folder logs', () async {
        await settings.setLastRoot('/tmp/comics');
        stubOptimizer(result: const Ok<void>(null), runCallbacks: true);

        await notifier.start();

        final logs = notifier.state.logs['/tmp/comics/Comic A']!;
        expect(logs, contains('Start: /tmp/comics/Comic A'));
        expect(logs.any((line) => line.startsWith('Done:')), true);
        expect(logs.any((line) => line.contains('saved')), true);
        expect(notifier.state.currentLogFolder, 'General');
      });

      test('logs errors returned by the optimizer', () async {
        await settings.setLastRoot('/tmp/comics');
        stubOptimizer(result: const Err<void>('boom'));

        await notifier.start();

        expect(
          notifier.state.logs['General']!.any(
            (line) => line.contains('Error: boom'),
          ),
          true,
        );
        expect(notifier.state.running, false);
      });
    });

    group('run controls', () {
      test('pause and resume toggle the paused flag', () {
        notifier.pause();
        expect(notifier.state.paused, true);

        notifier.resume();
        expect(notifier.state.paused, false);
      });

      test('cancel clears the paused flag', () {
        notifier.pause();
        notifier.cancel();
        expect(notifier.state.paused, false);
      });

      test('controls do not throw without an active optimizer', () {
        expect(() => notifier.cancel(), returnsNormally);
        expect(() => notifier.pause(), returnsNormally);
        expect(() => notifier.resume(), returnsNormally);
      });
    });

    group('addLog', () {
      test('adds a line under General when no folder is active', () {
        notifier.addLog('test message');
        expect(notifier.state.logs['General'], contains('test message'));
      });

      test('accumulates multiple lines', () {
        notifier.addLog('first');
        notifier.addLog('second');
        expect(notifier.state.logs['General']!.length, 2);
      });
    });
  });
}
