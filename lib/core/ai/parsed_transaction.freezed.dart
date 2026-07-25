// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parsed_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParsedTransaction {

 String get description; int? get amountMinor; String get currency; String get transactionType; String? get category; DateTime? get transactionDate; String? get account; String? get merchant; String? get notes; bool? get recurring; bool? get debt; bool? get split;
/// Create a copy of ParsedTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedTransactionCopyWith<ParsedTransaction> get copyWith => _$ParsedTransactionCopyWithImpl<ParsedTransaction>(this as ParsedTransaction, _$identity);

  /// Serializes this ParsedTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedTransaction&&(identical(other.description, description) || other.description == description)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.category, category) || other.category == category)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.account, account) || other.account == account)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recurring, recurring) || other.recurring == recurring)&&(identical(other.debt, debt) || other.debt == debt)&&(identical(other.split, split) || other.split == split));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,amountMinor,currency,transactionType,category,transactionDate,account,merchant,notes,recurring,debt,split);

@override
String toString() {
  return 'ParsedTransaction(description: $description, amountMinor: $amountMinor, currency: $currency, transactionType: $transactionType, category: $category, transactionDate: $transactionDate, account: $account, merchant: $merchant, notes: $notes, recurring: $recurring, debt: $debt, split: $split)';
}


}

/// @nodoc
abstract mixin class $ParsedTransactionCopyWith<$Res>  {
  factory $ParsedTransactionCopyWith(ParsedTransaction value, $Res Function(ParsedTransaction) _then) = _$ParsedTransactionCopyWithImpl;
@useResult
$Res call({
 String description, int? amountMinor, String currency, String transactionType, String? category, DateTime? transactionDate, String? account, String? merchant, String? notes, bool? recurring, bool? debt, bool? split
});




}
/// @nodoc
class _$ParsedTransactionCopyWithImpl<$Res>
    implements $ParsedTransactionCopyWith<$Res> {
  _$ParsedTransactionCopyWithImpl(this._self, this._then);

  final ParsedTransaction _self;
  final $Res Function(ParsedTransaction) _then;

/// Create a copy of ParsedTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? description = null,Object? amountMinor = freezed,Object? currency = null,Object? transactionType = null,Object? category = freezed,Object? transactionDate = freezed,Object? account = freezed,Object? merchant = freezed,Object? notes = freezed,Object? recurring = freezed,Object? debt = freezed,Object? split = freezed,}) {
  return _then(ParsedTransaction(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amountMinor: freezed == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: freezed == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,account: freezed == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recurring: freezed == recurring ? _self.recurring : recurring // ignore: cast_nullable_to_non_nullable
as bool?,debt: freezed == debt ? _self.debt : debt // ignore: cast_nullable_to_non_nullable
as bool?,split: freezed == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedTransaction].
extension ParsedTransactionPatterns on ParsedTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedTransaction value)  $default,){
final _that = this;
switch (_that) {
case _ParsedTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String description,  int? amountMinor,  String currency,  String transactionType,  String? category,  DateTime? transactionDate,  String? account,  String? merchant,  String? notes,  bool? recurring,  bool? debt,  bool? split)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedTransaction() when $default != null:
return $default(_that.description,_that.amountMinor,_that.currency,_that.transactionType,_that.category,_that.transactionDate,_that.account,_that.merchant,_that.notes,_that.recurring,_that.debt,_that.split);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String description,  int? amountMinor,  String currency,  String transactionType,  String? category,  DateTime? transactionDate,  String? account,  String? merchant,  String? notes,  bool? recurring,  bool? debt,  bool? split)  $default,) {final _that = this;
switch (_that) {
case _ParsedTransaction():
return $default(_that.description,_that.amountMinor,_that.currency,_that.transactionType,_that.category,_that.transactionDate,_that.account,_that.merchant,_that.notes,_that.recurring,_that.debt,_that.split);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String description,  int? amountMinor,  String currency,  String transactionType,  String? category,  DateTime? transactionDate,  String? account,  String? merchant,  String? notes,  bool? recurring,  bool? debt,  bool? split)?  $default,) {final _that = this;
switch (_that) {
case _ParsedTransaction() when $default != null:
return $default(_that.description,_that.amountMinor,_that.currency,_that.transactionType,_that.category,_that.transactionDate,_that.account,_that.merchant,_that.notes,_that.recurring,_that.debt,_that.split);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParsedTransaction implements ParsedTransaction {
  const _ParsedTransaction({required this.description, this.amountMinor, required this.currency, required this.transactionType, this.category, this.transactionDate, this.account, this.merchant, this.notes, this.recurring, this.debt, this.split});
  factory _ParsedTransaction.fromJson(Map<String, dynamic> json) => _$ParsedTransactionFromJson(json);

@override final  String description;
@override final  int? amountMinor;
@override final  String currency;
@override final  String transactionType;
@override final  String? category;
@override final  DateTime? transactionDate;
@override final  String? account;
@override final  String? merchant;
@override final  String? notes;
@override final  bool? recurring;
@override final  bool? debt;
@override final  bool? split;

/// Create a copy of ParsedTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedTransactionCopyWith<_ParsedTransaction> get copyWith => __$ParsedTransactionCopyWithImpl<_ParsedTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParsedTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedTransaction&&(identical(other.description, description) || other.description == description)&&(identical(other.amountMinor, amountMinor) || other.amountMinor == amountMinor)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.category, category) || other.category == category)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.account, account) || other.account == account)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recurring, recurring) || other.recurring == recurring)&&(identical(other.debt, debt) || other.debt == debt)&&(identical(other.split, split) || other.split == split));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,description,amountMinor,currency,transactionType,category,transactionDate,account,merchant,notes,recurring,debt,split);

@override
String toString() {
  return 'ParsedTransaction(description: $description, amountMinor: $amountMinor, currency: $currency, transactionType: $transactionType, category: $category, transactionDate: $transactionDate, account: $account, merchant: $merchant, notes: $notes, recurring: $recurring, debt: $debt, split: $split)';
}


}

/// @nodoc
abstract mixin class _$ParsedTransactionCopyWith<$Res> implements $ParsedTransactionCopyWith<$Res> {
  factory _$ParsedTransactionCopyWith(_ParsedTransaction value, $Res Function(_ParsedTransaction) _then) = __$ParsedTransactionCopyWithImpl;
@override @useResult
$Res call({
 String description, int? amountMinor, String currency, String transactionType, String? category, DateTime? transactionDate, String? account, String? merchant, String? notes, bool? recurring, bool? debt, bool? split
});




}
/// @nodoc
class __$ParsedTransactionCopyWithImpl<$Res>
    implements _$ParsedTransactionCopyWith<$Res> {
  __$ParsedTransactionCopyWithImpl(this._self, this._then);

  final _ParsedTransaction _self;
  final $Res Function(_ParsedTransaction) _then;

/// Create a copy of ParsedTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? description = null,Object? amountMinor = freezed,Object? currency = null,Object? transactionType = null,Object? category = freezed,Object? transactionDate = freezed,Object? account = freezed,Object? merchant = freezed,Object? notes = freezed,Object? recurring = freezed,Object? debt = freezed,Object? split = freezed,}) {
  return _then(_ParsedTransaction(
description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amountMinor: freezed == amountMinor ? _self.amountMinor : amountMinor // ignore: cast_nullable_to_non_nullable
as int?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: freezed == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,account: freezed == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String?,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recurring: freezed == recurring ? _self.recurring : recurring // ignore: cast_nullable_to_non_nullable
as bool?,debt: freezed == debt ? _self.debt : debt // ignore: cast_nullable_to_non_nullable
as bool?,split: freezed == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
