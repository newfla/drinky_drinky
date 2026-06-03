// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyProgress {

 int get totalMl; int get targetMl; List<WaterEntryEntity> get entries; String get dateKey;
/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyProgressCopyWith<DailyProgress> get copyWith => _$DailyProgressCopyWithImpl<DailyProgress>(this as DailyProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyProgress&&(identical(other.totalMl, totalMl) || other.totalMl == totalMl)&&(identical(other.targetMl, targetMl) || other.targetMl == targetMl)&&const DeepCollectionEquality().equals(other.entries, entries)&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey));
}


@override
int get hashCode => Object.hash(runtimeType,totalMl,targetMl,const DeepCollectionEquality().hash(entries),dateKey);

@override
String toString() {
  return 'DailyProgress(totalMl: $totalMl, targetMl: $targetMl, entries: $entries, dateKey: $dateKey)';
}


}

/// @nodoc
abstract mixin class $DailyProgressCopyWith<$Res>  {
  factory $DailyProgressCopyWith(DailyProgress value, $Res Function(DailyProgress) _then) = _$DailyProgressCopyWithImpl;
@useResult
$Res call({
 int totalMl, int targetMl, List<WaterEntryEntity> entries, String dateKey
});




}
/// @nodoc
class _$DailyProgressCopyWithImpl<$Res>
    implements $DailyProgressCopyWith<$Res> {
  _$DailyProgressCopyWithImpl(this._self, this._then);

  final DailyProgress _self;
  final $Res Function(DailyProgress) _then;

/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalMl = null,Object? targetMl = null,Object? entries = null,Object? dateKey = null,}) {
  return _then(_self.copyWith(
totalMl: null == totalMl ? _self.totalMl : totalMl // ignore: cast_nullable_to_non_nullable
as int,targetMl: null == targetMl ? _self.targetMl : targetMl // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<WaterEntryEntity>,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyProgress].
extension DailyProgressPatterns on DailyProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyProgress value)  $default,){
final _that = this;
switch (_that) {
case _DailyProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyProgress value)?  $default,){
final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalMl,  int targetMl,  List<WaterEntryEntity> entries,  String dateKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
return $default(_that.totalMl,_that.targetMl,_that.entries,_that.dateKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalMl,  int targetMl,  List<WaterEntryEntity> entries,  String dateKey)  $default,) {final _that = this;
switch (_that) {
case _DailyProgress():
return $default(_that.totalMl,_that.targetMl,_that.entries,_that.dateKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalMl,  int targetMl,  List<WaterEntryEntity> entries,  String dateKey)?  $default,) {final _that = this;
switch (_that) {
case _DailyProgress() when $default != null:
return $default(_that.totalMl,_that.targetMl,_that.entries,_that.dateKey);case _:
  return null;

}
}

}

/// @nodoc


class _DailyProgress implements DailyProgress {
  const _DailyProgress({required this.totalMl, required this.targetMl, required final  List<WaterEntryEntity> entries, required this.dateKey}): _entries = entries;
  

@override final  int totalMl;
@override final  int targetMl;
 final  List<WaterEntryEntity> _entries;
@override List<WaterEntryEntity> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

@override final  String dateKey;

/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyProgressCopyWith<_DailyProgress> get copyWith => __$DailyProgressCopyWithImpl<_DailyProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyProgress&&(identical(other.totalMl, totalMl) || other.totalMl == totalMl)&&(identical(other.targetMl, targetMl) || other.targetMl == targetMl)&&const DeepCollectionEquality().equals(other._entries, _entries)&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey));
}


@override
int get hashCode => Object.hash(runtimeType,totalMl,targetMl,const DeepCollectionEquality().hash(_entries),dateKey);

@override
String toString() {
  return 'DailyProgress(totalMl: $totalMl, targetMl: $targetMl, entries: $entries, dateKey: $dateKey)';
}


}

/// @nodoc
abstract mixin class _$DailyProgressCopyWith<$Res> implements $DailyProgressCopyWith<$Res> {
  factory _$DailyProgressCopyWith(_DailyProgress value, $Res Function(_DailyProgress) _then) = __$DailyProgressCopyWithImpl;
@override @useResult
$Res call({
 int totalMl, int targetMl, List<WaterEntryEntity> entries, String dateKey
});




}
/// @nodoc
class __$DailyProgressCopyWithImpl<$Res>
    implements _$DailyProgressCopyWith<$Res> {
  __$DailyProgressCopyWithImpl(this._self, this._then);

  final _DailyProgress _self;
  final $Res Function(_DailyProgress) _then;

/// Create a copy of DailyProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalMl = null,Object? targetMl = null,Object? entries = null,Object? dateKey = null,}) {
  return _then(_DailyProgress(
totalMl: null == totalMl ? _self.totalMl : totalMl // ignore: cast_nullable_to_non_nullable
as int,targetMl: null == targetMl ? _self.targetMl : targetMl // ignore: cast_nullable_to_non_nullable
as int,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<WaterEntryEntity>,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
