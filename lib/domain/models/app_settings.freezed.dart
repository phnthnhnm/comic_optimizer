// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 bool get preferPermanentDelete; String get outputExt; bool get skipCjxl; bool get safeRun; bool get deleteNonImageFiles; String get cjxlPath; String get lastPreset; String? get lastRoot; List<String> get libraryRoots; PostRunAction get postRunAction; bool get postRunConfirmEnabled; int get postRunConfirmSeconds;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.preferPermanentDelete, _this.preferPermanentDelete) || other.preferPermanentDelete == _this.preferPermanentDelete)&&(identical(other.outputExt, _this.outputExt) || other.outputExt == _this.outputExt)&&(identical(other.skipCjxl, _this.skipCjxl) || other.skipCjxl == _this.skipCjxl)&&(identical(other.safeRun, _this.safeRun) || other.safeRun == _this.safeRun)&&(identical(other.deleteNonImageFiles, _this.deleteNonImageFiles) || other.deleteNonImageFiles == _this.deleteNonImageFiles)&&(identical(other.cjxlPath, _this.cjxlPath) || other.cjxlPath == _this.cjxlPath)&&(identical(other.lastPreset, _this.lastPreset) || other.lastPreset == _this.lastPreset)&&(identical(other.lastRoot, _this.lastRoot) || other.lastRoot == _this.lastRoot)&&const DeepCollectionEquality().equals(other.libraryRoots, _this.libraryRoots)&&(identical(other.postRunAction, _this.postRunAction) || other.postRunAction == _this.postRunAction)&&(identical(other.postRunConfirmEnabled, _this.postRunConfirmEnabled) || other.postRunConfirmEnabled == _this.postRunConfirmEnabled)&&(identical(other.postRunConfirmSeconds, _this.postRunConfirmSeconds) || other.postRunConfirmSeconds == _this.postRunConfirmSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.preferPermanentDelete,_this.outputExt,_this.skipCjxl,_this.safeRun,_this.deleteNonImageFiles,_this.cjxlPath,_this.lastPreset,_this.lastRoot,const DeepCollectionEquality().hash(_this.libraryRoots),_this.postRunAction,_this.postRunConfirmEnabled,_this.postRunConfirmSeconds);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(preferPermanentDelete: ${_this.preferPermanentDelete}, outputExt: ${_this.outputExt}, skipCjxl: ${_this.skipCjxl}, safeRun: ${_this.safeRun}, deleteNonImageFiles: ${_this.deleteNonImageFiles}, cjxlPath: ${_this.cjxlPath}, lastPreset: ${_this.lastPreset}, lastRoot: ${_this.lastRoot}, libraryRoots: ${_this.libraryRoots}, postRunAction: ${_this.postRunAction}, postRunConfirmEnabled: ${_this.postRunConfirmEnabled}, postRunConfirmSeconds: ${_this.postRunConfirmSeconds})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 bool preferPermanentDelete, String outputExt, bool skipCjxl, bool safeRun, bool deleteNonImageFiles, String cjxlPath, String lastPreset, String? lastRoot, List<String> libraryRoots, PostRunAction postRunAction, bool postRunConfirmEnabled, int postRunConfirmSeconds
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preferPermanentDelete = null,Object? outputExt = null,Object? skipCjxl = null,Object? safeRun = null,Object? deleteNonImageFiles = null,Object? cjxlPath = null,Object? lastPreset = null,Object? lastRoot = freezed,Object? libraryRoots = null,Object? postRunAction = null,Object? postRunConfirmEnabled = null,Object? postRunConfirmSeconds = null,}) {
  return _then(AppSettings(
preferPermanentDelete: null == preferPermanentDelete ? _self.preferPermanentDelete : preferPermanentDelete // ignore: cast_nullable_to_non_nullable
as bool,outputExt: null == outputExt ? _self.outputExt : outputExt // ignore: cast_nullable_to_non_nullable
as String,skipCjxl: null == skipCjxl ? _self.skipCjxl : skipCjxl // ignore: cast_nullable_to_non_nullable
as bool,safeRun: null == safeRun ? _self.safeRun : safeRun // ignore: cast_nullable_to_non_nullable
as bool,deleteNonImageFiles: null == deleteNonImageFiles ? _self.deleteNonImageFiles : deleteNonImageFiles // ignore: cast_nullable_to_non_nullable
as bool,cjxlPath: null == cjxlPath ? _self.cjxlPath : cjxlPath // ignore: cast_nullable_to_non_nullable
as String,lastPreset: null == lastPreset ? _self.lastPreset : lastPreset // ignore: cast_nullable_to_non_nullable
as String,lastRoot: freezed == lastRoot ? _self.lastRoot : lastRoot // ignore: cast_nullable_to_non_nullable
as String?,libraryRoots: null == libraryRoots ? _self.libraryRoots : libraryRoots // ignore: cast_nullable_to_non_nullable
as List<String>,postRunAction: null == postRunAction ? _self.postRunAction : postRunAction // ignore: cast_nullable_to_non_nullable
as PostRunAction,postRunConfirmEnabled: null == postRunConfirmEnabled ? _self.postRunConfirmEnabled : postRunConfirmEnabled // ignore: cast_nullable_to_non_nullable
as bool,postRunConfirmSeconds: null == postRunConfirmSeconds ? _self.postRunConfirmSeconds : postRunConfirmSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool preferPermanentDelete,  String outputExt,  bool skipCjxl,  bool safeRun,  bool deleteNonImageFiles,  String cjxlPath,  String lastPreset,  String? lastRoot,  List<String> libraryRoots,  PostRunAction postRunAction,  bool postRunConfirmEnabled,  int postRunConfirmSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.preferPermanentDelete,_that.outputExt,_that.skipCjxl,_that.safeRun,_that.deleteNonImageFiles,_that.cjxlPath,_that.lastPreset,_that.lastRoot,_that.libraryRoots,_that.postRunAction,_that.postRunConfirmEnabled,_that.postRunConfirmSeconds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool preferPermanentDelete,  String outputExt,  bool skipCjxl,  bool safeRun,  bool deleteNonImageFiles,  String cjxlPath,  String lastPreset,  String? lastRoot,  List<String> libraryRoots,  PostRunAction postRunAction,  bool postRunConfirmEnabled,  int postRunConfirmSeconds)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.preferPermanentDelete,_that.outputExt,_that.skipCjxl,_that.safeRun,_that.deleteNonImageFiles,_that.cjxlPath,_that.lastPreset,_that.lastRoot,_that.libraryRoots,_that.postRunAction,_that.postRunConfirmEnabled,_that.postRunConfirmSeconds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool preferPermanentDelete,  String outputExt,  bool skipCjxl,  bool safeRun,  bool deleteNonImageFiles,  String cjxlPath,  String lastPreset,  String? lastRoot,  List<String> libraryRoots,  PostRunAction postRunAction,  bool postRunConfirmEnabled,  int postRunConfirmSeconds)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.preferPermanentDelete,_that.outputExt,_that.skipCjxl,_that.safeRun,_that.deleteNonImageFiles,_that.cjxlPath,_that.lastPreset,_that.lastRoot,_that.libraryRoots,_that.postRunAction,_that.postRunConfirmEnabled,_that.postRunConfirmSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings implements AppSettings {
  const _AppSettings({this.preferPermanentDelete = false, this.outputExt = '.cbz', this.skipCjxl = false, this.safeRun = true, this.deleteNonImageFiles = true, this.cjxlPath = 'cjxl', this.lastPreset = 'Lossless', this.lastRoot,  List<String> libraryRoots = const <String>[], this.postRunAction = PostRunAction.none, this.postRunConfirmEnabled = true, this.postRunConfirmSeconds = 60}): _libraryRoots = libraryRoots;
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  bool preferPermanentDelete;
@override@JsonKey() final  String outputExt;
@override@JsonKey() final  bool skipCjxl;
@override@JsonKey() final  bool safeRun;
@override@JsonKey() final  bool deleteNonImageFiles;
@override@JsonKey() final  String cjxlPath;
@override@JsonKey() final  String lastPreset;
@override final  String? lastRoot;
 final  List<String> _libraryRoots;
@override@JsonKey() List<String> get libraryRoots {
  if (_libraryRoots is EqualUnmodifiableListView) return _libraryRoots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_libraryRoots);
}

@override@JsonKey() final  PostRunAction postRunAction;
@override@JsonKey() final  bool postRunConfirmEnabled;
@override@JsonKey() final  int postRunConfirmSeconds;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.preferPermanentDelete, preferPermanentDelete) || other.preferPermanentDelete == preferPermanentDelete)&&(identical(other.outputExt, outputExt) || other.outputExt == outputExt)&&(identical(other.skipCjxl, skipCjxl) || other.skipCjxl == skipCjxl)&&(identical(other.safeRun, safeRun) || other.safeRun == safeRun)&&(identical(other.deleteNonImageFiles, deleteNonImageFiles) || other.deleteNonImageFiles == deleteNonImageFiles)&&(identical(other.cjxlPath, cjxlPath) || other.cjxlPath == cjxlPath)&&(identical(other.lastPreset, lastPreset) || other.lastPreset == lastPreset)&&(identical(other.lastRoot, lastRoot) || other.lastRoot == lastRoot)&&const DeepCollectionEquality().equals(other.libraryRoots, _libraryRoots)&&(identical(other.postRunAction, postRunAction) || other.postRunAction == postRunAction)&&(identical(other.postRunConfirmEnabled, postRunConfirmEnabled) || other.postRunConfirmEnabled == postRunConfirmEnabled)&&(identical(other.postRunConfirmSeconds, postRunConfirmSeconds) || other.postRunConfirmSeconds == postRunConfirmSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,preferPermanentDelete,outputExt,skipCjxl,safeRun,deleteNonImageFiles,cjxlPath,lastPreset,lastRoot,const DeepCollectionEquality().hash(_libraryRoots),postRunAction,postRunConfirmEnabled,postRunConfirmSeconds);
}

@override
String toString() {
    return 'AppSettings(preferPermanentDelete: $preferPermanentDelete, outputExt: $outputExt, skipCjxl: $skipCjxl, safeRun: $safeRun, deleteNonImageFiles: $deleteNonImageFiles, cjxlPath: $cjxlPath, lastPreset: $lastPreset, lastRoot: $lastRoot, libraryRoots: $libraryRoots, postRunAction: $postRunAction, postRunConfirmEnabled: $postRunConfirmEnabled, postRunConfirmSeconds: $postRunConfirmSeconds)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool preferPermanentDelete, String outputExt, bool skipCjxl, bool safeRun, bool deleteNonImageFiles, String cjxlPath, String lastPreset, String? lastRoot, List<String> libraryRoots, PostRunAction postRunAction, bool postRunConfirmEnabled, int postRunConfirmSeconds
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preferPermanentDelete = null,Object? outputExt = null,Object? skipCjxl = null,Object? safeRun = null,Object? deleteNonImageFiles = null,Object? cjxlPath = null,Object? lastPreset = null,Object? lastRoot = freezed,Object? libraryRoots = null,Object? postRunAction = null,Object? postRunConfirmEnabled = null,Object? postRunConfirmSeconds = null,}) {
  return _then(_AppSettings(
preferPermanentDelete: null == preferPermanentDelete ? _self.preferPermanentDelete : preferPermanentDelete // ignore: cast_nullable_to_non_nullable
as bool,outputExt: null == outputExt ? _self.outputExt : outputExt // ignore: cast_nullable_to_non_nullable
as String,skipCjxl: null == skipCjxl ? _self.skipCjxl : skipCjxl // ignore: cast_nullable_to_non_nullable
as bool,safeRun: null == safeRun ? _self.safeRun : safeRun // ignore: cast_nullable_to_non_nullable
as bool,deleteNonImageFiles: null == deleteNonImageFiles ? _self.deleteNonImageFiles : deleteNonImageFiles // ignore: cast_nullable_to_non_nullable
as bool,cjxlPath: null == cjxlPath ? _self.cjxlPath : cjxlPath // ignore: cast_nullable_to_non_nullable
as String,lastPreset: null == lastPreset ? _self.lastPreset : lastPreset // ignore: cast_nullable_to_non_nullable
as String,lastRoot: freezed == lastRoot ? _self.lastRoot : lastRoot // ignore: cast_nullable_to_non_nullable
as String?,libraryRoots: null == libraryRoots ? _self._libraryRoots : libraryRoots // ignore: cast_nullable_to_non_nullable
as List<String>,postRunAction: null == postRunAction ? _self.postRunAction : postRunAction // ignore: cast_nullable_to_non_nullable
as PostRunAction,postRunConfirmEnabled: null == postRunConfirmEnabled ? _self.postRunConfirmEnabled : postRunConfirmEnabled // ignore: cast_nullable_to_non_nullable
as bool,postRunConfirmSeconds: null == postRunConfirmSeconds ? _self.postRunConfirmSeconds : postRunConfirmSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
