import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/log_level.dart';
import '../enums/post_run_action.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(false) bool preferPermanentDelete,
    @Default('.cbz') String outputExt,
    @Default(false) bool skipCjxl,
    @Default(false) bool safeRun,
    @Default('cjxl') String cjxlPath,
    @Default('Lossless') String lastPreset,
    String? lastRoot,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(LogLevel.none) LogLevel logLevel,
    @Default(PostRunAction.none) PostRunAction postRunAction,
    @Default(true) bool postRunConfirmEnabled,
    @Default(60) int postRunConfirmSeconds,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
