import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/enums/post_run_action.dart';

part 'optimization_state.freezed.dart';

@freezed
abstract class OptimizationState with _$OptimizationState {
  const factory OptimizationState({
    String? rootPath,
    @Default('Lossless') String selectedPreset,
    @Default(false) bool skipCjxl,
    @Default(false) bool preferPermanentDelete,
    @Default(false) bool safeRun,
    @Default('.cbz') String outputExt,
    @Default(PostRunAction.none) PostRunAction postRunAction,
    @Default(true) bool postRunConfirmEnabled,
    @Default(60) int postRunConfirmSeconds,
    @Default(false) bool running,
    @Default(false) bool starting,
    @Default(false) bool paused,
    @Default(<String, List<String>>{}) Map<String, List<String>> logs,
    String? currentLogFolder,
    @Default(<String, Map<String, int?>>{})
    Map<String, Map<String, int?>> folderSizes,
    @Default(<String, Map<String, Map<String, int?>>>{})
    Map<String, Map<String, Map<String, int?>>> perFileSizes,
  }) = _OptimizationState;

  const OptimizationState._();
}
