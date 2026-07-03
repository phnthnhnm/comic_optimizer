// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  preferPermanentDelete: json['preferPermanentDelete'] as bool? ?? false,
  outputExt: json['outputExt'] as String? ?? '.cbz',
  skipCjxl: json['skipCjxl'] as bool? ?? false,
  safeRun: json['safeRun'] as bool? ?? false,
  cjxlPath: json['cjxlPath'] as String? ?? 'cjxl',
  lastPreset: json['lastPreset'] as String? ?? 'Lossless',
  lastRoot: json['lastRoot'] as String?,
  themeMode:
      $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
      ThemeMode.system,
  logLevel:
      $enumDecodeNullable(_$LogLevelEnumMap, json['logLevel']) ?? LogLevel.none,
  postRunAction:
      $enumDecodeNullable(_$PostRunActionEnumMap, json['postRunAction']) ??
      PostRunAction.none,
  postRunConfirmEnabled: json['postRunConfirmEnabled'] as bool? ?? true,
  postRunConfirmSeconds: (json['postRunConfirmSeconds'] as num?)?.toInt() ?? 60,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'preferPermanentDelete': instance.preferPermanentDelete,
      'outputExt': instance.outputExt,
      'skipCjxl': instance.skipCjxl,
      'safeRun': instance.safeRun,
      'cjxlPath': instance.cjxlPath,
      'lastPreset': instance.lastPreset,
      'lastRoot': instance.lastRoot,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'logLevel': _$LogLevelEnumMap[instance.logLevel]!,
      'postRunAction': _$PostRunActionEnumMap[instance.postRunAction]!,
      'postRunConfirmEnabled': instance.postRunConfirmEnabled,
      'postRunConfirmSeconds': instance.postRunConfirmSeconds,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$LogLevelEnumMap = {
  LogLevel.none: 'none',
  LogLevel.normal: 'normal',
  LogLevel.error: 'error',
};

const _$PostRunActionEnumMap = {
  PostRunAction.none: 'none',
  PostRunAction.quit: 'quit',
  PostRunAction.sleep: 'sleep',
  PostRunAction.hibernate: 'hibernate',
  PostRunAction.shutdown: 'shutdown',
  PostRunAction.restart: 'restart',
};
