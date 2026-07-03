import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod/riverpod.dart';

import 'package:comic_optimizer/core/result.dart';
import 'package:comic_optimizer/core/utils.dart';
import 'package:comic_optimizer/domain/enums/post_run_action.dart';
import 'package:comic_optimizer/domain/models/optimization_state.dart';
import 'package:comic_optimizer/domain/models/preset.dart';
import 'package:comic_optimizer/infrastructure/services/optimizer_service_impl.dart';
import 'package:comic_optimizer/features/settings/providers/settings_provider.dart';

final optimizationProvider =
    NotifierProvider<OptimizationNotifier, OptimizationState>(
      OptimizationNotifier.new,
    );

class OptimizationNotifier extends Notifier<OptimizationState> {
  OptimizerServiceImpl? _currentOptimizer;

  @override
  OptimizationState build() {
    // Load initial values from settings
    final settings = ref.read(settingsProvider);
    return OptimizationState(
      rootPath: settings.lastRoot,
      selectedPreset: settings.lastPreset.isNotEmpty
          ? settings.lastPreset
          : Preset.losslessName,
      outputExt: settings.outputExt,
      skipCjxl: settings.skipCjxl,
      preferPermanentDelete: settings.preferPermanentDelete,
      safeRun: settings.safeRun,
      postRunAction: settings.postRunAction,
      postRunConfirmEnabled: settings.postRunConfirmEnabled,
      postRunConfirmSeconds: settings.postRunConfirmSeconds,
    );
  }

  void _log(String line, {String? folder}) {
    final current = state;
    var logs = Map<String, List<String>>.from(current.logs);
    if (logs.isEmpty && current.logs.isEmpty) {
      // Handle initial state
    }
    final key = folder ?? current.currentLogFolder ?? 'General';
    logs.putIfAbsent(key, () => []).add(line);
    state = current.copyWith(logs: logs);
  }

  Future<void> pickRoot() async {
    final result = await FilePicker.getDirectoryPath();
    if (result != null) {
      state = state.copyWith(rootPath: result);
      _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    final s = state;
    final settings = ref.read(settingsProvider.notifier);
    if (s.rootPath != null) await settings.setLastRoot(s.rootPath);
    await settings.setLastPreset(s.selectedPreset);
    await settings.setSkipCjxl(s.skipCjxl);
    await settings.setPreferPermanentDelete(s.preferPermanentDelete);
    await settings.setSafeRun(s.safeRun);
    await settings.setOutputExt(s.outputExt);
    await settings.setPostRunAction(s.postRunAction);
    await settings.setPostRunConfirmEnabled(s.postRunConfirmEnabled);
    await settings.setPostRunConfirmSeconds(s.postRunConfirmSeconds);
  }

  Future<bool> confirmDialog(int seconds) async {
    // This needs a BuildContext, so we return false by default.
    // The actual dialog is shown in the UI layer via the provider's state.
    return false;
  }

  Future<void> start(BuildContext context) async {
    final s = state;
    if (s.rootPath == null) {
      _log('Please choose a root folder first.');
      return;
    }

    final preferPermanentDelete = s.preferPermanentDelete;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text(
          'This tool will modify and delete files. Back up your data before proceeding. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _saveSettings();

    state = state.copyWith(
      logs: {},
      currentLogFolder: null,
      running: true,
      starting: true,
      folderSizes: {},
    );

    final preset = Preset.byName(state.selectedPreset);
    final presetArgs = preset.args;

    final optimizer = OptimizerServiceImpl();
    _currentOptimizer = optimizer;

    try {
      final settings = ref.read(settingsProvider);
      final result = await optimizer.optimizeRoot(
        Directory(state.rootPath!),
        presetArgs: presetArgs,
        skipCjxl: state.skipCjxl,
        cjxlPath: settings.cjxlPath,
        safeRun: state.safeRun,
        outputExtension: state.outputExt,
        preferPermanentDelete: preferPermanentDelete,
        onLog: (msg) => _log(msg),
        onFolderStart: (f) {
          _log('Start: $f', folder: f);
          state = state.copyWith(currentLogFolder: f, starting: false);
        },
        onFolderDone: (f, ok, beforeBytes, afterBytes, perFileSizes) async {
          final folderSizes = Map<String, Map<String, int?>>.from(
            state.folderSizes,
          );
          folderSizes[f] = {'before': beforeBytes, 'after': afterBytes};

          var perFile = state.perFileSizes;
          if (perFileSizes != null) {
            perFile = Map<String, Map<String, Map<String, int?>>>.from(perFile);
            perFile[f] = perFileSizes.map(
              (k, v) => MapEntry(k, Map<String, int?>.from(v)),
            );
          }

          _log('Done: $f (${ok ? 'OK' : 'ERR'})', folder: f);
          state = state.copyWith(
            currentLogFolder: null,
            folderSizes: folderSizes,
            perFileSizes: perFile,
          );

          try {
            final name = p.basename(f);
            final summary = storageSummaryText(
              folderName: name,
              beforeBytes: beforeBytes,
              afterBytes: afterBytes,
              includeFolderName: false,
            );
            _log(summary, folder: f);
          } catch (_) {}
        },
      );

      if (result case Err(:final message)) {
        _log('Error: $message');
      } else {
        // Log storage summary
        if (state.folderSizes.isNotEmpty) {
          _log('Storage summary:');
          final folderSizes = state.folderSizes;
          folderSizes.forEach((folder, map) {
            final before = map['before'];
            final after = map['after'];
            final name = p.basename(folder);
            final summary = storageSummaryText(
              folderName: name,
              beforeBytes: before,
              afterBytes: after,
              includeFolderName: true,
            );
            _log(summary);
          });
          state = state.copyWith(currentLogFolder: 'General');
        } else {
          _log('All done.');
        }
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

  // Simple setters for UI bindings
  void setSelectedPreset(String? v) =>
      state = state.copyWith(selectedPreset: v ?? Preset.losslessName);

  void setSkipCjxl(bool? v) => state = state.copyWith(skipCjxl: v ?? false);

  void setPreferPermanentDelete(bool? v) =>
      state = state.copyWith(preferPermanentDelete: v ?? false);

  void setSafeRun(bool? v) => state = state.copyWith(safeRun: v ?? false);

  void setOutputExt(String? v) =>
      state = state.copyWith(outputExt: v ?? '.cbz');

  void setPostRunAction(PostRunAction? v) =>
      state = state.copyWith(postRunAction: v ?? PostRunAction.none);

  void setPostRunConfirmEnabled(bool? v) =>
      state = state.copyWith(postRunConfirmEnabled: v ?? true);

  void setPostRunConfirmSeconds(int? v) =>
      state = state.copyWith(postRunConfirmSeconds: v ?? 60);

  void addLog(String line) => _log(line);
}
