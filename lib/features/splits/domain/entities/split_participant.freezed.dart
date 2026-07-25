// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'split_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SplitParticipant {

 String get id; String get splitId; String get contactId; int get shareMinor; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of SplitParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitParticipantCopyWith<SplitParticipant> get copyWith => _$SplitParticipantCopyWithImpl<SplitParticipant>(this as SplitParticipant, _$identity);

  /// Serializes this SplitParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplitParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.splitId, splitId) || other.splitId == splitId)&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.shareMinor, shareMinor) || other.shareMinor == shareMinor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,splitId,contactId,shareMinor,createdAt,updatedAt);

@override
String toString() {
  return 'SplitParticipant(id: $id, splitId: $splitId, contactId: $contactId, shareMinor: $shareMinor, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SplitParticipantCopyWith<$Res>  {
  factory $SplitParticipantCopyWith(SplitParticipant value, $Res Function(SplitParticipant) _then) = _$SplitParticipantCopyWithImpl;
@useResult
$Res call({
 String id, String splitId, String contactId, int shareMinor, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SplitParticipantCopyWithImpl<$Res>
    implements $SplitParticipantCopyWith<$Res> {
  _$SplitParticipantCopyWithImpl(this._self, this._then);

  final SplitParticipant _self;
  final $Res Function(SplitParticipant) _then;

/// Create a copy of SplitParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? splitId = null,Object? contactId = null,Object? shareMinor = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(SplitParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,splitId: null == splitId ? _self.splitId : splitId // ignore: cast_nullable_to_non_nullable
as String,contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,shareMinor: null == shareMinor ? _self.shareMinor : shareMinor // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SplitParticipant].
extension SplitParticipantPatterns on SplitParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SplitParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SplitParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SplitParticipant value)  $default,){
final _that = this;
switch (_that) {
case _SplitParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SplitParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _SplitParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String splitId,  String contactId,  int shareMinor,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SplitParticipant() when $default != null:
return $default(_that.id,_that.splitId,_that.contactId,_that.shareMinor,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String splitId,  String contactId,  int shareMinor,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SplitParticipant():
return $default(_that.id,_that.splitId,_that.contactId,_that.shareMinor,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String splitId,  String contactId,  int shareMinor,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SplitParticipant() when $default != null:
return $default(_that.id,_that.splitId,_that.contactId,_that.shareMinor,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SplitParticipant implements SplitParticipant {
  const _SplitParticipant({required this.id, required this.splitId, required this.contactId, required this.shareMinor, required this.createdAt, required this.updatedAt});
  factory _SplitParticipant.fromJson(Map<String, dynamic> json) => _$SplitParticipantFromJson(json);

@override final  String id;
@override final  String splitId;
@override final  String contactId;
@override final  int shareMinor;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of SplitParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SplitParticipantCopyWith<_SplitParticipant> get copyWith => __$SplitParticipantCopyWithImpl<_SplitParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SplitParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.splitId, splitId) || other.splitId == splitId)&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.shareMinor, shareMinor) || other.shareMinor == shareMinor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,splitId,contactId,shareMinor,createdAt,updatedAt);

@override
String toString() {
  return 'SplitParticipant(id: $id, splitId: $splitId, contactId: $contactId, shareMinor: $shareMinor, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SplitParticipantCopyWith<$Res> implements $SplitParticipantCopyWith<$Res> {
  factory _$SplitParticipantCopyWith(_SplitParticipant value, $Res Function(_SplitParticipant) _then) = __$SplitParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id, String splitId, String contactId, int shareMinor, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SplitParticipantCopyWithImpl<$Res>
    implements _$SplitParticipantCopyWith<$Res> {
  __$SplitParticipantCopyWithImpl(this._self, this._then);

  final _SplitParticipant _self;
  final $Res Function(_SplitParticipant) _then;

/// Create a copy of SplitParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? splitId = null,Object? contactId = null,Object? shareMinor = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_SplitParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,splitId: null == splitId ? _self.splitId : splitId // ignore: cast_nullable_to_non_nullable
as String,contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,shareMinor: null == shareMinor ? _self.shareMinor : shareMinor // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
