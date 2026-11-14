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
  libraries:
      (json['libraries'] as List<dynamic>?)
          ?.map((e) => LibraryEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LibraryEntry>[],
  customPresets:
      (json['customPresets'] as List<dynamic>?)
          ?.map((e) => CustomPreset.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CustomPreset>[],
  outputMode:
      $enumDecodeNullable(_$OutputModeEnumMap, json['outputMode']) ??
      OutputMode.besideSource,
  outputDirectory: json['outputDirectory'] as String? ?? '',
  namingTemplate: json['namingTemplate'] as String? ?? '{folder}',
  collisionPolicy:
      $enumDecodeNullable(_$CollisionPolicyEnumMap, json['collisionPolicy']) ??
      CollisionPolicy.overwrite,
  skipExistingArchives: json['skipExistingArchives'] as bool? ?? false,
  maxParallelEncodes: (json['maxParallelEncodes'] as num?)?.toInt() ?? 2,
  preventSleep: json['preventSleep'] as bool? ?? true,
  postRunAction:
      $enumDecodeNullable(_$PostRunActionEnumMap, json['postRunAction']) ??
      PostRunAction.none,
  postRunConfirmEnabled: json['postRunConfirmEnabled'] as bool? ?? true,
  postRunConfirmSeconds: (json['postRunConfirmSeconds'] as num?)?.toInt() ?? 60,
  tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
  animationsEnabled: json['animationsEnabled'] as bool? ?? true,
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
      'libraries': instance.libraries.map((e) => e.toJson()).toList(),
      'customPresets': instance.customPresets.map((e) => e.toJson()).toList(),
      'outputMode': _$OutputModeEnumMap[instance.outputMode]!,
      'outputDirectory': instance.outputDirectory,
      'namingTemplate': instance.namingTemplate,
      'collisionPolicy': _$CollisionPolicyEnumMap[instance.collisionPolicy]!,
      'skipExistingArchives': instance.skipExistingArchives,
      'maxParallelEncodes': instance.maxParallelEncodes,
      'preventSleep': instance.preventSleep,
      'postRunAction': _$PostRunActionEnumMap[instance.postRunAction]!,
      'postRunConfirmEnabled': instance.postRunConfirmEnabled,
      'postRunConfirmSeconds': instance.postRunConfirmSeconds,
      'tutorialCompleted': instance.tutorialCompleted,
      'animationsEnabled': instance.animationsEnabled,
    };

const _$OutputModeEnumMap = {
  OutputMode.besideSource: 'besideSource',
  OutputMode.custom: 'custom',
};

const _$CollisionPolicyEnumMap = {
  CollisionPolicy.overwrite: 'overwrite',
  CollisionPolicy.skip: 'skip',
  CollisionPolicy.suffix: 'suffix',
};

const _$PostRunActionEnumMap = {
  PostRunAction.none: 'none',
  PostRunAction.quit: 'quit',
  PostRunAction.sleep: 'sleep',
  PostRunAction.hibernate: 'hibernate',
  PostRunAction.shutdown: 'shutdown',
  PostRunAction.restart: 'restart',
};
