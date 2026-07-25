// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LedgerEntry {

 String get id; String get accountId; String? get categoryId; String? get recurringInstanceId; String? get debtId; String? get splitId; String? get transferId; int get amountMinor; MoneyDirection get direction; LedgerOrigin get origin; DateTime get occurredAt; String? get note; String? get metadataJson; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt; SyncStatus get syncStatus;
/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LedgerEntryCopyWith<LedgerEntry> get copyWith => _$LedgerEntryCopyWithImpl<LedgerEntry>(this as LedgerEntry, _$identity);

  /// Serializes this LedgerEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LedgerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.recurringInstanceId, recurringInstanceId) || other.recurringInstanceId == recurringInstanceId)&&(identical(other.debtId, debtId) || other.debtId == debtId)&&(identical(other.splitId, splitId) || other.splitId == splitId)&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.metadataJson, metadataJson) || other.metadataJson == metadataJson)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountId,categoryId,recurringInstanceId,debtId,splitId,transferId,amountMinor,direction,origin,occurredAt,note,metadataJson,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'LedgerEntry(id: $id, accountId: $accountId, categoryId: $categoryId, recurringInstanceId: $recurringInstanceId, debtId: $debtId, splitId: $splitId, transferId: $transferId, amountMinor: $amountMinor, direction: $direction, origin: $origin, occurredAt: $occurredAt, note: $note, metadataJson: $metadataJson, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $LedgerEntryCopyWith<$Res>  {
  factory $LedgerEntryCopyWith(LedgerEntry value, $Res Function(LedgerEntry) _then) = _$LedgerEntryCopyWithImpl;
@useResult
$Res call({
 String id, String accountId, String? categoryId, String? recurringInstanceId, String? debtId, String? splitId, String? transferId, int amountMinor, MoneyDirection direction, LedgerOrigin origin, DateTime occurredAt, String? note, String? metadataJson, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class _$LedgerEntryCopyWithImpl<$Res>
    implements $LedgerEntryCopyWith<$Res> {
  _$LedgerEntryCopyWithImpl(this._self, this._then);

  final LedgerEntry _self;
  final $Res Function(LedgerEntry) _then;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? categoryId = freezed,Object? recurringInstanceId = freezed,Object? debtId = freezed,Object? splitId = freezed,Object? transferId = freezed,Object? amountMinor = null,Object? direction = null,Object? origin = null,Object? occurredAt = null,Object? note = freezed,Object? metadataJson = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(LedgerEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,recurringInstanceId: freezed == recurringInstanceId ? _self.recurringInstanceId : recurringInstanceId // ignore: cast_nullable_to_non_nullable
as String?,debtId: freezed == debtId ? _self.debtId : debtId // ignore: cast_nullable_to_non_nullable
as String?,splitId: freezed == splitId ? _self.splitId : splitId // ignore: cast_nullable_to_non_nullable
as String?,transferId: freezed == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String?,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MoneyDirection,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LedgerOrigin,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,metadataJson: freezed == metadataJson ? _self.metadataJson : metadataJson // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [LedgerEntry].
extension LedgerEntryPatterns on LedgerEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LedgerEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LedgerEntry value)  $default,){
final _that = this;
switch (_that) {
case _LedgerEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LedgerEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountId,  String? categoryId,  String? recurringInstanceId,  String? debtId,  String? splitId,  String? transferId,  int amountMinor,  MoneyDirection direction,  LedgerOrigin origin,  DateTime occurredAt,  String? note,  String? metadataJson,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
return $default(_that.id,_that.accountId,_that.categoryId,_that.recurringInstanceId,_that.debtId,_that.splitId,_that.transferId,_that.amountMinor,_that.direction,_that.origin,_that.occurredAt,_that.note,_that.metadataJson,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountId,  String? categoryId,  String? recurringInstanceId,  String? debtId,  String? splitId,  String? transferId,  int amountMinor,  MoneyDirection direction,  LedgerOrigin origin,  DateTime occurredAt,  String? note,  String? metadataJson,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _LedgerEntry():
return $default(_that.id,_that.accountId,_that.categoryId,_that.recurringInstanceId,_that.debtId,_that.splitId,_that.transferId,_that.amountMinor,_that.direction,_that.origin,_that.occurredAt,_that.note,_that.metadataJson,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountId,  String? categoryId,  String? recurringInstanceId,  String? debtId,  String? splitId,  String? transferId,  int amountMinor,  MoneyDirection direction,  LedgerOrigin origin,  DateTime occurredAt,  String? note,  String? metadataJson,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _LedgerEntry() when $default != null:
return $default(_that.id,_that.accountId,_that.categoryId,_that.recurringInstanceId,_that.debtId,_that.splitId,_that.transferId,_that.amountMinor,_that.direction,_that.origin,_that.occurredAt,_that.note,_that.metadataJson,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LedgerEntry implements LedgerEntry {
  const _LedgerEntry({required this.id, required this.accountId, this.categoryId, this.recurringInstanceId, this.debtId, this.splitId, this.transferId, required this.amountMinor, required this.direction, required this.origin, required this.occurredAt, this.note, this.metadataJson, required this.createdAt, required this.updatedAt, this.deletedAt, required this.syncStatus});
  factory _LedgerEntry.fromJson(Map<String, dynamic> json) => _$LedgerEntryFromJson(json);

@override final  String id;
@override final  String accountId;
@override final  String? categoryId;
@override final  String? recurringInstanceId;
@override final  String? debtId;
@override final  String? splitId;
@override final  String? transferId;
@override final  int amountMinor;
@override final  MoneyDirection direction;
@override final  LedgerOrigin origin;
@override final  DateTime occurredAt;
@override final  String? note;
@override final  String? metadataJson;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override final  SyncStatus syncStatus;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LedgerEntryCopyWith<_LedgerEntry> get copyWith => __$LedgerEntryCopyWithImpl<_LedgerEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LedgerEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LedgerEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.recurringInstanceId, recurringInstanceId) || other.recurringInstanceId == recurringInstanceId)&&(identical(other.debtId, debtId) || other.debtId == debtId)&&(identical(other.splitId, splitId) || other.splitId == splitId)&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.metadataJson, metadataJson) || other.metadataJson == metadataJson)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountId,categoryId,recurringInstanceId,debtId,splitId,transferId,amountMinor,direction,origin,occurredAt,note,metadataJson,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'LedgerEntry(id: $id, accountId: $accountId, categoryId: $categoryId, recurringInstanceId: $recurringInstanceId, debtId: $debtId, splitId: $splitId, transferId: $transferId, amountMinor: $amountMinor, direction: $direction, origin: $origin, occurredAt: $occurredAt, note: $note, metadataJson: $metadataJson, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$LedgerEntryCopyWith<$Res> implements $LedgerEntryCopyWith<$Res> {
  factory _$LedgerEntryCopyWith(_LedgerEntry value, $Res Function(_LedgerEntry) _then) = __$LedgerEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountId, String? categoryId, String? recurringInstanceId, String? debtId, String? splitId, String? transferId, int amountMinor, MoneyDirection direction, LedgerOrigin origin, DateTime occurredAt, String? note, String? metadataJson, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class __$LedgerEntryCopyWithImpl<$Res>
    implements _$LedgerEntryCopyWith<$Res> {
  __$LedgerEntryCopyWithImpl(this._self, this._then);

  final _LedgerEntry _self;
  final $Res Function(_LedgerEntry) _then;

/// Create a copy of LedgerEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? categoryId = freezed,Object? recurringInstanceId = freezed,Object? debtId = freezed,Object? splitId = freezed,Object? transferId = freezed,Object? amountMinor = null,Object? direction = null,Object? origin = null,Object? occurredAt = null,Object? note = freezed,Object? metadataJson = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_LedgerEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,recurringInstanceId: freezed == recurringInstanceId ? _self.recurringInstanceId : recurringInstanceId // ignore: cast_nullable_to_non_nullable
as String?,debtId: freezed == debtId ? _self.debtId : debtId // ignore: cast_nullable_to_non_nullable
as String?,splitId: freezed == splitId ? _self.splitId : splitId // ignore: cast_nullable_to_non_nullable
as String?,transferId: freezed == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String?,amountMinor: null == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as MoneyDirection,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as LedgerOrigin,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,metadataJson: freezed == metadataJson ? _self.metadataJson : metadataJson // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
