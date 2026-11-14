import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/collision_policy.dart';
import '../enums/output_mode.dart';
import '../enums/post_run_action.dart';
import 'custom_preset.dart';
import 'library_entry.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(false) bool preferPermanentDelete,
    @Default('.cbz') String outputExt,
    @Default(false) bool skipCjxl,
    @Default(true) bool safeRun,
    @Default(true) bool deleteNonImageFiles,
    @Default('cjxl') String cjxlPath,
    @Default('Lossless') String lastPreset,
    String? lastRoot,
    @Default(<LibraryEntry>[]) List<LibraryEntry> libraries,
    @Default(<CustomPreset>[]) List<CustomPreset> customPresets,
    @Default(OutputMode.besideSource) OutputMode outputMode,
    @Default('') String outputDirectory,
    @Default('{folder}') String namingTemplate,
    @Default(CollisionPolicy.overwrite) CollisionPolicy collisionPolicy,
    @Default(false) bool skipExistingArchives,
    @Default(2) int maxParallelEncodes,
    @Default(true) bool preventSleep,
    @Default(PostRunAction.none) PostRunAction postRunAction,
    @Default(true) bool postRunConfirmEnabled,
    @Default(60) int postRunConfirmSeconds,
    @Default(false) bool tutorialCompleted,
    @Default(true) bool animationsEnabled,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

extension AppSettingsLibraries on AppSettings {
  List<String> get libraryRoots =>
      libraries.map((entry) => entry.path).toList();
}
