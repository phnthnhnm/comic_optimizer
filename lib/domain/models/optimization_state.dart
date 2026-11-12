import 'package:freezed_annotation/freezed_annotation.dart';

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
    @Default(<String, List<String>>{}) Map<String, List<String>> logs,
    String? currentLogFolder,
  }) = _OptimizationState;

  const OptimizationState._();
}
