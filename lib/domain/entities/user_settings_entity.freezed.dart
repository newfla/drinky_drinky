// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserSettingsEntity {

 int get dailyTargetMl; int get notificationIntervalMinutes; int get dndStartHour; int get dndStartMinute; int get dndEndHour; int get dndEndMinute; bool get dndEnabled;
/// Create a copy of UserSettingsEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSettingsEntityCopyWith<UserSettingsEntity> get copyWith => _$UserSettingsEntityCopyWithImpl<UserSettingsEntity>(this as UserSettingsEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSettingsEntity&&(identical(other.dailyTargetMl, dailyTargetMl) || other.dailyTargetMl == dailyTargetMl)&&(identical(other.notificationIntervalMinutes, notificationIntervalMinutes) || other.notificationIntervalMinutes == notificationIntervalMinutes)&&(identical(other.dndStartHour, dndStartHour) || other.dndStartHour == dndStartHour)&&(identical(other.dndStartMinute, dndStartMinute) || other.dndStartMinute == dndStartMinute)&&(identical(other.dndEndHour, dndEndHour) || other.dndEndHour == dndEndHour)&&(identical(other.dndEndMinute, dndEndMinute) || other.dndEndMinute == dndEndMinute)&&(identical(other.dndEnabled, dndEnabled) || other.dndEnabled == dndEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,dailyTargetMl,notificationIntervalMinutes,dndStartHour,dndStartMinute,dndEndHour,dndEndMinute,dndEnabled);

@override
String toString() {
  return 'UserSettingsEntity(dailyTargetMl: $dailyTargetMl, notificationIntervalMinutes: $notificationIntervalMinutes, dndStartHour: $dndStartHour, dndStartMinute: $dndStartMinute, dndEndHour: $dndEndHour, dndEndMinute: $dndEndMinute, dndEnabled: $dndEnabled)';
}


}

/// @nodoc
abstract mixin class $UserSettingsEntityCopyWith<$Res>  {
  factory $UserSettingsEntityCopyWith(UserSettingsEntity value, $Res Function(UserSettingsEntity) _then) = _$UserSettingsEntityCopyWithImpl;
@useResult
$Res call({
 int dailyTargetMl, int notificationIntervalMinutes, int dndStartHour, int dndStartMinute, int dndEndHour, int dndEndMinute, bool dndEnabled
});




}
/// @nodoc
class _$UserSettingsEntityCopyWithImpl<$Res>
    implements $UserSettingsEntityCopyWith<$Res> {
  _$UserSettingsEntityCopyWithImpl(this._self, this._then);

  final UserSettingsEntity _self;
  final $Res Function(UserSettingsEntity) _then;

/// Create a copy of UserSettingsEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dailyTargetMl = null,Object? notificationIntervalMinutes = null,Object? dndStartHour = null,Object? dndStartMinute = null,Object? dndEndHour = null,Object? dndEndMinute = null,Object? dndEnabled = null,}) {
  return _then(_self.copyWith(
dailyTargetMl: null == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int,notificationIntervalMinutes: null == notificationIntervalMinutes ? _self.notificationIntervalMinutes : notificationIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,dndStartHour: null == dndStartHour ? _self.dndStartHour : dndStartHour // ignore: cast_nullable_to_non_nullable
as int,dndStartMinute: null == dndStartMinute ? _self.dndStartMinute : dndStartMinute // ignore: cast_nullable_to_non_nullable
as int,dndEndHour: null == dndEndHour ? _self.dndEndHour : dndEndHour // ignore: cast_nullable_to_non_nullable
as int,dndEndMinute: null == dndEndMinute ? _self.dndEndMinute : dndEndMinute // ignore: cast_nullable_to_non_nullable
as int,dndEnabled: null == dndEnabled ? _self.dndEnabled : dndEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSettingsEntity].
extension UserSettingsEntityPatterns on UserSettingsEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSettingsEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSettingsEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSettingsEntity value)  $default,){
final _that = this;
switch (_that) {
case _UserSettingsEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSettingsEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UserSettingsEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dailyTargetMl,  int notificationIntervalMinutes,  int dndStartHour,  int dndStartMinute,  int dndEndHour,  int dndEndMinute,  bool dndEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSettingsEntity() when $default != null:
return $default(_that.dailyTargetMl,_that.notificationIntervalMinutes,_that.dndStartHour,_that.dndStartMinute,_that.dndEndHour,_that.dndEndMinute,_that.dndEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dailyTargetMl,  int notificationIntervalMinutes,  int dndStartHour,  int dndStartMinute,  int dndEndHour,  int dndEndMinute,  bool dndEnabled)  $default,) {final _that = this;
switch (_that) {
case _UserSettingsEntity():
return $default(_that.dailyTargetMl,_that.notificationIntervalMinutes,_that.dndStartHour,_that.dndStartMinute,_that.dndEndHour,_that.dndEndMinute,_that.dndEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dailyTargetMl,  int notificationIntervalMinutes,  int dndStartHour,  int dndStartMinute,  int dndEndHour,  int dndEndMinute,  bool dndEnabled)?  $default,) {final _that = this;
switch (_that) {
case _UserSettingsEntity() when $default != null:
return $default(_that.dailyTargetMl,_that.notificationIntervalMinutes,_that.dndStartHour,_that.dndStartMinute,_that.dndEndHour,_that.dndEndMinute,_that.dndEnabled);case _:
  return null;

}
}

}

/// @nodoc


class _UserSettingsEntity implements UserSettingsEntity {
  const _UserSettingsEntity({required this.dailyTargetMl, required this.notificationIntervalMinutes, required this.dndStartHour, required this.dndStartMinute, required this.dndEndHour, required this.dndEndMinute, required this.dndEnabled});
  

@override final  int dailyTargetMl;
@override final  int notificationIntervalMinutes;
@override final  int dndStartHour;
@override final  int dndStartMinute;
@override final  int dndEndHour;
@override final  int dndEndMinute;
@override final  bool dndEnabled;

/// Create a copy of UserSettingsEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSettingsEntityCopyWith<_UserSettingsEntity> get copyWith => __$UserSettingsEntityCopyWithImpl<_UserSettingsEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSettingsEntity&&(identical(other.dailyTargetMl, dailyTargetMl) || other.dailyTargetMl == dailyTargetMl)&&(identical(other.notificationIntervalMinutes, notificationIntervalMinutes) || other.notificationIntervalMinutes == notificationIntervalMinutes)&&(identical(other.dndStartHour, dndStartHour) || other.dndStartHour == dndStartHour)&&(identical(other.dndStartMinute, dndStartMinute) || other.dndStartMinute == dndStartMinute)&&(identical(other.dndEndHour, dndEndHour) || other.dndEndHour == dndEndHour)&&(identical(other.dndEndMinute, dndEndMinute) || other.dndEndMinute == dndEndMinute)&&(identical(other.dndEnabled, dndEnabled) || other.dndEnabled == dndEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,dailyTargetMl,notificationIntervalMinutes,dndStartHour,dndStartMinute,dndEndHour,dndEndMinute,dndEnabled);

@override
String toString() {
  return 'UserSettingsEntity(dailyTargetMl: $dailyTargetMl, notificationIntervalMinutes: $notificationIntervalMinutes, dndStartHour: $dndStartHour, dndStartMinute: $dndStartMinute, dndEndHour: $dndEndHour, dndEndMinute: $dndEndMinute, dndEnabled: $dndEnabled)';
}


}

/// @nodoc
abstract mixin class _$UserSettingsEntityCopyWith<$Res> implements $UserSettingsEntityCopyWith<$Res> {
  factory _$UserSettingsEntityCopyWith(_UserSettingsEntity value, $Res Function(_UserSettingsEntity) _then) = __$UserSettingsEntityCopyWithImpl;
@override @useResult
$Res call({
 int dailyTargetMl, int notificationIntervalMinutes, int dndStartHour, int dndStartMinute, int dndEndHour, int dndEndMinute, bool dndEnabled
});




}
/// @nodoc
class __$UserSettingsEntityCopyWithImpl<$Res>
    implements _$UserSettingsEntityCopyWith<$Res> {
  __$UserSettingsEntityCopyWithImpl(this._self, this._then);

  final _UserSettingsEntity _self;
  final $Res Function(_UserSettingsEntity) _then;

/// Create a copy of UserSettingsEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dailyTargetMl = null,Object? notificationIntervalMinutes = null,Object? dndStartHour = null,Object? dndStartMinute = null,Object? dndEndHour = null,Object? dndEndMinute = null,Object? dndEnabled = null,}) {
  return _then(_UserSettingsEntity(
dailyTargetMl: null == dailyTargetMl ? _self.dailyTargetMl : dailyTargetMl // ignore: cast_nullable_to_non_nullable
as int,notificationIntervalMinutes: null == notificationIntervalMinutes ? _self.notificationIntervalMinutes : notificationIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,dndStartHour: null == dndStartHour ? _self.dndStartHour : dndStartHour // ignore: cast_nullable_to_non_nullable
as int,dndStartMinute: null == dndStartMinute ? _self.dndStartMinute : dndStartMinute // ignore: cast_nullable_to_non_nullable
as int,dndEndHour: null == dndEndHour ? _self.dndEndHour : dndEndHour // ignore: cast_nullable_to_non_nullable
as int,dndEndMinute: null == dndEndMinute ? _self.dndEndMinute : dndEndMinute // ignore: cast_nullable_to_non_nullable
as int,dndEnabled: null == dndEnabled ? _self.dndEnabled : dndEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
