import 'package:flutter/material.dart';

/// Maps a Category's stored icon key (a plain string in the database) to a
/// Flutter IconData. Falls back to a generic icon for anything unrecognized
/// so a bad/missing seed value never crashes the UI.
///
/// Used by BudgetsPage's category rows and AccountsPage's Recent Activity
/// list, so both screens render the same icon for the same category.
IconData mapCategoryIcon(String iconKey) {
  switch (iconKey.toLowerCase()) {
    case 'food':
    case 'dining':
    case 'restaurant':
    case 'food_dining':
      return Icons.restaurant_outlined;
    case 'coffee':
      return Icons.coffee_outlined;
    case 'transport':
    case 'transportation':
    case 'car':
      return Icons.directions_car_outlined;
    case 'housing':
    case 'rent':
    case 'home':
      return Icons.home_outlined;
    case 'utilities':
      return Icons.bolt_outlined;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'entertainment':
    case 'subscription':
      return Icons.movie_outlined;
    case 'health':
      return Icons.favorite_border;
    case 'transfer':
      return Icons.swap_horiz_outlined;
    case 'salary':
    case 'income':
      return Icons.payments_outlined;
    default:
      return Icons.category_outlined;
  }
}