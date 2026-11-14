// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LibraryEntry {

 String get path; String? get preset; String? get outputDirectory; bool? get safeRunOverride;
/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryEntryCopyWith<LibraryEntry> get copyWith => _$LibraryEntryCopyWithImpl<LibraryEntry>(this as LibraryEntry, _$identity);

  /// Serializes this LibraryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LibraryEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryEntry&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.preset, _this.preset) || other.preset == _this.preset)&&(identical(other.outputDirectory, _this.outputDirectory) || other.outputDirectory == _this.outputDirectory)&&(identical(other.safeRunOverride, _this.safeRunOverride) || other.safeRunOverride == _this.safeRunOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LibraryEntry;
  return Object.hash(runtimeType,_this.path,_this.preset,_this.outputDirectory,_this.safeRunOverride);
}

@override
String toString() {
  final _this = this as LibraryEntry;
  return 'LibraryEntry(path: ${_this.path}, preset: ${_this.preset}, outputDirectory: ${_this.outputDirectory}, safeRunOverride: ${_this.safeRunOverride})';
}


}

/// @nodoc
abstract mixin class $LibraryEntryCopyWith<$Res>  {
  factory $LibraryEntryCopyWith(LibraryEntry value, $Res Function(LibraryEntry) _then) = _$LibraryEntryCopyWithImpl;
@useResult
$Res call({
 String path, String? preset, String? outputDirectory, bool? safeRunOverride
});




}
/// @nodoc
class _$LibraryEntryCopyWithImpl<$Res>
    implements $LibraryEntryCopyWith<$Res> {
  _$LibraryEntryCopyWithImpl(this._self, this._then);

  final LibraryEntry _self;
  final $Res Function(LibraryEntry) _then;

/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? preset = freezed,Object? outputDirectory = freezed,Object? safeRunOverride = freezed,}) {
  return _then(LibraryEntry(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,preset: freezed == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as String?,outputDirectory: freezed == outputDirectory ? _self.outputDirectory : outputDirectory // ignore: cast_nullable_to_non_nullable
as String?,safeRunOverride: freezed == safeRunOverride ? _self.safeRunOverride : safeRunOverride // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryEntry].
extension LibraryEntryPatterns on LibraryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryEntry value)  $default,){
final _that = this;
switch (_that) {
case _LibraryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String? preset,  String? outputDirectory,  bool? safeRunOverride)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
return $default(_that.path,_that.preset,_that.outputDirectory,_that.safeRunOverride);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String? preset,  String? outputDirectory,  bool? safeRunOverride)  $default,) {final _that = this;
switch (_that) {
case _LibraryEntry():
return $default(_that.path,_that.preset,_that.outputDirectory,_that.safeRunOverride);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String? preset,  String? outputDirectory,  bool? safeRunOverride)?  $default,) {final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
return $default(_that.path,_that.preset,_that.outputDirectory,_that.safeRunOverride);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LibraryEntry implements LibraryEntry {
  const _LibraryEntry({required this.path, this.preset, this.outputDirectory, this.safeRunOverride});
  factory _LibraryEntry.fromJson(Map<String, dynamic> json) => _$LibraryEntryFromJson(json);

@override final  String path;
@override final  String? preset;
@override final  String? outputDirectory;
@override final  bool? safeRunOverride;

/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryEntryCopyWith<_LibraryEntry> get copyWith => __$LibraryEntryCopyWithImpl<_LibraryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryEntry&&(identical(other.path, path) || other.path == path)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.outputDirectory, outputDirectory) || other.outputDirectory == outputDirectory)&&(identical(other.safeRunOverride, safeRunOverride) || other.safeRunOverride == safeRunOverride));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,path,preset,outputDirectory,safeRunOverride);
}

@override
String toString() {
    return 'LibraryEntry(path: $path, preset: $preset, outputDirectory: $outputDirectory, safeRunOverride: $safeRunOverride)';
}


}

/// @nodoc
abstract mixin class _$LibraryEntryCopyWith<$Res> implements $LibraryEntryCopyWith<$Res> {
  factory _$LibraryEntryCopyWith(_LibraryEntry value, $Res Function(_LibraryEntry) _then) = __$LibraryEntryCopyWithImpl;
@override @useResult
$Res call({
 String path, String? preset, String? outputDirectory, bool? safeRunOverride
});




}
/// @nodoc
class __$LibraryEntryCopyWithImpl<$Res>
    implements _$LibraryEntryCopyWith<$Res> {
  __$LibraryEntryCopyWithImpl(this._self, this._then);

  final _LibraryEntry _self;
  final $Res Function(_LibraryEntry) _then;

/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? preset = freezed,Object? outputDirectory = freezed,Object? safeRunOverride = freezed,}) {
  return _then(_LibraryEntry(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,preset: freezed == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as String?,outputDirectory: freezed == outputDirectory ? _self.outputDirectory : outputDirectory // ignore: cast_nullable_to_non_nullable
as String?,safeRunOverride: freezed == safeRunOverride ? _self.safeRunOverride : safeRunOverride // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
