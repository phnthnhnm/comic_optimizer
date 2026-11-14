import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';

import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/enums/folder_run_status.dart';
import 'package:comic_optimizer/domain/enums/run_log_level.dart';
import 'package:comic_optimizer/domain/models/app_settings.dart';
import 'package:comic_optimizer/domain/models/folder_run_result.dart';
import 'package:comic_optimizer/domain/models/optimization_state.dart';
import 'package:comic_optimizer/domain/models/preflight_summary.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/domain/models/run_log_entry.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';
import 'package:comic_optimizer/infrastructure/services/run_journal_store.dart';

final optimizationProvider =
    NotifierProvider<OptimizationNotifier, OptimizationState>(
      OptimizationNotifier.new,
    );

/// Drives a run over the library queue and keeps its progress and logs.
///
/// Every input comes from `settingsProvider`; this notifier never keeps its
/// own copy of a user setting.
class OptimizationNotifier extends Notifier<OptimizationState> {
  IOptimizerService? _currentOptimizer;
  bool _cancelRequested = false;
  bool _paused = false;
  Completer<void>? _pauseCompleter;

  @override
  OptimizationState build() => const OptimizationState();

  void _log(String line, {String? folder, RunLogLevel? level}) {
    final current = state;
    final logs = Map<String, List<RunLogEntry>>.from(current.logs);
    final key = folder ?? current.currentLogFolder ?? 'General';
    logs
        .putIfAbsent(key, () => [])
        .add(
          RunLogEntry(
            line,
            level ?? RunLogLevelX.fromLine(line),
            DateTime.now(),
          ),
        );
    state = current.copyWith(logs: logs);
  }

  String? _lastError(String folder) {
    final entries = state.logs[folder];
    if (entries == null) return null;
    for (var i = entries.length - 1; i >= 0; i--) {
      if (entries[i].level == RunLogLevel.error) return entries[i].message;
    }
    return null;
  }

  /// The queue, with a fallback to the legacy single `lastRoot`.
  List<String> _rootsToRun() {
    final settings = ref.read(settingsProvider);
    if (settings.libraries.isNotEmpty) {
      return settings.libraries.map((entry) => entry.path).toList();
    }
    final legacy = settings.lastRoot;
    return legacy == null ? const [] : [legacy];
  }

  Future<void> _waitIfPaused() async {
    if (!_paused) return;
    final completer = _pauseCompleter;
    if (completer != null) await completer.future;
  }

  Future<void> start({
    PreflightSummary? summary,
    List<String>? rootsOverride,
  }) async {
    final settings = ref.read(settingsProvider);
    final roots = rootsOverride ?? _rootsToRun();
    if (roots.isEmpty) {
      _log('Add at least one root folder to the library first.');
      return;
    }

    final sleepInhibitor = ref.read(sleepInhibitorProvider);
    if (settings.preventSleep) sleepInhibitor.inhibit();

    final journalStore = ref.read(runJournalStoreProvider);
    final fingerprint = _runFingerprint(settings, roots);
    var journal = journalStore.read();
    if (journal != null && journal.fingerprint != fingerprint) {
      await journalStore.clear();
      journal = null;
      _log('Previous run settings changed; starting a fresh journal.');
    }
    if (journal == null) {
      journal = RunJournal(
        fingerprint: fingerprint,
        completed: const {},
        updatedAt: DateTime.now(),
      );
      await journalStore.write(journal);
    }
    final completed = Set<String>.from(journal.completed);
    var journalWrite = Future<void>.value();

    _cancelRequested = false;
    _paused = false;
    _pauseCompleter = null;

    state = state.copyWith(
      logs: {},
      folders: {
        for (final folder in summary?.folders ?? const <String>[])
          folder: FolderRunStatus.pending,
      },
      results: {},
      libraries: roots,
      currentLogFolder: null,
      currentRoot: null,
      currentFolder: null,
      currentFile: null,
      running: true,
      starting: true,
      rootsTotal: roots.length,
      rootsDone: 0,
      comicsTotal: summary?.comics ?? 0,
      comicsDone: 0,
      imagesTotal: summary?.images ?? 0,
      imagesDone: 0,
      startedAt: DateTime.now(),
      finishedAt: null,
    );

    // Kept local: it only feeds the end-of-run summary.
    final folderSizes = <String, Map<String, int?>>{};
    var hadErrors = false;
    if (completed.isNotEmpty) {
      _log('Resuming: ${completed.length} completed comics will be skipped.');
    }

    try {
      for (var index = 0; index < roots.length; index++) {
        await _waitIfPaused();
        if (_cancelRequested) {
          _log('Operation cancelled by user');
          break;
        }

        final root = roots[index];
        final matching = settings.libraries
            .where((entry) => entry.path == root)
            .toList();
        final library = matching.isEmpty ? null : matching.first;
        final presetName = library?.preset ?? settings.lastPreset;
        final rootPreset = Preset.resolve(presetName, settings.customPresets);
        final rootSafeRun = library?.safeRunOverride ?? settings.safeRun;
        state = state.copyWith(currentRoot: root, starting: false);
        _log('Root: $root (${index + 1}/${roots.length})');

        final optimizer = ref.read(optimizerServiceProvider);
        _currentOptimizer = optimizer;

        final result = await optimizer.optimizeRoot(
          Directory(root),
          presetArgs: rootPreset.args,
          skipCjxl: settings.skipCjxl,
          deleteNonImageFiles: settings.deleteNonImageFiles,
          cjxlPath: settings.cjxlPath,
          safeRun: rootSafeRun,
          outputExtension: settings.outputExt,
          preferPermanentDelete: settings.preferPermanentDelete,
          presetName: rootPreset.name,
          namingTemplate: settings.namingTemplate,
          globalOutputDirectory: settings.outputDirectory,
          libraryOutputDirectory: library?.outputDirectory,
          outputMode: settings.outputMode,
          collisionPolicy: settings.collisionPolicy,
          skipExistingArchives: settings.skipExistingArchives,
          maxParallelEncodes: settings.maxParallelEncodes,
          completedFolders: completed,
          onLog: (msg) => _log(msg),
          onFileStart: (folder, file, index, total) {
            state = state.copyWith(
              currentFolder: folder,
              currentFile: p.basename(file),
              imagesDone: state.imagesDone + 1,
            );
          },
          onFolderStart: (folder) {
            _log('Start: $folder', folder: folder);
            state = state.copyWith(
              currentLogFolder: folder,
              currentFolder: folder,
              currentFile: null,
              starting: false,
              folders: {...state.folders, folder: FolderRunStatus.running},
            );
          },
          onFolderDone: (folder, ok, beforeBytes, afterBytes, _, archivePath) {
            folderSizes[folder] = {'before': beforeBytes, 'after': afterBytes};
            final error = ok ? null : _lastError(folder);
            if (!ok) hadErrors = true;
            if (ok) {
              completed.add(folder);
              journalWrite = journalWrite.then(
                (_) => journalStore.write(
                  RunJournal(
                    fingerprint: fingerprint,
                    completed: Set<String>.from(completed),
                    updatedAt: DateTime.now(),
                  ),
                ),
              );
            }
            _log('Done: $folder (${ok ? 'OK' : 'ERR'})', folder: folder);
            state = state.copyWith(
              currentLogFolder: null,
              currentFolder: null,
              currentFile: null,
              comicsDone: state.comicsDone + 1,
              folders: {
                ...state.folders,
                folder: ok ? FolderRunStatus.success : FolderRunStatus.failed,
              },
              results: {
                ...state.results,
                folder: FolderRunResult(
                  path: folder,
                  root: state.currentRoot ?? '',
                  success: ok,
                  beforeBytes: beforeBytes,
                  afterBytes: afterBytes,
                  error: error,
                  archivePath: archivePath,
                ),
              },
            );
            _log(
              storageSummaryText(
                folderName: p.basename(folder),
                beforeBytes: beforeBytes,
                afterBytes: afterBytes,
                includeFolderName: false,
              ),
              folder: folder,
            );
          },
        );

        if (result case Err(:final message)) {
          _log('Error: $message');
          hadErrors = true;
        }
        state = state.copyWith(rootsDone: index + 1);
      }

      if (folderSizes.isNotEmpty) {
        _log('Storage summary:');
        folderSizes.forEach((folder, sizes) {
          _log(
            storageSummaryText(
              folderName: p.basename(folder),
              beforeBytes: sizes['before'],
              afterBytes: sizes['after'],
              includeFolderName: true,
            ),
          );
        });
        state = state.copyWith(currentLogFolder: 'General');
      } else if (!_cancelRequested) {
        _log(hadErrors ? 'Finished with errors.' : 'All done.');
      }
      if (!_cancelRequested && !hadErrors) {
        await journalWrite;
        await journalStore.clear();
      }
    } catch (e, st) {
      _log('Error: $e');
      _log(st.toString());
    } finally {
      state = state.copyWith(
        running: false,
        starting: false,
        paused: false,
        currentFolder: null,
        currentFile: null,
        finishedAt: DateTime.now(),
      );
      _currentOptimizer = null;
      if (settings.preventSleep) sleepInhibitor.release();
    }
  }

  /// Clears the finished run so the library can start another one.
  void reset() {
    _currentOptimizer = null;
    _cancelRequested = false;
    _paused = false;
    _pauseCompleter = null;
    state = const OptimizationState();
  }

  /// Re-runs the libraries that contain failed comics.
  Future<void> retryFailed() async {
    final failures = state.results.values.where((r) => !r.success).toList();
    if (failures.isEmpty) return;
    final roots = failures
        .map((r) => r.root)
        .where((root) => root.isNotEmpty)
        .toSet()
        .toList();
    if (roots.isEmpty) return;

    await start(
      summary: PreflightSummary(
        roots: roots.length,
        comics: failures.length,
        images: 0,
        nonImageFiles: 0,
        folders: failures.map((r) => r.path).toList(),
      ),
      rootsOverride: roots,
    );
  }

  void cancel() {
    _cancelRequested = true;
    _currentOptimizer?.cancel();
    if (_paused) {
      _paused = false;
      try {
        _pauseCompleter?.complete();
      } catch (_) {}
      _pauseCompleter = null;
    }
    state = state.copyWith(paused: false);
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _pauseCompleter = Completer<void>();
    _currentOptimizer?.pause();
    state = state.copyWith(paused: true);
  }

  void resume() {
    if (!_paused) {
      _currentOptimizer?.resume();
      state = state.copyWith(paused: false);
      return;
    }
    _paused = false;
    try {
      _pauseCompleter?.complete();
    } catch (_) {}
    _pauseCompleter = null;
    _currentOptimizer?.resume();
    state = state.copyWith(paused: false);
  }

  void addLog(String line) => _log(line);
}

String _runFingerprint(AppSettings settings, List<String> roots) {
  final buffer = StringBuffer()
    ..write('run-journal-v1|')
    ..write(settings.outputExt)
    ..write('|')
    ..write(settings.skipCjxl)
    ..write('|')
    ..write(settings.deleteNonImageFiles)
    ..write('|')
    ..write(settings.cjxlPath)
    ..write('|')
    ..write(settings.safeRun)
    ..write('|')
    ..write(settings.preferPermanentDelete)
    ..write('|')
    ..write(settings.outputMode.name)
    ..write('|')
    ..write(settings.outputDirectory)
    ..write('|')
    ..write(settings.namingTemplate)
    ..write('|')
    ..write(settings.collisionPolicy.name)
    ..write('|')
    ..write(settings.lastPreset)
    ..write('|')
    ..write(roots.join('\\u0000'));
  for (final entry in settings.libraries) {
    buffer
      ..write('|')
      ..write(entry.path)
      ..write('\\u0001')
      ..write(entry.preset)
      ..write('\\u0001')
      ..write(entry.outputDirectory)
      ..write('\\u0001')
      ..write(entry.safeRunOverride);
  }
  for (final preset in settings.customPresets) {
    buffer
      ..write('|')
      ..write(preset.name)
      ..write('\\u0001')
      ..write(preset.args.join(','));
  }
  var hash = 0x811c9dc5;
  for (final unit in buffer.toString().codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
