// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'optimization_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OptimizationState {

 String? get rootPath; String get selectedPreset; bool get skipCjxl; bool get preferPermanentDelete; bool get safeRun; String get outputExt; PostRunAction get postRunAction; bool get postRunConfirmEnabled; int get postRunConfirmSeconds; bool get running; bool get starting; bool get paused; Map<String, List<String>> get logs; String? get currentLogFolder; Map<String, Map<String, int?>> get folderSizes; Map<String, Map<String, Map<String, int?>>> get perFileSizes;
/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptimizationStateCopyWith<OptimizationState> get copyWith => _$OptimizationStateCopyWithImpl<OptimizationState>(this as OptimizationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptimizationState&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.selectedPreset, selectedPreset) || other.selectedPreset == selectedPreset)&&(identical(other.skipCjxl, skipCjxl) || other.skipCjxl == skipCjxl)&&(identical(other.preferPermanentDelete, preferPermanentDelete) || other.preferPermanentDelete == preferPermanentDelete)&&(identical(other.safeRun, safeRun) || other.safeRun == safeRun)&&(identical(other.outputExt, outputExt) || other.outputExt == outputExt)&&(identical(other.postRunAction, postRunAction) || other.postRunAction == postRunAction)&&(identical(other.postRunConfirmEnabled, postRunConfirmEnabled) || other.postRunConfirmEnabled == postRunConfirmEnabled)&&(identical(other.postRunConfirmSeconds, postRunConfirmSeconds) || other.postRunConfirmSeconds == postRunConfirmSeconds)&&(identical(other.running, running) || other.running == running)&&(identical(other.starting, starting) || other.starting == starting)&&(identical(other.paused, paused) || other.paused == paused)&&const DeepCollectionEquality().equals(other.logs, logs)&&(identical(other.currentLogFolder, currentLogFolder) || other.currentLogFolder == currentLogFolder)&&const DeepCollectionEquality().equals(other.folderSizes, folderSizes)&&const DeepCollectionEquality().equals(other.perFileSizes, perFileSizes));
}


@override
int get hashCode => Object.hash(runtimeType,rootPath,selectedPreset,skipCjxl,preferPermanentDelete,safeRun,outputExt,postRunAction,postRunConfirmEnabled,postRunConfirmSeconds,running,starting,paused,const DeepCollectionEquality().hash(logs),currentLogFolder,const DeepCollectionEquality().hash(folderSizes),const DeepCollectionEquality().hash(perFileSizes));

@override
String toString() {
  return 'OptimizationState(rootPath: $rootPath, selectedPreset: $selectedPreset, skipCjxl: $skipCjxl, preferPermanentDelete: $preferPermanentDelete, safeRun: $safeRun, outputExt: $outputExt, postRunAction: $postRunAction, postRunConfirmEnabled: $postRunConfirmEnabled, postRunConfirmSeconds: $postRunConfirmSeconds, running: $running, starting: $starting, paused: $paused, logs: $logs, currentLogFolder: $currentLogFolder, folderSizes: $folderSizes, perFileSizes: $perFileSizes)';
}


}

/// @nodoc
abstract mixin class $OptimizationStateCopyWith<$Res>  {
  factory $OptimizationStateCopyWith(OptimizationState value, $Res Function(OptimizationState) _then) = _$OptimizationStateCopyWithImpl;
@useResult
$Res call({
 String? rootPath, String selectedPreset, bool skipCjxl, bool preferPermanentDelete, bool safeRun, String outputExt, PostRunAction postRunAction, bool postRunConfirmEnabled, int postRunConfirmSeconds, bool running, bool starting, bool paused, Map<String, List<String>> logs, String? currentLogFolder, Map<String, Map<String, int?>> folderSizes, Map<String, Map<String, Map<String, int?>>> perFileSizes
});




}
/// @nodoc
class _$OptimizationStateCopyWithImpl<$Res>
    implements $OptimizationStateCopyWith<$Res> {
  _$OptimizationStateCopyWithImpl(this._self, this._then);

  final OptimizationState _self;
  final $Res Function(OptimizationState) _then;

/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rootPath = freezed,Object? selectedPreset = null,Object? skipCjxl = null,Object? preferPermanentDelete = null,Object? safeRun = null,Object? outputExt = null,Object? postRunAction = null,Object? postRunConfirmEnabled = null,Object? postRunConfirmSeconds = null,Object? running = null,Object? starting = null,Object? paused = null,Object? logs = null,Object? currentLogFolder = freezed,Object? folderSizes = null,Object? perFileSizes = null,}) {
  return _then(_self.copyWith(
rootPath: freezed == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String?,selectedPreset: null == selectedPreset ? _self.selectedPreset : selectedPreset // ignore: cast_nullable_to_non_nullable
as String,skipCjxl: null == skipCjxl ? _self.skipCjxl : skipCjxl // ignore: cast_nullable_to_non_nullable
as bool,preferPermanentDelete: null == preferPermanentDelete ? _self.preferPermanentDelete : preferPermanentDelete // ignore: cast_nullable_to_non_nullable
as bool,safeRun: null == safeRun ? _self.safeRun : safeRun // ignore: cast_nullable_to_non_nullable
as bool,outputExt: null == outputExt ? _self.outputExt : outputExt // ignore: cast_nullable_to_non_nullable
as String,postRunAction: null == postRunAction ? _self.postRunAction : postRunAction // ignore: cast_nullable_to_non_nullable
as PostRunAction,postRunConfirmEnabled: null == postRunConfirmEnabled ? _self.postRunConfirmEnabled : postRunConfirmEnabled // ignore: cast_nullable_to_non_nullable
as bool,postRunConfirmSeconds: null == postRunConfirmSeconds ? _self.postRunConfirmSeconds : postRunConfirmSeconds // ignore: cast_nullable_to_non_nullable
as int,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,currentLogFolder: freezed == currentLogFolder ? _self.currentLogFolder : currentLogFolder // ignore: cast_nullable_to_non_nullable
as String?,folderSizes: null == folderSizes ? _self.folderSizes : folderSizes // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, int?>>,perFileSizes: null == perFileSizes ? _self.perFileSizes : perFileSizes // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, Map<String, int?>>>,
  ));
}

}


/// Adds pattern-matching-related methods to [OptimizationState].
extension OptimizationStatePatterns on OptimizationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OptimizationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OptimizationState value)  $default,){
final _that = this;
switch (_that) {
case _OptimizationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OptimizationState value)?  $default,){
final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? rootPath,  String selectedPreset,  bool skipCjxl,  bool preferPermanentDelete,  bool safeRun,  String outputExt,  PostRunAction postRunAction,  bool postRunConfirmEnabled,  int postRunConfirmSeconds,  bool running,  bool starting,  bool paused,  Map<String, List<String>> logs,  String? currentLogFolder,  Map<String, Map<String, int?>> folderSizes,  Map<String, Map<String, Map<String, int?>>> perFileSizes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
return $default(_that.rootPath,_that.selectedPreset,_that.skipCjxl,_that.preferPermanentDelete,_that.safeRun,_that.outputExt,_that.postRunAction,_that.postRunConfirmEnabled,_that.postRunConfirmSeconds,_that.running,_that.starting,_that.paused,_that.logs,_that.currentLogFolder,_that.folderSizes,_that.perFileSizes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? rootPath,  String selectedPreset,  bool skipCjxl,  bool preferPermanentDelete,  bool safeRun,  String outputExt,  PostRunAction postRunAction,  bool postRunConfirmEnabled,  int postRunConfirmSeconds,  bool running,  bool starting,  bool paused,  Map<String, List<String>> logs,  String? currentLogFolder,  Map<String, Map<String, int?>> folderSizes,  Map<String, Map<String, Map<String, int?>>> perFileSizes)  $default,) {final _that = this;
switch (_that) {
case _OptimizationState():
return $default(_that.rootPath,_that.selectedPreset,_that.skipCjxl,_that.preferPermanentDelete,_that.safeRun,_that.outputExt,_that.postRunAction,_that.postRunConfirmEnabled,_that.postRunConfirmSeconds,_that.running,_that.starting,_that.paused,_that.logs,_that.currentLogFolder,_that.folderSizes,_that.perFileSizes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? rootPath,  String selectedPreset,  bool skipCjxl,  bool preferPermanentDelete,  bool safeRun,  String outputExt,  PostRunAction postRunAction,  bool postRunConfirmEnabled,  int postRunConfirmSeconds,  bool running,  bool starting,  bool paused,  Map<String, List<String>> logs,  String? currentLogFolder,  Map<String, Map<String, int?>> folderSizes,  Map<String, Map<String, Map<String, int?>>> perFileSizes)?  $default,) {final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
return $default(_that.rootPath,_that.selectedPreset,_that.skipCjxl,_that.preferPermanentDelete,_that.safeRun,_that.outputExt,_that.postRunAction,_that.postRunConfirmEnabled,_that.postRunConfirmSeconds,_that.running,_that.starting,_that.paused,_that.logs,_that.currentLogFolder,_that.folderSizes,_that.perFileSizes);case _:
  return null;

}
}

}

/// @nodoc


class _OptimizationState extends OptimizationState {
  const _OptimizationState({this.rootPath, this.selectedPreset = 'Lossless', this.skipCjxl = false, this.preferPermanentDelete = false, this.safeRun = false, this.outputExt = '.cbz', this.postRunAction = PostRunAction.none, this.postRunConfirmEnabled = true, this.postRunConfirmSeconds = 60, this.running = false, this.starting = false, this.paused = false, final  Map<String, List<String>> logs = const <String, List<String>>{}, this.currentLogFolder, final  Map<String, Map<String, int?>> folderSizes = const <String, Map<String, int?>>{}, final  Map<String, Map<String, Map<String, int?>>> perFileSizes = const <String, Map<String, Map<String, int?>>>{}}): _logs = logs,_folderSizes = folderSizes,_perFileSizes = perFileSizes,super._();
  

@override final  String? rootPath;
@override@JsonKey() final  String selectedPreset;
@override@JsonKey() final  bool skipCjxl;
@override@JsonKey() final  bool preferPermanentDelete;
@override@JsonKey() final  bool safeRun;
@override@JsonKey() final  String outputExt;
@override@JsonKey() final  PostRunAction postRunAction;
@override@JsonKey() final  bool postRunConfirmEnabled;
@override@JsonKey() final  int postRunConfirmSeconds;
@override@JsonKey() final  bool running;
@override@JsonKey() final  bool starting;
@override@JsonKey() final  bool paused;
 final  Map<String, List<String>> _logs;
@override@JsonKey() Map<String, List<String>> get logs {
  if (_logs is EqualUnmodifiableMapView) return _logs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_logs);
}

@override final  String? currentLogFolder;
 final  Map<String, Map<String, int?>> _folderSizes;
@override@JsonKey() Map<String, Map<String, int?>> get folderSizes {
  if (_folderSizes is EqualUnmodifiableMapView) return _folderSizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_folderSizes);
}

 final  Map<String, Map<String, Map<String, int?>>> _perFileSizes;
@override@JsonKey() Map<String, Map<String, Map<String, int?>>> get perFileSizes {
  if (_perFileSizes is EqualUnmodifiableMapView) return _perFileSizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_perFileSizes);
}


/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptimizationStateCopyWith<_OptimizationState> get copyWith => __$OptimizationStateCopyWithImpl<_OptimizationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptimizationState&&(identical(other.rootPath, rootPath) || other.rootPath == rootPath)&&(identical(other.selectedPreset, selectedPreset) || other.selectedPreset == selectedPreset)&&(identical(other.skipCjxl, skipCjxl) || other.skipCjxl == skipCjxl)&&(identical(other.preferPermanentDelete, preferPermanentDelete) || other.preferPermanentDelete == preferPermanentDelete)&&(identical(other.safeRun, safeRun) || other.safeRun == safeRun)&&(identical(other.outputExt, outputExt) || other.outputExt == outputExt)&&(identical(other.postRunAction, postRunAction) || other.postRunAction == postRunAction)&&(identical(other.postRunConfirmEnabled, postRunConfirmEnabled) || other.postRunConfirmEnabled == postRunConfirmEnabled)&&(identical(other.postRunConfirmSeconds, postRunConfirmSeconds) || other.postRunConfirmSeconds == postRunConfirmSeconds)&&(identical(other.running, running) || other.running == running)&&(identical(other.starting, starting) || other.starting == starting)&&(identical(other.paused, paused) || other.paused == paused)&&const DeepCollectionEquality().equals(other._logs, _logs)&&(identical(other.currentLogFolder, currentLogFolder) || other.currentLogFolder == currentLogFolder)&&const DeepCollectionEquality().equals(other._folderSizes, _folderSizes)&&const DeepCollectionEquality().equals(other._perFileSizes, _perFileSizes));
}


@override
int get hashCode => Object.hash(runtimeType,rootPath,selectedPreset,skipCjxl,preferPermanentDelete,safeRun,outputExt,postRunAction,postRunConfirmEnabled,postRunConfirmSeconds,running,starting,paused,const DeepCollectionEquality().hash(_logs),currentLogFolder,const DeepCollectionEquality().hash(_folderSizes),const DeepCollectionEquality().hash(_perFileSizes));

@override
String toString() {
  return 'OptimizationState(rootPath: $rootPath, selectedPreset: $selectedPreset, skipCjxl: $skipCjxl, preferPermanentDelete: $preferPermanentDelete, safeRun: $safeRun, outputExt: $outputExt, postRunAction: $postRunAction, postRunConfirmEnabled: $postRunConfirmEnabled, postRunConfirmSeconds: $postRunConfirmSeconds, running: $running, starting: $starting, paused: $paused, logs: $logs, currentLogFolder: $currentLogFolder, folderSizes: $folderSizes, perFileSizes: $perFileSizes)';
}


}

/// @nodoc
abstract mixin class _$OptimizationStateCopyWith<$Res> implements $OptimizationStateCopyWith<$Res> {
  factory _$OptimizationStateCopyWith(_OptimizationState value, $Res Function(_OptimizationState) _then) = __$OptimizationStateCopyWithImpl;
@override @useResult
$Res call({
 String? rootPath, String selectedPreset, bool skipCjxl, bool preferPermanentDelete, bool safeRun, String outputExt, PostRunAction postRunAction, bool postRunConfirmEnabled, int postRunConfirmSeconds, bool running, bool starting, bool paused, Map<String, List<String>> logs, String? currentLogFolder, Map<String, Map<String, int?>> folderSizes, Map<String, Map<String, Map<String, int?>>> perFileSizes
});




}
/// @nodoc
class __$OptimizationStateCopyWithImpl<$Res>
    implements _$OptimizationStateCopyWith<$Res> {
  __$OptimizationStateCopyWithImpl(this._self, this._then);

  final _OptimizationState _self;
  final $Res Function(_OptimizationState) _then;

/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rootPath = freezed,Object? selectedPreset = null,Object? skipCjxl = null,Object? preferPermanentDelete = null,Object? safeRun = null,Object? outputExt = null,Object? postRunAction = null,Object? postRunConfirmEnabled = null,Object? postRunConfirmSeconds = null,Object? running = null,Object? starting = null,Object? paused = null,Object? logs = null,Object? currentLogFolder = freezed,Object? folderSizes = null,Object? perFileSizes = null,}) {
  return _then(_OptimizationState(
rootPath: freezed == rootPath ? _self.rootPath : rootPath // ignore: cast_nullable_to_non_nullable
as String?,selectedPreset: null == selectedPreset ? _self.selectedPreset : selectedPreset // ignore: cast_nullable_to_non_nullable
as String,skipCjxl: null == skipCjxl ? _self.skipCjxl : skipCjxl // ignore: cast_nullable_to_non_nullable
as bool,preferPermanentDelete: null == preferPermanentDelete ? _self.preferPermanentDelete : preferPermanentDelete // ignore: cast_nullable_to_non_nullable
as bool,safeRun: null == safeRun ? _self.safeRun : safeRun // ignore: cast_nullable_to_non_nullable
as bool,outputExt: null == outputExt ? _self.outputExt : outputExt // ignore: cast_nullable_to_non_nullable
as String,postRunAction: null == postRunAction ? _self.postRunAction : postRunAction // ignore: cast_nullable_to_non_nullable
as PostRunAction,postRunConfirmEnabled: null == postRunConfirmEnabled ? _self.postRunConfirmEnabled : postRunConfirmEnabled // ignore: cast_nullable_to_non_nullable
as bool,postRunConfirmSeconds: null == postRunConfirmSeconds ? _self.postRunConfirmSeconds : postRunConfirmSeconds // ignore: cast_nullable_to_non_nullable
as int,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,logs: null == logs ? _self._logs : logs // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,currentLogFolder: freezed == currentLogFolder ? _self.currentLogFolder : currentLogFolder // ignore: cast_nullable_to_non_nullable
as String?,folderSizes: null == folderSizes ? _self._folderSizes : folderSizes // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, int?>>,perFileSizes: null == perFileSizes ? _self._perFileSizes : perFileSizes // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, Map<String, int?>>>,
  ));
}


}

// dart format on
