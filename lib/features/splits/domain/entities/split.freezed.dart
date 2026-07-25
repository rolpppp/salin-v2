// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'split.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Split {

 String get id; String get title; String? get originLedgerEntryId; int get totalMinor; SplitStatus get status; String? get note; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt; SyncStatus get syncStatus;
/// Create a copy of Split
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitCopyWith<Split> get copyWith => _$SplitCopyWithImpl<Split>(this as Split, _$identity);

  /// Serializes this Split to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Split&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.originLedgerEntryId, originLedgerEntryId) || other.originLedgerEntryId == originLedgerEntryId)&&(identical(other.totalMinor, totalMinor) || other.totalMinor == totalMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,originLedgerEntryId,totalMinor,status,note,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Split(id: $id, title: $title, originLedgerEntryId: $originLedgerEntryId, totalMinor: $totalMinor, status: $status, note: $note, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $SplitCopyWith<$Res>  {
  factory $SplitCopyWith(Split value, $Res Function(Split) _then) = _$SplitCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? originLedgerEntryId, int totalMinor, SplitStatus status, String? note, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class _$SplitCopyWithImpl<$Res>
    implements $SplitCopyWith<$Res> {
  _$SplitCopyWithImpl(this._self, this._then);

  final Split _self;
  final $Res Function(Split) _then;

/// Create a copy of Split
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? originLedgerEntryId = freezed,Object? totalMinor = null,Object? status = null,Object? note = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(Split(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,originLedgerEntryId: freezed == originLedgerEntryId ? _self.originLedgerEntryId : originLedgerEntryId // ignore: cast_nullable_to_non_nullable
as String?,totalMinor: null == totalMinor ? _self.totalMinor : totalMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SplitStatus,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Split].
extension SplitPatterns on Split {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Split value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Split() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Split value)  $default,){
final _that = this;
switch (_that) {
case _Split():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Split value)?  $default,){
final _that = this;
switch (_that) {
case _Split() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? originLedgerEntryId,  int totalMinor,  SplitStatus status,  String? note,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Split() when $default != null:
return $default(_that.id,_that.title,_that.originLedgerEntryId,_that.totalMinor,_that.status,_that.note,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? originLedgerEntryId,  int totalMinor,  SplitStatus status,  String? note,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Split():
return $default(_that.id,_that.title,_that.originLedgerEntryId,_that.totalMinor,_that.status,_that.note,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? originLedgerEntryId,  int totalMinor,  SplitStatus status,  String? note,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Split() when $default != null:
return $default(_that.id,_that.title,_that.originLedgerEntryId,_that.totalMinor,_that.status,_that.note,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Split implements Split {
  const _Split({required this.id, required this.title, this.originLedgerEntryId, required this.totalMinor, required this.status, this.note, required this.createdAt, required this.updatedAt, this.deletedAt, required this.syncStatus});
  factory _Split.fromJson(Map<String, dynamic> json) => _$SplitFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? originLedgerEntryId;
@override final  int totalMinor;
@override final  SplitStatus status;
@override final  String? note;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;
@override final  SyncStatus syncStatus;

/// Create a copy of Split
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SplitCopyWith<_Split> get copyWith => __$SplitCopyWithImpl<_Split>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Split&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.originLedgerEntryId, originLedgerEntryId) || other.originLedgerEntryId == originLedgerEntryId)&&(identical(other.totalMinor, totalMinor) || other.totalMinor == totalMinor)&&(identical(other.status, status) || other.status == status)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,originLedgerEntryId,totalMinor,status,note,createdAt,updatedAt,deletedAt,syncStatus);

@override
String toString() {
  return 'Split(id: $id, title: $title, originLedgerEntryId: $originLedgerEntryId, totalMinor: $totalMinor, status: $status, note: $note, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$SplitCopyWith<$Res> implements $SplitCopyWith<$Res> {
  factory _$SplitCopyWith(_Split value, $Res Function(_Split) _then) = __$SplitCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? originLedgerEntryId, int totalMinor, SplitStatus status, String? note, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class __$SplitCopyWithImpl<$Res>
    implements _$SplitCopyWith<$Res> {
  __$SplitCopyWithImpl(this._self, this._then);

  final _Split _self;
  final $Res Function(_Split) _then;

/// Create a copy of Split
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? originLedgerEntryId = freezed,Object? totalMinor = null,Object? status = null,Object? note = freezed,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_Split(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,originLedgerEntryId: freezed == originLedgerEntryId ? _self.originLedgerEntryId : originLedgerEntryId // ignore: cast_nullable_to_non_nullable
as String?,totalMinor: null == totalMinor ? _self.totalMinor : totalMinor // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SplitStatus,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
