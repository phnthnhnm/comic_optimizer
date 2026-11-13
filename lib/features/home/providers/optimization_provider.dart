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
import 'package:comic_optimizer/domain/models/optimization_state.dart';
import 'package:comic_optimizer/domain/models/preflight_summary.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/domain/models/run_log_entry.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';

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

  /// The queue, with a fallback to the legacy single `lastRoot`.
  List<String> _rootsToRun() {
    final settings = ref.read(settingsProvider);
    if (settings.libraryRoots.isNotEmpty) return settings.libraryRoots;
    final legacy = settings.lastRoot;
    return legacy == null ? const [] : [legacy];
  }

  Future<void> _waitIfPaused() async {
    if (!_paused) return;
    final completer = _pauseCompleter;
    if (completer != null) await completer.future;
  }

  Future<void> start({PreflightSummary? summary}) async {
    final settings = ref.read(settingsProvider);
    final roots = _rootsToRun();
    if (roots.isEmpty) {
      _log('Add at least one root folder to the library first.');
      return;
    }

    final preset = Preset.byName(settings.lastPreset);
    _cancelRequested = false;
    _paused = false;
    _pauseCompleter = null;

    state = state.copyWith(
      logs: {},
      folders: {
        for (final folder in summary?.folders ?? const <String>[])
          folder: FolderRunStatus.pending,
      },
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

    try {
      for (var index = 0; index < roots.length; index++) {
        await _waitIfPaused();
        if (_cancelRequested) {
          _log('Operation cancelled by user');
          break;
        }

        final root = roots[index];
        state = state.copyWith(currentRoot: root, starting: false);
        _log('Root: $root (${index + 1}/${roots.length})');

        final optimizer = ref.read(optimizerServiceProvider);
        _currentOptimizer = optimizer;

        final result = await optimizer.optimizeRoot(
          Directory(root),
          presetArgs: preset.args,
          skipCjxl: settings.skipCjxl,
          deleteNonImageFiles: settings.deleteNonImageFiles,
          cjxlPath: settings.cjxlPath,
          safeRun: settings.safeRun,
          outputExtension: settings.outputExt,
          preferPermanentDelete: settings.preferPermanentDelete,
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
          onFolderDone: (folder, ok, beforeBytes, afterBytes, _) {
            folderSizes[folder] = {'before': beforeBytes, 'after': afterBytes};
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
