import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';

import 'package:comic_optimizer/core/interfaces/i_optimizer_service.dart';
import 'package:comic_optimizer/core/providers/service_providers.dart';
import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/models/optimization_state.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';

final optimizationProvider =
    NotifierProvider<OptimizationNotifier, OptimizationState>(
      OptimizationNotifier.new,
    );

/// Drives a single optimization run and keeps its progress and logs.
///
/// Every input comes from `settingsProvider`; this notifier never keeps its
/// own copy of a user setting.
class OptimizationNotifier extends Notifier<OptimizationState> {
  IOptimizerService? _currentOptimizer;

  @override
  OptimizationState build() => const OptimizationState();

  void _log(String line, {String? folder}) {
    final current = state;
    final logs = Map<String, List<String>>.from(current.logs);
    final key = folder ?? current.currentLogFolder ?? 'General';
    logs.putIfAbsent(key, () => []).add(line);
    state = current.copyWith(logs: logs);
  }

  Future<void> start() async {
    final settings = ref.read(settingsProvider);
    final rootPath = settings.lastRoot;
    if (rootPath == null) {
      _log('Please choose a root folder first.');
      return;
    }

    final preset = Preset.byName(settings.lastPreset);

    state = state.copyWith(
      logs: {},
      currentLogFolder: null,
      running: true,
      starting: true,
    );

    final optimizer = ref.read(optimizerServiceProvider);
    _currentOptimizer = optimizer;

    // Kept local: it only feeds the end-of-run summary.
    final folderSizes = <String, Map<String, int?>>{};

    try {
      final result = await optimizer.optimizeRoot(
        Directory(rootPath),
        presetArgs: preset.args,
        skipCjxl: settings.skipCjxl,
        deleteNonImageFiles: settings.deleteNonImageFiles,
        cjxlPath: settings.cjxlPath,
        safeRun: settings.safeRun,
        outputExtension: settings.outputExt,
        preferPermanentDelete: settings.preferPermanentDelete,
        onLog: (msg) => _log(msg),
        onFolderStart: (folder) {
          _log('Start: $folder', folder: folder);
          state = state.copyWith(currentLogFolder: folder, starting: false);
        },
        onFolderDone: (folder, ok, beforeBytes, afterBytes, _) {
          folderSizes[folder] = {'before': beforeBytes, 'after': afterBytes};
          _log('Done: $folder (${ok ? 'OK' : 'ERR'})', folder: folder);
          state = state.copyWith(currentLogFolder: null);
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
      } else if (folderSizes.isNotEmpty) {
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
      } else {
        _log('All done.');
      }
    } catch (e, st) {
      _log('Error: $e');
      _log(st.toString());
    } finally {
      state = state.copyWith(running: false, starting: false, paused: false);
      _currentOptimizer = null;
    }
  }

  void cancel() {
    _currentOptimizer?.cancel();
    state = state.copyWith(paused: false);
  }

  void pause() {
    _currentOptimizer?.pause();
    state = state.copyWith(paused: true);
  }

  void resume() {
    _currentOptimizer?.resume();
    state = state.copyWith(paused: false);
  }

  void addLog(String line) => _log(line);
}
