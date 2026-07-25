// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetCategory {

 String get id; String get budgetId; String get categoryId; int get limitMinor; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetCategoryCopyWith<BudgetCategory> get copyWith => _$BudgetCategoryCopyWithImpl<BudgetCategory>(this as BudgetCategory, _$identity);

  /// Serializes this BudgetCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.budgetId, budgetId) || other.budgetId == budgetId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.limitMinor, limitMinor) || other.limitMinor == limitMinor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,budgetId,categoryId,limitMinor,createdAt,updatedAt);

@override
String toString() {
  return 'BudgetCategory(id: $id, budgetId: $budgetId, categoryId: $categoryId, limitMinor: $limitMinor, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BudgetCategoryCopyWith<$Res>  {
  factory $BudgetCategoryCopyWith(BudgetCategory value, $Res Function(BudgetCategory) _then) = _$BudgetCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String budgetId, String categoryId, int limitMinor, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$BudgetCategoryCopyWithImpl<$Res>
    implements $BudgetCategoryCopyWith<$Res> {
  _$BudgetCategoryCopyWithImpl(this._self, this._then);

  final BudgetCategory _self;
  final $Res Function(BudgetCategory) _then;

/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? budgetId = null,Object? categoryId = null,Object? limitMinor = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(BudgetCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,budgetId: null == budgetId ? _self.budgetId : budgetId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,limitMinor: null == limitMinor ? _self.limitMinor : limitMinor // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetCategory].
extension BudgetCategoryPatterns on BudgetCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetCategory value)  $default,){
final _that = this;
switch (_that) {
case _BudgetCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetCategory value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String budgetId,  String categoryId,  int limitMinor,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
return $default(_that.id,_that.budgetId,_that.categoryId,_that.limitMinor,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String budgetId,  String categoryId,  int limitMinor,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BudgetCategory():
return $default(_that.id,_that.budgetId,_that.categoryId,_that.limitMinor,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String budgetId,  String categoryId,  int limitMinor,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BudgetCategory() when $default != null:
return $default(_that.id,_that.budgetId,_that.categoryId,_that.limitMinor,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetCategory implements BudgetCategory {
  const _BudgetCategory({required this.id, required this.budgetId, required this.categoryId, required this.limitMinor, required this.createdAt, required this.updatedAt});
  factory _BudgetCategory.fromJson(Map<String, dynamic> json) => _$BudgetCategoryFromJson(json);

@override final  String id;
@override final  String budgetId;
@override final  String categoryId;
@override final  int limitMinor;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetCategoryCopyWith<_BudgetCategory> get copyWith => __$BudgetCategoryCopyWithImpl<_BudgetCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.budgetId, budgetId) || other.budgetId == budgetId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.limitMinor, limitMinor) || other.limitMinor == limitMinor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,budgetId,categoryId,limitMinor,createdAt,updatedAt);

@override
String toString() {
  return 'BudgetCategory(id: $id, budgetId: $budgetId, categoryId: $categoryId, limitMinor: $limitMinor, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BudgetCategoryCopyWith<$Res> implements $BudgetCategoryCopyWith<$Res> {
  factory _$BudgetCategoryCopyWith(_BudgetCategory value, $Res Function(_BudgetCategory) _then) = __$BudgetCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String budgetId, String categoryId, int limitMinor, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$BudgetCategoryCopyWithImpl<$Res>
    implements _$BudgetCategoryCopyWith<$Res> {
  __$BudgetCategoryCopyWithImpl(this._self, this._then);

  final _BudgetCategory _self;
  final $Res Function(_BudgetCategory) _then;

/// Create a copy of BudgetCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? budgetId = null,Object? categoryId = null,Object? limitMinor = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_BudgetCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,budgetId: null == budgetId ? _self.budgetId : budgetId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,limitMinor: null == limitMinor ? _self.limitMinor : limitMinor // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
