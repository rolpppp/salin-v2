// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviewItem {

 String get id; String get rawInput; ParsedTransaction get transaction; List<String> get warnings;
/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewItemCopyWith<ReviewItem> get copyWith => _$ReviewItemCopyWithImpl<ReviewItem>(this as ReviewItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewItem&&(identical(other.id, id) || other.id == id)&&(identical(other.rawInput, rawInput) || other.rawInput == rawInput)&&(identical(other.transaction, transaction) || other.transaction == transaction)&&const DeepCollectionEquality().equals(other.warnings, warnings));
}


@override
int get hashCode => Object.hash(runtimeType,id,rawInput,transaction,const DeepCollectionEquality().hash(warnings));

@override
String toString() {
  return 'ReviewItem(id: $id, rawInput: $rawInput, transaction: $transaction, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class $ReviewItemCopyWith<$Res>  {
  factory $ReviewItemCopyWith(ReviewItem value, $Res Function(ReviewItem) _then) = _$ReviewItemCopyWithImpl;
@useResult
$Res call({
 String id, String rawInput, ParsedTransaction transaction, List<String> warnings
});


$ParsedTransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class _$ReviewItemCopyWithImpl<$Res>
    implements $ReviewItemCopyWith<$Res> {
  _$ReviewItemCopyWithImpl(this._self, this._then);

  final ReviewItem _self;
  final $Res Function(ReviewItem) _then;

/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rawInput = null,Object? transaction = null,Object? warnings = null,}) {
  return _then(ReviewItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rawInput: null == rawInput ? _self.rawInput : rawInput // ignore: cast_nullable_to_non_nullable
as String,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as ParsedTransaction,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParsedTransactionCopyWith<$Res> get transaction {
  
  return $ParsedTransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReviewItem].
extension ReviewItemPatterns on ReviewItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewItem value)  $default,){
final _that = this;
switch (_that) {
case _ReviewItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rawInput,  ParsedTransaction transaction,  List<String> warnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
return $default(_that.id,_that.rawInput,_that.transaction,_that.warnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rawInput,  ParsedTransaction transaction,  List<String> warnings)  $default,) {final _that = this;
switch (_that) {
case _ReviewItem():
return $default(_that.id,_that.rawInput,_that.transaction,_that.warnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rawInput,  ParsedTransaction transaction,  List<String> warnings)?  $default,) {final _that = this;
switch (_that) {
case _ReviewItem() when $default != null:
return $default(_that.id,_that.rawInput,_that.transaction,_that.warnings);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewItem implements ReviewItem {
  const _ReviewItem({required this.id, required this.rawInput, required this.transaction,  List<String> warnings = const []}): _warnings = warnings;
  

@override final  String id;
@override final  String rawInput;
@override final  ParsedTransaction transaction;
 final  List<String> _warnings;
@override@JsonKey() List<String> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}


/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewItemCopyWith<_ReviewItem> get copyWith => __$ReviewItemCopyWithImpl<_ReviewItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewItem&&(identical(other.id, id) || other.id == id)&&(identical(other.rawInput, rawInput) || other.rawInput == rawInput)&&(identical(other.transaction, transaction) || other.transaction == transaction)&&const DeepCollectionEquality().equals(other._warnings, _warnings));
}


@override
int get hashCode => Object.hash(runtimeType,id,rawInput,transaction,const DeepCollectionEquality().hash(_warnings));

@override
String toString() {
  return 'ReviewItem(id: $id, rawInput: $rawInput, transaction: $transaction, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class _$ReviewItemCopyWith<$Res> implements $ReviewItemCopyWith<$Res> {
  factory _$ReviewItemCopyWith(_ReviewItem value, $Res Function(_ReviewItem) _then) = __$ReviewItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String rawInput, ParsedTransaction transaction, List<String> warnings
});


@override $ParsedTransactionCopyWith<$Res> get transaction;

}
/// @nodoc
class __$ReviewItemCopyWithImpl<$Res>
    implements _$ReviewItemCopyWith<$Res> {
  __$ReviewItemCopyWithImpl(this._self, this._then);

  final _ReviewItem _self;
  final $Res Function(_ReviewItem) _then;

/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rawInput = null,Object? transaction = null,Object? warnings = null,}) {
  return _then(_ReviewItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rawInput: null == rawInput ? _self.rawInput : rawInput // ignore: cast_nullable_to_non_nullable
as String,transaction: null == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as ParsedTransaction,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ReviewItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParsedTransactionCopyWith<$Res> get transaction {
  
  return $ParsedTransactionCopyWith<$Res>(_self.transaction, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}
}

// dart format on
