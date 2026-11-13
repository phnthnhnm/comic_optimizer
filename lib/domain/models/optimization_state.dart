import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/folder_run_status.dart';
import 'folder_run_result.dart';
import 'run_log_entry.dart';

part 'optimization_state.freezed.dart';

/// Runtime state of an optimization run.
///
/// User choices (preset, output format, flags, …) live in [AppSettings] and
/// are read from `settingsProvider` when a run starts, so the same value is
/// never stored twice.
@freezed
abstract class OptimizationState with _$OptimizationState {
  const factory OptimizationState({
    @Default(false) bool running,
    @Default(false) bool starting,
    @Default(false) bool paused,
    @Default(0) int rootsTotal,
    @Default(0) int rootsDone,
    String? currentRoot,
    @Default(<String>[]) List<String> libraries,
    @Default(0) int comicsTotal,
    @Default(0) int comicsDone,
    @Default(0) int imagesTotal,
    @Default(0) int imagesDone,
    String? currentFolder,
    String? currentFile,
    @Default(<String, List<RunLogEntry>>{}) Map<String, List<RunLogEntry>> logs,
    @Default(<String, FolderRunStatus>{}) Map<String, FolderRunStatus> folders,
    @Default(<String, FolderRunResult>{}) Map<String, FolderRunResult> results,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? currentLogFolder,
  }) = _OptimizationState;

  const OptimizationState._();
}
