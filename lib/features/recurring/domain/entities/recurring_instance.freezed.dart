// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_instance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringInstance {

 String get id; String get recurringRuleId; DateTime get scheduledDate; String? get ledgerEntryId; RecurringInstanceStatus get status; DateTime get createdAt; DateTime get updatedAt; SyncStatus get syncStatus;
/// Create a copy of RecurringInstance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringInstanceCopyWith<RecurringInstance> get copyWith => _$RecurringInstanceCopyWithImpl<RecurringInstance>(this as RecurringInstance, _$identity);

  /// Serializes this RecurringInstance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringInstance&&(identical(other.id, id) || other.id == id)&&(identical(other.recurringRuleId, recurringRuleId) || other.recurringRuleId == recurringRuleId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.ledgerEntryId, ledgerEntryId) || other.ledgerEntryId == ledgerEntryId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recurringRuleId,scheduledDate,ledgerEntryId,status,createdAt,updatedAt,syncStatus);

@override
String toString() {
  return 'RecurringInstance(id: $id, recurringRuleId: $recurringRuleId, scheduledDate: $scheduledDate, ledgerEntryId: $ledgerEntryId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $RecurringInstanceCopyWith<$Res>  {
  factory $RecurringInstanceCopyWith(RecurringInstance value, $Res Function(RecurringInstance) _then) = _$RecurringInstanceCopyWithImpl;
@useResult
$Res call({
 String id, String recurringRuleId, DateTime scheduledDate, String? ledgerEntryId, RecurringInstanceStatus status, DateTime createdAt, DateTime updatedAt, SyncStatus syncStatus
});




}
/// @nodoc
class _$RecurringInstanceCopyWithImpl<$Res>
    implements $RecurringInstanceCopyWith<$Res> {
  _$RecurringInstanceCopyWithImpl(this._self, this._then);

  final RecurringInstance _self;
  final $Res Function(RecurringInstance) _then;

/// Create a copy of RecurringInstance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recurringRuleId = null,Object? scheduledDate = null,Object? ledgerEntryId = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? syncStatus = null,}) {
  return _then(RecurringInstance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recurringRuleId: null == recurringRuleId ? _self.recurringRuleId : recurringRuleId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,ledgerEntryId: freezed == ledgerEntryId ? _self.ledgerEntryId : ledgerEntryId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecurringInstanceStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringInstance].
extension RecurringInstancePatterns on RecurringInstance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringInstance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringInstance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringInstance value)  $default,){
final _that = this;
switch (_that) {
case _RecurringInstance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringInstance value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringInstance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String recurringRuleId,  DateTime scheduledDate,  String? ledgerEntryId,  RecurringInstanceStatus status,  DateTime createdAt,  DateTime updatedAt,  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringInstance() when $default != null:
return $default(_that.id,_that.recurringRuleId,_that.scheduledDate,_that.ledgerEntryId,_that.status,_that.createdAt,_that.updatedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String recurringRuleId,  DateTime scheduledDate,  String? ledgerEntryId,  RecurringInstanceStatus status,  DateTime createdAt,  DateTime updatedAt,  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _RecurringInstance():
return $default(_that.id,_that.recurringRuleId,_that.scheduledDate,_that.ledgerEntryId,_that.status,_that.createdAt,_that.updatedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String recurringRuleId,  DateTime scheduledDate,  String? ledgerEntryId,  RecurringInstanceStatus status,  DateTime createdAt,  DateTime updatedAt,  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _RecurringInstance() when $default != null:
return $default(_that.id,_that.recurringRuleId,_that.scheduledDate,_that.ledgerEntryId,_that.status,_that.createdAt,_that.updatedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringInstance implements RecurringInstance {
  const _RecurringInstance({required this.id, required this.recurringRuleId, required this.scheduledDate, this.ledgerEntryId, required this.status, required this.createdAt, required this.updatedAt, required this.syncStatus});
  factory _RecurringInstance.fromJson(Map<String, dynamic> json) => _$RecurringInstanceFromJson(json);

@override final  String id;
@override final  String recurringRuleId;
@override final  DateTime scheduledDate;
@override final  String? ledgerEntryId;
@override final  RecurringInstanceStatus status;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  SyncStatus syncStatus;

/// Create a copy of RecurringInstance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringInstanceCopyWith<_RecurringInstance> get copyWith => __$RecurringInstanceCopyWithImpl<_RecurringInstance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringInstanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringInstance&&(identical(other.id, id) || other.id == id)&&(identical(other.recurringRuleId, recurringRuleId) || other.recurringRuleId == recurringRuleId)&&(identical(other.scheduledDate, scheduledDate) || other.scheduledDate == scheduledDate)&&(identical(other.ledgerEntryId, ledgerEntryId) || other.ledgerEntryId == ledgerEntryId)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recurringRuleId,scheduledDate,ledgerEntryId,status,createdAt,updatedAt,syncStatus);

@override
String toString() {
  return 'RecurringInstance(id: $id, recurringRuleId: $recurringRuleId, scheduledDate: $scheduledDate, ledgerEntryId: $ledgerEntryId, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$RecurringInstanceCopyWith<$Res> implements $RecurringInstanceCopyWith<$Res> {
  factory _$RecurringInstanceCopyWith(_RecurringInstance value, $Res Function(_RecurringInstance) _then) = __$RecurringInstanceCopyWithImpl;
@override @useResult
$Res call({
 String id, String recurringRuleId, DateTime scheduledDate, String? ledgerEntryId, RecurringInstanceStatus status, DateTime createdAt, DateTime updatedAt, SyncStatus syncStatus
});




}
/// @nodoc
class __$RecurringInstanceCopyWithImpl<$Res>
    implements _$RecurringInstanceCopyWith<$Res> {
  __$RecurringInstanceCopyWithImpl(this._self, this._then);

  final _RecurringInstance _self;
  final $Res Function(_RecurringInstance) _then;

/// Create a copy of RecurringInstance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recurringRuleId = null,Object? scheduledDate = null,Object? ledgerEntryId = freezed,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? syncStatus = null,}) {
  return _then(_RecurringInstance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recurringRuleId: null == recurringRuleId ? _self.recurringRuleId : recurringRuleId // ignore: cast_nullable_to_non_nullable
as String,scheduledDate: null == scheduledDate ? _self.scheduledDate : scheduledDate // ignore: cast_nullable_to_non_nullable
as DateTime,ledgerEntryId: freezed == ledgerEntryId ? _self.ledgerEntryId : ledgerEntryId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecurringInstanceStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
