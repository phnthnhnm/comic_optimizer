// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibraryEntry _$LibraryEntryFromJson(Map<String, dynamic> json) =>
    _LibraryEntry(
      path: json['path'] as String,
      preset: json['preset'] as String?,
      outputDirectory: json['outputDirectory'] as String?,
      safeRunOverride: json['safeRunOverride'] as bool?,
    );

Map<String, dynamic> _$LibraryEntryToJson(_LibraryEntry instance) =>
    <String, dynamic>{
      'path': instance.path,
      'preset': instance.preset,
      'outputDirectory': instance.outputDirectory,
      'safeRunOverride': instance.safeRunOverride,
    };
