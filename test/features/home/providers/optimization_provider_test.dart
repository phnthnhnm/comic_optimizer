import 'dart:io';

import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/core/providers/shared_preferences_provider.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/domain/enums/collision_policy.dart';
import 'package:comic_optimizer/domain/enums/output_mode.dart';
import 'package:comic_optimizer/domain/enums/folder_run_status.dart';
import 'package:comic_optimizer/domain/models/preflight_summary.dart';
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
    registerFallbackValue(OutputMode.besideSource);
    registerFallbackValue(CollisionPolicy.overwrite);
    registerFallbackValue(<String>{});
  });

  group('OptimizationNotifier', () {
    late ProviderContainer container;
    late MockOptimizerService mockOptimizer;
    late OptimizationNotifier notifier;
    late SettingsNotifier settings;

    void stubOptimizer({
      required Result<void> result,
      bool runCallbacks = false,
      bool folderSucceeded = true,
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
          presetName: any(named: 'presetName'),
          namingTemplate: any(named: 'namingTemplate'),
          globalOutputDirectory: any(named: 'globalOutputDirectory'),
          libraryOutputDirectory: any(named: 'libraryOutputDirectory'),
          outputMode: any(named: 'outputMode'),
          collisionPolicy: any(named: 'collisionPolicy'),
          skipExistingArchives: any(named: 'skipExistingArchives'),
          maxParallelEncodes: any(named: 'maxParallelEncodes'),
          completedFolders: any(named: 'completedFolders'),
          onLog: any(named: 'onLog'),
          onFolderStart: any(named: 'onFolderStart'),
          onFolderDone: any(named: 'onFolderDone'),
          onFileStart: any(named: 'onFileStart'),
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
                    String?,
                  );
          final onFile =
              invocation.namedArguments[#onFileStart]
                  as void Function(String, String, int, int)?;
          onStart('/tmp/comics/Comic A');
          onFile?.call(
            '/tmp/comics/Comic A',
            '/tmp/comics/Comic A/001.png',
            1,
            2,
          );
          onDone(
            '/tmp/comics/Comic A',
            folderSucceeded,
            1000,
            400,
            null,
            '/tmp/comics/Comic A.cbz',
          );
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
            (entry) => entry.message.contains('root folder'),
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
            presetName: Preset.lossyName,
            namingTemplate: '{folder}',
            globalOutputDirectory: '',
            libraryOutputDirectory: null,
            outputMode: OutputMode.besideSource,
            collisionPolicy: CollisionPolicy.overwrite,
            skipExistingArchives: false,
            maxParallelEncodes: 2,
            completedFolders: any(named: 'completedFolders'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
            onFileStart: any(named: 'onFileStart'),
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
            presetName: any(named: 'presetName'),
            namingTemplate: any(named: 'namingTemplate'),
            globalOutputDirectory: any(named: 'globalOutputDirectory'),
            libraryOutputDirectory: any(named: 'libraryOutputDirectory'),
            outputMode: any(named: 'outputMode'),
            collisionPolicy: any(named: 'collisionPolicy'),
            skipExistingArchives: any(named: 'skipExistingArchives'),
            maxParallelEncodes: any(named: 'maxParallelEncodes'),
            completedFolders: any(named: 'completedFolders'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
            onFileStart: any(named: 'onFileStart'),
          ),
        ).called(3);
        expect(notifier.state.rootsTotal, 3);
        expect(notifier.state.rootsDone, 3);
        expect(notifier.state.currentRoot, '/tmp/c');
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
            presetName: any(named: 'presetName'),
            namingTemplate: any(named: 'namingTemplate'),
            globalOutputDirectory: any(named: 'globalOutputDirectory'),
            libraryOutputDirectory: any(named: 'libraryOutputDirectory'),
            outputMode: any(named: 'outputMode'),
            collisionPolicy: any(named: 'collisionPolicy'),
            skipExistingArchives: any(named: 'skipExistingArchives'),
            maxParallelEncodes: any(named: 'maxParallelEncodes'),
            completedFolders: any(named: 'completedFolders'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
            onFileStart: any(named: 'onFileStart'),
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
            presetName: any(named: 'presetName'),
            namingTemplate: any(named: 'namingTemplate'),
            globalOutputDirectory: any(named: 'globalOutputDirectory'),
            libraryOutputDirectory: any(named: 'libraryOutputDirectory'),
            outputMode: any(named: 'outputMode'),
            collisionPolicy: any(named: 'collisionPolicy'),
            skipExistingArchives: any(named: 'skipExistingArchives'),
            maxParallelEncodes: any(named: 'maxParallelEncodes'),
            completedFolders: any(named: 'completedFolders'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
            onFileStart: any(named: 'onFileStart'),
          ),
        ).called(1);
        expect(notifier.state.rootsDone, 1);
        expect(notifier.state.running, false);
      });

      test('seeds queued folders from the preflight summary', () async {
        await settings.setLastRoot('/tmp/comics');
        stubOptimizer(result: const Ok<void>(null), runCallbacks: true);

        await notifier.start(
          summary: const PreflightSummary(
            roots: 1,
            comics: 2,
            images: 4,
            nonImageFiles: 0,
            folders: ['/tmp/comics/Comic A', '/tmp/comics/Comic B'],
          ),
        );

        expect(
          notifier.state.folders['/tmp/comics/Comic A'],
          FolderRunStatus.success,
        );
        expect(
          notifier.state.folders['/tmp/comics/Comic B'],
          FolderRunStatus.pending,
        );
        expect(notifier.state.comicsTotal, 2);
        expect(notifier.state.imagesTotal, 4);
      });

      test('folder callbacks populate per-folder logs', () async {
        await settings.setLastRoot('/tmp/comics');
        stubOptimizer(result: const Ok<void>(null), runCallbacks: true);

        await notifier.start();

        final logs = notifier.state.logs['/tmp/comics/Comic A']!;
        expect(
          logs.any((entry) => entry.message == 'Start: /tmp/comics/Comic A'),
          true,
        );
        expect(logs.any((entry) => entry.message.startsWith('Done:')), true);
        expect(logs.any((entry) => entry.message.contains('saved')), true);
        expect(notifier.state.currentLogFolder, 'General');
        expect(notifier.state.imagesDone, 1);
        expect(notifier.state.comicsDone, 1);
        expect(notifier.state.currentFile, isNull);
        expect(
          notifier.state.folders['/tmp/comics/Comic A'],
          FolderRunStatus.success,
        );
        final result = notifier.state.results['/tmp/comics/Comic A']!;
        expect(result.success, true);
        expect(result.root, '/tmp/comics');
        expect(result.beforeBytes, 1000);
        expect(result.afterBytes, 400);
      });

      test('logs errors returned by the optimizer', () async {
        await settings.setLastRoot('/tmp/comics');
        stubOptimizer(result: const Err<void>('boom'));

        await notifier.start();

        expect(
          notifier.state.logs['General']!.any(
            (entry) => entry.message.contains('Error: boom'),
          ),
          true,
        );
        expect(notifier.state.running, false);
      });

      test('retryFailed reruns the affected library', () async {
        await settings.setLastRoot('/tmp/comics');
        stubOptimizer(
          result: const Ok<void>(null),
          runCallbacks: true,
          folderSucceeded: false,
        );

        await notifier.start();
        expect(notifier.state.results['/tmp/comics/Comic A']!.success, false);

        await notifier.retryFailed();

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
            presetName: any(named: 'presetName'),
            namingTemplate: any(named: 'namingTemplate'),
            globalOutputDirectory: any(named: 'globalOutputDirectory'),
            libraryOutputDirectory: any(named: 'libraryOutputDirectory'),
            outputMode: any(named: 'outputMode'),
            collisionPolicy: any(named: 'collisionPolicy'),
            skipExistingArchives: any(named: 'skipExistingArchives'),
            maxParallelEncodes: any(named: 'maxParallelEncodes'),
            completedFolders: any(named: 'completedFolders'),
            onLog: any(named: 'onLog'),
            onFolderStart: any(named: 'onFolderStart'),
            onFolderDone: any(named: 'onFolderDone'),
            onFileStart: any(named: 'onFileStart'),
          ),
        ).called(2);
        expect(notifier.state.libraries, ['/tmp/comics']);
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
        expect(
          notifier.state.logs['General']!.any(
            (entry) => entry.message == 'test message',
          ),
          true,
        );
      });

      test('accumulates multiple lines', () {
        notifier.addLog('first');
        notifier.addLog('second');
        expect(notifier.state.logs['General']!.length, 2);
      });
    });
  });
}
