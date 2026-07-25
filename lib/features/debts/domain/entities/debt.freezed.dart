// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Debt {

 String get id; String get contactId; bool get isLent; String? get originLedgerEntryId; int get principalMinor; DateTime? get dueDate; DebtStatus get status; String? get note; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt; SyncStatus get syncStatus;
/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtCopyWith<Debt> get copyWith => _$DebtCopyWithImpl<Debt>(this as Debt, _$identity);

  /// Serializes this Debt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Debt&&(identical(other.id, id) || other.id == id)&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.isLent, isLent) || other.isLent == isLent)&&(identical(other.originLedgerEntryId, originLedgerEntryId) || other.originLedgerEntryId == originLedgerEntryId)&&(identical(other.principalMinor, principalMinor) || other.principalMinor == principalMinor)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contactId,isLent,originLedgerEntryId,principalMinor,dueDate,status,note,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Debt(id: $id, contactId: $contactId, isLent: $isLent, originLedgerEntryId: $originLedgerEntryId, principalMinor: $principalMinor, dueDate: $dueDate, status: $status, note: $note, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $DebtCopyWith<$Res>  {
  factory $DebtCopyWith(Debt value, $Res Function(Debt) _then) = _$DebtCopyWithImpl;
@useResult
$Res call({
 String id, String contactId, bool isLent, String? originLedgerEntryId, int principalMinor, DateTime? dueDate, DebtStatus status, String? note, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class _$DebtCopyWithImpl<$Res>
    implements $DebtCopyWith<$Res> {
  _$DebtCopyWithImpl(this._self, this._then);

  final Debt _self;
  final $Res Function(Debt) _then;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? contactId = null,Object? isLent = null,Object? originLedgerEntryId = freezed,Object? principalMinor = null,Object? dueDate = freezed,Object? status = null,Object? note = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(Debt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,isLent: null == isLent ? _self.isLent : isLent // ignore: cast_nullable_to_non_nullable
as bool,originLedgerEntryId: freezed == originLedgerEntryId ? _self.originLedgerEntryId : originLedgerEntryId // ignore: cast_nullable_to_non_nullable
as String?,principalMinor: null == principalMinor ? _self.principalMinor : principalMinor // ignore: cast_nullable_to_non_nullable
as int,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DebtStatus,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Debt].
extension DebtPatterns on Debt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Debt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Debt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Debt value)  $default,){
final _that = this;
switch (_that) {
case _Debt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Debt value)?  $default,){
final _that = this;
switch (_that) {
case _Debt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String contactId,  bool isLent,  String? originLedgerEntryId,  int principalMinor,  DateTime? dueDate,  DebtStatus status,  String? note,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Debt() when $default != null:
return $default(_that.id,_that.contactId,_that.isLent,_that.originLedgerEntryId,_that.principalMinor,_that.dueDate,_that.status,_that.note,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String contactId,  bool isLent,  String? originLedgerEntryId,  int principalMinor,  DateTime? dueDate,  DebtStatus status,  String? note,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Debt():
return $default(_that.id,_that.contactId,_that.isLent,_that.originLedgerEntryId,_that.principalMinor,_that.dueDate,_that.status,_that.note,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String contactId,  bool isLent,  String? originLedgerEntryId,  int principalMinor,  DateTime? dueDate,  DebtStatus status,  String? note,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Debt() when $default != null:
return $default(_that.id,_that.contactId,_that.isLent,_that.originLedgerEntryId,_that.principalMinor,_that.dueDate,_that.status,_that.note,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Debt implements Debt {
  const _Debt({required this.id, required this.contactId, required this.isLent, this.originLedgerEntryId, required this.principalMinor, this.dueDate, required this.status, this.note, required this.createdAt, required this.updatedAt, this.deletedAt, required this.syncStatus});
  factory _Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);

@override final  String id;
@override final  String contactId;
@override final  bool isLent;
@override final  String? originLedgerEntryId;
@override final  int principalMinor;
@override final  DateTime? dueDate;
@override final  DebtStatus status;
@override final  String? note;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override final  SyncStatus syncStatus;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtCopyWith<_Debt> get copyWith => __$DebtCopyWithImpl<_Debt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Debt&&(identical(other.id, id) || other.id == id)&&(identical(other.contactId, contactId) || other.contactId == contactId)&&(identical(other.isLent, isLent) || other.isLent == isLent)&&(identical(other.originLedgerEntryId, originLedgerEntryId) || other.originLedgerEntryId == originLedgerEntryId)&&(identical(other.principalMinor, principalMinor) || other.principalMinor == principalMinor)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,contactId,isLent,originLedgerEntryId,principalMinor,dueDate,status,note,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Debt(id: $id, contactId: $contactId, isLent: $isLent, originLedgerEntryId: $originLedgerEntryId, principalMinor: $principalMinor, dueDate: $dueDate, status: $status, note: $note, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$DebtCopyWith<$Res> implements $DebtCopyWith<$Res> {
  factory _$DebtCopyWith(_Debt value, $Res Function(_Debt) _then) = __$DebtCopyWithImpl;
@override @useResult
$Res call({
 String id, String contactId, bool isLent, String? originLedgerEntryId, int principalMinor, DateTime? dueDate, DebtStatus status, String? note, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class __$DebtCopyWithImpl<$Res>
    implements _$DebtCopyWith<$Res> {
  __$DebtCopyWithImpl(this._self, this._then);

  final _Debt _self;
  final $Res Function(_Debt) _then;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? contactId = null,Object? isLent = null,Object? originLedgerEntryId = freezed,Object? principalMinor = null,Object? dueDate = freezed,Object? status = null,Object? note = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_Debt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,contactId: null == contactId ? _self.contactId : contactId // ignore: cast_nullable_to_non_nullable
as String,isLent: null == isLent ? _self.isLent : isLent // ignore: cast_nullable_to_non_nullable
as bool,originLedgerEntryId: freezed == originLedgerEntryId ? _self.originLedgerEntryId : originLedgerEntryId // ignore: cast_nullable_to_non_nullable
as String?,principalMinor: null == principalMinor ? _self.principalMinor : principalMinor // ignore: cast_nullable_to_non_nullable
as int,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DebtStatus,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
