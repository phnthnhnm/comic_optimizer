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

 bool get running; bool get starting; bool get paused; int get rootsTotal; int get rootsDone; String? get currentRoot; Map<String, List<String>> get logs; String? get currentLogFolder;
/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OptimizationStateCopyWith<OptimizationState> get copyWith => _$OptimizationStateCopyWithImpl<OptimizationState>(this as OptimizationState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OptimizationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OptimizationState&&(identical(other.running, _this.running) || other.running == _this.running)&&(identical(other.starting, _this.starting) || other.starting == _this.starting)&&(identical(other.paused, _this.paused) || other.paused == _this.paused)&&(identical(other.rootsTotal, _this.rootsTotal) || other.rootsTotal == _this.rootsTotal)&&(identical(other.rootsDone, _this.rootsDone) || other.rootsDone == _this.rootsDone)&&(identical(other.currentRoot, _this.currentRoot) || other.currentRoot == _this.currentRoot)&&const DeepCollectionEquality().equals(other.logs, _this.logs)&&(identical(other.currentLogFolder, _this.currentLogFolder) || other.currentLogFolder == _this.currentLogFolder));
}


@override
int get hashCode {
  final _this = this as OptimizationState;
  return Object.hash(runtimeType,_this.running,_this.starting,_this.paused,_this.rootsTotal,_this.rootsDone,_this.currentRoot,const DeepCollectionEquality().hash(_this.logs),_this.currentLogFolder);
}

@override
String toString() {
  final _this = this as OptimizationState;
  return 'OptimizationState(running: ${_this.running}, starting: ${_this.starting}, paused: ${_this.paused}, rootsTotal: ${_this.rootsTotal}, rootsDone: ${_this.rootsDone}, currentRoot: ${_this.currentRoot}, logs: ${_this.logs}, currentLogFolder: ${_this.currentLogFolder})';
}


}

/// @nodoc
abstract mixin class $OptimizationStateCopyWith<$Res>  {
  factory $OptimizationStateCopyWith(OptimizationState value, $Res Function(OptimizationState) _then) = _$OptimizationStateCopyWithImpl;
@useResult
$Res call({
 bool running, bool starting, bool paused, int rootsTotal, int rootsDone, String? currentRoot, Map<String, List<String>> logs, String? currentLogFolder
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
@pragma('vm:prefer-inline') @override $Res call({Object? running = null,Object? starting = null,Object? paused = null,Object? rootsTotal = null,Object? rootsDone = null,Object? currentRoot = freezed,Object? logs = null,Object? currentLogFolder = freezed,}) {
  return _then(OptimizationState(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,rootsTotal: null == rootsTotal ? _self.rootsTotal : rootsTotal // ignore: cast_nullable_to_non_nullable
as int,rootsDone: null == rootsDone ? _self.rootsDone : rootsDone // ignore: cast_nullable_to_non_nullable
as int,currentRoot: freezed == currentRoot ? _self.currentRoot : currentRoot // ignore: cast_nullable_to_non_nullable
as String?,logs: null == logs ? _self.logs : logs // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,currentLogFolder: freezed == currentLogFolder ? _self.currentLogFolder : currentLogFolder // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool running,  bool starting,  bool paused,  int rootsTotal,  int rootsDone,  String? currentRoot,  Map<String, List<String>> logs,  String? currentLogFolder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
return $default(_that.running,_that.starting,_that.paused,_that.rootsTotal,_that.rootsDone,_that.currentRoot,_that.logs,_that.currentLogFolder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool running,  bool starting,  bool paused,  int rootsTotal,  int rootsDone,  String? currentRoot,  Map<String, List<String>> logs,  String? currentLogFolder)  $default,) {final _that = this;
switch (_that) {
case _OptimizationState():
return $default(_that.running,_that.starting,_that.paused,_that.rootsTotal,_that.rootsDone,_that.currentRoot,_that.logs,_that.currentLogFolder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool running,  bool starting,  bool paused,  int rootsTotal,  int rootsDone,  String? currentRoot,  Map<String, List<String>> logs,  String? currentLogFolder)?  $default,) {final _that = this;
switch (_that) {
case _OptimizationState() when $default != null:
return $default(_that.running,_that.starting,_that.paused,_that.rootsTotal,_that.rootsDone,_that.currentRoot,_that.logs,_that.currentLogFolder);case _:
  return null;

}
}

}

/// @nodoc


class _OptimizationState extends OptimizationState {
  const _OptimizationState({this.running = false, this.starting = false, this.paused = false, this.rootsTotal = 0, this.rootsDone = 0, this.currentRoot,  Map<String, List<String>> logs = const <String, List<String>>{}, this.currentLogFolder}): _logs = logs,super._();
  

@override@JsonKey() final  bool running;
@override@JsonKey() final  bool starting;
@override@JsonKey() final  bool paused;
@override@JsonKey() final  int rootsTotal;
@override@JsonKey() final  int rootsDone;
@override final  String? currentRoot;
 final  Map<String, List<String>> _logs;
@override@JsonKey() Map<String, List<String>> get logs {
  if (_logs is EqualUnmodifiableMapView) return _logs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_logs);
}

@override final  String? currentLogFolder;

/// Create a copy of OptimizationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OptimizationStateCopyWith<_OptimizationState> get copyWith => __$OptimizationStateCopyWithImpl<_OptimizationState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OptimizationState&&(identical(other.running, running) || other.running == running)&&(identical(other.starting, starting) || other.starting == starting)&&(identical(other.paused, paused) || other.paused == paused)&&(identical(other.rootsTotal, rootsTotal) || other.rootsTotal == rootsTotal)&&(identical(other.rootsDone, rootsDone) || other.rootsDone == rootsDone)&&(identical(other.currentRoot, currentRoot) || other.currentRoot == currentRoot)&&const DeepCollectionEquality().equals(other.logs, _logs)&&(identical(other.currentLogFolder, currentLogFolder) || other.currentLogFolder == currentLogFolder));
}


@override
int get hashCode {
    return Object.hash(runtimeType,running,starting,paused,rootsTotal,rootsDone,currentRoot,const DeepCollectionEquality().hash(_logs),currentLogFolder);
}

@override
String toString() {
    return 'OptimizationState(running: $running, starting: $starting, paused: $paused, rootsTotal: $rootsTotal, rootsDone: $rootsDone, currentRoot: $currentRoot, logs: $logs, currentLogFolder: $currentLogFolder)';
}


}

/// @nodoc
abstract mixin class _$OptimizationStateCopyWith<$Res> implements $OptimizationStateCopyWith<$Res> {
  factory _$OptimizationStateCopyWith(_OptimizationState value, $Res Function(_OptimizationState) _then) = __$OptimizationStateCopyWithImpl;
@override @useResult
$Res call({
 bool running, bool starting, bool paused, int rootsTotal, int rootsDone, String? currentRoot, Map<String, List<String>> logs, String? currentLogFolder
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
@override @pragma('vm:prefer-inline') $Res call({Object? running = null,Object? starting = null,Object? paused = null,Object? rootsTotal = null,Object? rootsDone = null,Object? currentRoot = freezed,Object? logs = null,Object? currentLogFolder = freezed,}) {
  return _then(_OptimizationState(
running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,starting: null == starting ? _self.starting : starting // ignore: cast_nullable_to_non_nullable
as bool,paused: null == paused ? _self.paused : paused // ignore: cast_nullable_to_non_nullable
as bool,rootsTotal: null == rootsTotal ? _self.rootsTotal : rootsTotal // ignore: cast_nullable_to_non_nullable
as int,rootsDone: null == rootsDone ? _self.rootsDone : rootsDone // ignore: cast_nullable_to_non_nullable
as int,currentRoot: freezed == currentRoot ? _self.currentRoot : currentRoot // ignore: cast_nullable_to_non_nullable
as String?,logs: null == logs ? _self._logs : logs // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,currentLogFolder: freezed == currentLogFolder ? _self.currentLogFolder : currentLogFolder // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
