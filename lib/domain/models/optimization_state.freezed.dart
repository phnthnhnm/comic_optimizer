// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'optimization_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OptimizationState {

 bool get running; bool get starting; bool get paused; int get rootsTotal; int get rootsDone; String? get currentRoot; List<String> get libraries; int get comicsTotal; int get comicsDone; int get imagesTotal; int get imagesDone; String? get currentFolder; String? get currentFile; Map<String, List<RunLogEntry>> get logs; Map<String, FolderRunStatus> get folders; Map<String, FolderRunResult> get results; DateTime? get startedAt; DateTime? get finishedAt; String? get currentLogFolder;
/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptimizationStateCopyWith<OptimizationState> get copyWith => _$OptimizationStateCopyWithImpl<OptimizationState>(this as OptimizationState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OptimizationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptimizationState&&(identical(other.running, _this.running) || other.running == _this.running)&&(identical(other.starting, _this.starting) || other.starting == _this.starting)&&(identical(other.paused, _this.paused) || other.paused == _this.paused)&&(identical(other.rootsTotal, _this.rootsTotal) || other.rootsTotal == _this.rootsTotal)&&(identical(other.rootsDone, _this.rootsDone) || other.rootsDone == _this.rootsDone)&&(identical(other.currentRoot, _this.currentRoot) || other.currentRoot == _this.currentRoot)&&const DeepCollectionEquality().equals(other.libraries, _this.libraries)&&(identical(other.comicsTotal, _this.comicsTotal) || other.comicsTotal == _this.comicsTotal)&&(identical(other.comicsDone, _this.comicsDone) || other.comicsDone == _this.comicsDone)&&(identical(other.imagesTotal, _this.imagesTotal) || other.imagesTotal == _this.imagesTotal)&&(identical(other.imagesDone, _this.imagesDone) || other.imagesDone == _this.imagesDone)&&(identical(other.currentFolder, _this.currentFolder) || other.currentFolder == _this.currentFolder)&&(identical(other.currentFile, _this.currentFile) || other.currentFile == _this.currentFile)&&const DeepCollectionEquality().equals(other.logs, _this.logs)&&const DeepCollectionEquality().equals(other.folders, _this.folders)&&const DeepCollectionEquality().equals(other.results, _this.results)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.finishedAt, _this.finishedAt) || other.finishedAt == _this.finishedAt)&&(identical(other.currentLogFolder, _this.currentLogFolder) || other.currentLogFolder == _this.currentLogFolder));
}


@override
int get hashCode {
  final _this = this as OptimizationState;
  return Object.hashAll([runtimeType,_this.running,_this.starting,_this.paused,_this.rootsTotal,_this.rootsDone,_this.currentRoot,const DeepCollectionEquality().hash(_this.libraries),_this.comicsTotal,_this.comicsDone,_this.imagesTotal,_this.imagesDone,_this.currentFolder,_this.currentFile,const DeepCollectionEquality().hash(_this.logs),const DeepCollectionEquality().hash(_this.folders),const DeepCollectionEquality().hash(_this.results),_this.startedAt,_this.finishedAt,_this.currentLogFolder]);
}

@override
String toString() {
  final _this = this as OptimizationState;
  return 'OptimizationState(running: ${_this.running}, starting: ${_this.starting}, paused: ${_this.paused}, rootsTotal: ${_this.rootsTotal}, rootsDone: ${_this.rootsDone}, currentRoot: ${_this.currentRoot}, libraries: ${_this.libraries}, comicsTotal: ${_this.comicsTotal}, comicsDone: ${_this.comicsDone}, imagesTotal: ${_this.imagesTotal}, imagesDone: ${_this.imagesDone}, currentFolder: ${_this.currentFolder}, currentFile: ${_this.currentFile}, logs: ${_this.logs}, folders: ${_this.folders}, results: ${_this.results}, startedAt: ${_this.startedAt}, finishedAt: ${_this.finishedAt}, currentLogFolder: ${_this.currentLogFolder})';
}


}

/// @nodoc
abstract mixin class $OptimizationStateCopyWith<$Res>  {
  factory $OptimizationStateCopyWith(OptimizationState value, $Res Function(OptimizationState) _then) = _$OptimizationStateCopyWithImpl;
@useResult
$Res call({
 bool running, bool starting, bool paused, int rootsTotal, int rootsDone, String? currentRoot, List<String> libraries, int comicsTotal, int comicsDone, int imagesTotal, int imagesDone, String? currentFolder, String? currentFile, Map<String, List<RunLogEntry>> logs, Map<String, FolderRunStatus> folders, Map<String, FolderRunResult> results, DateTime? startedAt, DateTime? finishedAt, String? currentLogFolder
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
@pragma('vm:prefer-inline') @override $Res call({Object? running = null,Object? starting = null,Object? paused = null,Object? rootsTotal = null,Object? rootsDone = null,Object? currentRoot = freezed,Object? libraries = null,Object? comicsTotal = null,Object? comicsDone = null,Object? imagesTotal = null,Object? imagesDone = null,Object? currentFolder = freezed,Object? currentFile = freezed,Object? logs = null,Object? folders = null,Object? results = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? currentLogFolder = freezed,}) {
  return _then(OptimizationState(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,rootsTotal: null == rootsTotal ? _self.rootsTotal : rootsTotal // ignore: cast_nullable_to_non_nullable
as int,rootsDone: null == rootsDone ? _self.rootsDone : rootsDone // ignore: cast_nullable_to_non_nullable
as int,currentRoot: freezed == currentRoot ? _self.currentRoot : currentRoot // ignore: cast_nullable_to_non_nullable
as String?,libraries: null == libraries ? _self.libraries : libraries // ignore: cast_nullable_to_non_nullable
as List<String>,comicsTotal: null == comicsTotal ? _self.comicsTotal : comicsTotal // ignore: cast_nullable_to_non_nullable
as int,comicsDone: null == comicsDone ? _self.comicsDone : comicsDone // ignore: cast_nullable_to_non_nullable
as int,imagesTotal: null == imagesTotal ? _self.imagesTotal : imagesTotal // ignore: cast_nullable_to_non_nullable
as int,imagesDone: null == imagesDone ? _self.imagesDone : imagesDone // ignore: cast_nullable_to_non_nullable
as int,currentFolder: freezed == currentFolder ? _self.currentFolder : currentFolder // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as Map<String, List<RunLogEntry>>,folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as Map<String, FolderRunStatus>,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as Map<String, FolderRunResult>,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentLogFolder: freezed == currentLogFolder ? _self.currentLogFolder : currentLogFolder // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool running,  bool starting,  bool paused,  int rootsTotal,  int rootsDone,  String? currentRoot,  List<String> libraries,  int comicsTotal,  int comicsDone,  int imagesTotal,  int imagesDone,  String? currentFolder,  String? currentFile,  Map<String, List<RunLogEntry>> logs,  Map<String, FolderRunStatus> folders,  Map<String, FolderRunResult> results,  DateTime? startedAt,  DateTime? finishedAt,  String? currentLogFolder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
return $default(_that.running,_that.starting,_that.paused,_that.rootsTotal,_that.rootsDone,_that.currentRoot,_that.libraries,_that.comicsTotal,_that.comicsDone,_that.imagesTotal,_that.imagesDone,_that.currentFolder,_that.currentFile,_that.logs,_that.folders,_that.results,_that.startedAt,_that.finishedAt,_that.currentLogFolder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool running,  bool starting,  bool paused,  int rootsTotal,  int rootsDone,  String? currentRoot,  List<String> libraries,  int comicsTotal,  int comicsDone,  int imagesTotal,  int imagesDone,  String? currentFolder,  String? currentFile,  Map<String, List<RunLogEntry>> logs,  Map<String, FolderRunStatus> folders,  Map<String, FolderRunResult> results,  DateTime? startedAt,  DateTime? finishedAt,  String? currentLogFolder)  $default,) {final _that = this;
switch (_that) {
case _OptimizationState():
return $default(_that.running,_that.starting,_that.paused,_that.rootsTotal,_that.rootsDone,_that.currentRoot,_that.libraries,_that.comicsTotal,_that.comicsDone,_that.imagesTotal,_that.imagesDone,_that.currentFolder,_that.currentFile,_that.logs,_that.folders,_that.results,_that.startedAt,_that.finishedAt,_that.currentLogFolder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool running,  bool starting,  bool paused,  int rootsTotal,  int rootsDone,  String? currentRoot,  List<String> libraries,  int comicsTotal,  int comicsDone,  int imagesTotal,  int imagesDone,  String? currentFolder,  String? currentFile,  Map<String, List<RunLogEntry>> logs,  Map<String, FolderRunStatus> folders,  Map<String, FolderRunResult> results,  DateTime? startedAt,  DateTime? finishedAt,  String? currentLogFolder)?  $default,) {final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
return $default(_that.running,_that.starting,_that.paused,_that.rootsTotal,_that.rootsDone,_that.currentRoot,_that.libraries,_that.comicsTotal,_that.comicsDone,_that.imagesTotal,_that.imagesDone,_that.currentFolder,_that.currentFile,_that.logs,_that.folders,_that.results,_that.startedAt,_that.finishedAt,_that.currentLogFolder);case _:
  return null;

}
}

}

/// @nodoc


class _OptimizationState extends OptimizationState {
  const _OptimizationState({this.running = false, this.starting = false, this.paused = false, this.rootsTotal = 0, this.rootsDone = 0, this.currentRoot,  List<String> libraries = const <String>[], this.comicsTotal = 0, this.comicsDone = 0, this.imagesTotal = 0, this.imagesDone = 0, this.currentFolder, this.currentFile,  Map<String, List<RunLogEntry>> logs = const <String, List<RunLogEntry>>{},  Map<String, FolderRunStatus> folders = const <String, FolderRunStatus>{},  Map<String, FolderRunResult> results = const <String, FolderRunResult>{}, this.startedAt, this.finishedAt, this.currentLogFolder}): _libraries = libraries,_logs = logs,_folders = folders,_results = results,super._();
  

@override@JsonKey() final  bool running;
@override@JsonKey() final  bool starting;
@override@JsonKey() final  bool paused;
@override@JsonKey() final  int rootsTotal;
@override@JsonKey() final  int rootsDone;
@override final  String? currentRoot;
 final  List<String> _libraries;
@override@JsonKey() List<String> get libraries {
  if (_libraries is EqualUnmodifiableListView) return _libraries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_libraries);
}

@override@JsonKey() final  int comicsTotal;
@override@JsonKey() final  int comicsDone;
@override@JsonKey() final  int imagesTotal;
@override@JsonKey() final  int imagesDone;
@override final  String? currentFolder;
@override final  String? currentFile;
 final  Map<String, List<RunLogEntry>> _logs;
@override@JsonKey() Map<String, List<RunLogEntry>> get logs {
  if (_logs is EqualUnmodifiableMapView) return _logs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_logs);
}

 final  Map<String, FolderRunStatus> _folders;
@override@JsonKey() Map<String, FolderRunStatus> get folders {
  if (_folders is EqualUnmodifiableMapView) return _folders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_folders);
}

 final  Map<String, FolderRunResult> _results;
@override@JsonKey() Map<String, FolderRunResult> get results {
  if (_results is EqualUnmodifiableMapView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_results);
}

@override final  DateTime? startedAt;
@override final  DateTime? finishedAt;
@override final  String? currentLogFolder;

/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptimizationStateCopyWith<_OptimizationState> get copyWith => __$OptimizationStateCopyWithImpl<_OptimizationState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptimizationState&&(identical(other.running, running) || other.running == running)&&(identical(other.starting, starting) || other.starting == starting)&&(identical(other.paused, paused) || other.paused == paused)&&(identical(other.rootsTotal, rootsTotal) || other.rootsTotal == rootsTotal)&&(identical(other.rootsDone, rootsDone) || other.rootsDone == rootsDone)&&(identical(other.currentRoot, currentRoot) || other.currentRoot == currentRoot)&&const DeepCollectionEquality().equals(other.libraries, _libraries)&&(identical(other.comicsTotal, comicsTotal) || other.comicsTotal == comicsTotal)&&(identical(other.comicsDone, comicsDone) || other.comicsDone == comicsDone)&&(identical(other.imagesTotal, imagesTotal) || other.imagesTotal == imagesTotal)&&(identical(other.imagesDone, imagesDone) || other.imagesDone == imagesDone)&&(identical(other.currentFolder, currentFolder) || other.currentFolder == currentFolder)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&const DeepCollectionEquality().equals(other.logs, _logs)&&const DeepCollectionEquality().equals(other.folders, _folders)&&const DeepCollectionEquality().equals(other.results, _results)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.currentLogFolder, currentLogFolder) || other.currentLogFolder == currentLogFolder));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,running,starting,paused,rootsTotal,rootsDone,currentRoot,const DeepCollectionEquality().hash(_libraries),comicsTotal,comicsDone,imagesTotal,imagesDone,currentFolder,currentFile,const DeepCollectionEquality().hash(_logs),const DeepCollectionEquality().hash(_folders),const DeepCollectionEquality().hash(_results),startedAt,finishedAt,currentLogFolder]);
}

@override
String toString() {
    return 'OptimizationState(running: $running, starting: $starting, paused: $paused, rootsTotal: $rootsTotal, rootsDone: $rootsDone, currentRoot: $currentRoot, libraries: $libraries, comicsTotal: $comicsTotal, comicsDone: $comicsDone, imagesTotal: $imagesTotal, imagesDone: $imagesDone, currentFolder: $currentFolder, currentFile: $currentFile, logs: $logs, folders: $folders, results: $results, startedAt: $startedAt, finishedAt: $finishedAt, currentLogFolder: $currentLogFolder)';
}


}

/// @nodoc
abstract mixin class _$OptimizationStateCopyWith<$Res> implements $OptimizationStateCopyWith<$Res> {
  factory _$OptimizationStateCopyWith(_OptimizationState value, $Res Function(_OptimizationState) _then) = __$OptimizationStateCopyWithImpl;
@override @useResult
$Res call({
 bool running, bool starting, bool paused, int rootsTotal, int rootsDone, String? currentRoot, List<String> libraries, int comicsTotal, int comicsDone, int imagesTotal, int imagesDone, String? currentFolder, String? currentFile, Map<String, List<RunLogEntry>> logs, Map<String, FolderRunStatus> folders, Map<String, FolderRunResult> results, DateTime? startedAt, DateTime? finishedAt, String? currentLogFolder
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
@override @pragma('vm:prefer-inline') $Res call({Object? running = null,Object? starting = null,Object? paused = null,Object? rootsTotal = null,Object? rootsDone = null,Object? currentRoot = freezed,Object? libraries = null,Object? comicsTotal = null,Object? comicsDone = null,Object? imagesTotal = null,Object? imagesDone = null,Object? currentFolder = freezed,Object? currentFile = freezed,Object? logs = null,Object? folders = null,Object? results = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? currentLogFolder = freezed,}) {
  return _then(_OptimizationState(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,rootsTotal: null == rootsTotal ? _self.rootsTotal : rootsTotal // ignore: cast_nullable_to_non_nullable
as int,rootsDone: null == rootsDone ? _self.rootsDone : rootsDone // ignore: cast_nullable_to_non_nullable
as int,currentRoot: freezed == currentRoot ? _self.currentRoot : currentRoot // ignore: cast_nullable_to_non_nullable
as String?,libraries: null == libraries ? _self._libraries : libraries // ignore: cast_nullable_to_non_nullable
as List<String>,comicsTotal: null == comicsTotal ? _self.comicsTotal : comicsTotal // ignore: cast_nullable_to_non_nullable
as int,comicsDone: null == comicsDone ? _self.comicsDone : comicsDone // ignore: cast_nullable_to_non_nullable
as int,imagesTotal: null == imagesTotal ? _self.imagesTotal : imagesTotal // ignore: cast_nullable_to_non_nullable
as int,imagesDone: null == imagesDone ? _self.imagesDone : imagesDone // ignore: cast_nullable_to_non_nullable
as int,currentFolder: freezed == currentFolder ? _self.currentFolder : currentFolder // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,logs: null == logs ? _self._logs : logs // ignore: cast_nullable_to_non_nullable
as Map<String, List<RunLogEntry>>,folders: null == folders ? _self._folders : folders // ignore: cast_nullable_to_non_nullable
as Map<String, FolderRunStatus>,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as Map<String, FolderRunResult>,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentLogFolder: freezed == currentLogFolder ? _self.currentLogFolder : currentLogFolder // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
