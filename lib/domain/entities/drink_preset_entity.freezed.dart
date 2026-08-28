// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drink_preset_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DrinkPresetEntity {

 int get id; int get amountMl; int get sortOrder;
/// Create a copy of DrinkPresetEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrinkPresetEntityCopyWith<DrinkPresetEntity> get copyWith => _$DrinkPresetEntityCopyWithImpl<DrinkPresetEntity>(this as DrinkPresetEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrinkPresetEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.amountMl, amountMl) || other.amountMl == amountMl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,amountMl,sortOrder);

@override
String toString() {
  return 'DrinkPresetEntity(id: $id, amountMl: $amountMl, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $DrinkPresetEntityCopyWith<$Res>  {
  factory $DrinkPresetEntityCopyWith(DrinkPresetEntity value, $Res Function(DrinkPresetEntity) _then) = _$DrinkPresetEntityCopyWithImpl;
@useResult
$Res call({
 int id, int amountMl, int sortOrder
});




}
/// @nodoc
class _$DrinkPresetEntityCopyWithImpl<$Res>
    implements $DrinkPresetEntityCopyWith<$Res> {
  _$DrinkPresetEntityCopyWithImpl(this._self, this._then);

  final DrinkPresetEntity _self;
  final $Res Function(DrinkPresetEntity) _then;

/// Create a copy of DrinkPresetEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amountMl = null,Object? sortOrder = null,}) {
  return _then(DrinkPresetEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amountMl: null == amountMl ? _self.amountMl : amountMl // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DrinkPresetEntity].
extension DrinkPresetEntityPatterns on DrinkPresetEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrinkPresetEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrinkPresetEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrinkPresetEntity value)  $default,){
final _that = this;
switch (_that) {
case _DrinkPresetEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrinkPresetEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DrinkPresetEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int amountMl,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrinkPresetEntity() when $default != null:
return $default(_that.id,_that.amountMl,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int amountMl,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _DrinkPresetEntity():
return $default(_that.id,_that.amountMl,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int amountMl,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _DrinkPresetEntity() when $default != null:
return $default(_that.id,_that.amountMl,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _DrinkPresetEntity implements DrinkPresetEntity {
  const _DrinkPresetEntity({required this.id, required this.amountMl, required this.sortOrder});
  

@override final  int id;
@override final  int amountMl;
@override final  int sortOrder;

/// Create a copy of DrinkPresetEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrinkPresetEntityCopyWith<_DrinkPresetEntity> get copyWith => __$DrinkPresetEntityCopyWithImpl<_DrinkPresetEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrinkPresetEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.amountMl, amountMl) || other.amountMl == amountMl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,amountMl,sortOrder);

@override
String toString() {
  return 'DrinkPresetEntity(id: $id, amountMl: $amountMl, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$DrinkPresetEntityCopyWith<$Res> implements $DrinkPresetEntityCopyWith<$Res> {
  factory _$DrinkPresetEntityCopyWith(_DrinkPresetEntity value, $Res Function(_DrinkPresetEntity) _then) = __$DrinkPresetEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, int amountMl, int sortOrder
});




}
/// @nodoc
class __$DrinkPresetEntityCopyWithImpl<$Res>
    implements _$DrinkPresetEntityCopyWith<$Res> {
  __$DrinkPresetEntityCopyWithImpl(this._self, this._then);

  final _DrinkPresetEntity _self;
  final $Res Function(_DrinkPresetEntity) _then;

/// Create a copy of DrinkPresetEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amountMl = null,Object? sortOrder = null,}) {
  return _then(_DrinkPresetEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amountMl: null == amountMl ? _self.amountMl : amountMl // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
