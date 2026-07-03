// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Preset _$PresetFromJson(Map<String, dynamic> json) => _Preset(
  name: json['name'] as String,
  args:
      (json['args'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$PresetToJson(_Preset instance) => <String, dynamic>{
  'name': instance.name,
  'args': instance.args,
};
