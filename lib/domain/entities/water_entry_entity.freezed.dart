// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'water_entry_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WaterEntryEntity {

 int get id; int get amountMl; DateTime get loggedAt; String get dateKey;
/// Create a copy of WaterEntryEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WaterEntryEntityCopyWith<WaterEntryEntity> get copyWith => _$WaterEntryEntityCopyWithImpl<WaterEntryEntity>(this as WaterEntryEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WaterEntryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.amountMl, amountMl) || other.amountMl == amountMl)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt)&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey));
}


@override
int get hashCode => Object.hash(runtimeType,id,amountMl,loggedAt,dateKey);

@override
String toString() {
  return 'WaterEntryEntity(id: $id, amountMl: $amountMl, loggedAt: $loggedAt, dateKey: $dateKey)';
}


}

/// @nodoc
abstract mixin class $WaterEntryEntityCopyWith<$Res>  {
  factory $WaterEntryEntityCopyWith(WaterEntryEntity value, $Res Function(WaterEntryEntity) _then) = _$WaterEntryEntityCopyWithImpl;
@useResult
$Res call({
 int id, int amountMl, DateTime loggedAt, String dateKey
});




}
/// @nodoc
class _$WaterEntryEntityCopyWithImpl<$Res>
    implements $WaterEntryEntityCopyWith<$Res> {
  _$WaterEntryEntityCopyWithImpl(this._self, this._then);

  final WaterEntryEntity _self;
  final $Res Function(WaterEntryEntity) _then;

/// Create a copy of WaterEntryEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amountMl = null,Object? loggedAt = null,Object? dateKey = null,}) {
  return _then(WaterEntryEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amountMl: null == amountMl ? _self.amountMl : amountMl // ignore: cast_nullable_to_non_nullable
as int,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WaterEntryEntity].
extension WaterEntryEntityPatterns on WaterEntryEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WaterEntryEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WaterEntryEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WaterEntryEntity value)  $default,){
final _that = this;
switch (_that) {
case _WaterEntryEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WaterEntryEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WaterEntryEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int amountMl,  DateTime loggedAt,  String dateKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WaterEntryEntity() when $default != null:
return $default(_that.id,_that.amountMl,_that.loggedAt,_that.dateKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int amountMl,  DateTime loggedAt,  String dateKey)  $default,) {final _that = this;
switch (_that) {
case _WaterEntryEntity():
return $default(_that.id,_that.amountMl,_that.loggedAt,_that.dateKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int amountMl,  DateTime loggedAt,  String dateKey)?  $default,) {final _that = this;
switch (_that) {
case _WaterEntryEntity() when $default != null:
return $default(_that.id,_that.amountMl,_that.loggedAt,_that.dateKey);case _:
  return null;

}
}

}

/// @nodoc


class _WaterEntryEntity implements WaterEntryEntity {
  const _WaterEntryEntity({required this.id, required this.amountMl, required this.loggedAt, required this.dateKey});
  

@override final  int id;
@override final  int amountMl;
@override final  DateTime loggedAt;
@override final  String dateKey;

/// Create a copy of WaterEntryEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WaterEntryEntityCopyWith<_WaterEntryEntity> get copyWith => __$WaterEntryEntityCopyWithImpl<_WaterEntryEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WaterEntryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.amountMl, amountMl) || other.amountMl == amountMl)&&(identical(other.loggedAt, loggedAt) || other.loggedAt == loggedAt)&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey));
}


@override
int get hashCode => Object.hash(runtimeType,id,amountMl,loggedAt,dateKey);

@override
String toString() {
  return 'WaterEntryEntity(id: $id, amountMl: $amountMl, loggedAt: $loggedAt, dateKey: $dateKey)';
}


}

/// @nodoc
abstract mixin class _$WaterEntryEntityCopyWith<$Res> implements $WaterEntryEntityCopyWith<$Res> {
  factory _$WaterEntryEntityCopyWith(_WaterEntryEntity value, $Res Function(_WaterEntryEntity) _then) = __$WaterEntryEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, int amountMl, DateTime loggedAt, String dateKey
});




}
/// @nodoc
class __$WaterEntryEntityCopyWithImpl<$Res>
    implements _$WaterEntryEntityCopyWith<$Res> {
  __$WaterEntryEntityCopyWithImpl(this._self, this._then);

  final _WaterEntryEntity _self;
  final $Res Function(_WaterEntryEntity) _then;

/// Create a copy of WaterEntryEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amountMl = null,Object? loggedAt = null,Object? dateKey = null,}) {
  return _then(_WaterEntryEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amountMl: null == amountMl ? _self.amountMl : amountMl // ignore: cast_nullable_to_non_nullable
as int,loggedAt: null == loggedAt ? _self.loggedAt : loggedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dateKey: null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
