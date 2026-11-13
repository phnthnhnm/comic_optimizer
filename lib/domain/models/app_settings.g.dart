// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  preferPermanentDelete: json['preferPermanentDelete'] as bool? ?? false,
  outputExt: json['outputExt'] as String? ?? '.cbz',
  skipCjxl: json['skipCjxl'] as bool? ?? false,
  safeRun: json['safeRun'] as bool? ?? true,
  deleteNonImageFiles: json['deleteNonImageFiles'] as bool? ?? true,
  cjxlPath: json['cjxlPath'] as String? ?? 'cjxl',
  lastPreset: json['lastPreset'] as String? ?? 'Lossless',
  lastRoot: json['lastRoot'] as String?,
  libraryRoots:
      (json['libraryRoots'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  customPresets:
      (json['customPresets'] as List<dynamic>?)
          ?.map((e) => CustomPreset.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CustomPreset>[],
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
      'deleteNonImageFiles': instance.deleteNonImageFiles,
      'cjxlPath': instance.cjxlPath,
      'lastPreset': instance.lastPreset,
      'lastRoot': instance.lastRoot,
      'libraryRoots': instance.libraryRoots,
      'customPresets': instance.customPresets,
      'postRunAction': _$PostRunActionEnumMap[instance.postRunAction]!,
      'postRunConfirmEnabled': instance.postRunConfirmEnabled,
      'postRunConfirmSeconds': instance.postRunConfirmSeconds,
    };

const _$PostRunActionEnumMap = {
  PostRunAction.none: 'none',
  PostRunAction.quit: 'quit',
  PostRunAction.sleep: 'sleep',
  PostRunAction.hibernate: 'hibernate',
  PostRunAction.shutdown: 'shutdown',
  PostRunAction.restart: 'restart',
};
