import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoneyText extends StatelessWidget {
  final int amountMinor;
  final TextStyle? style;
  final bool isNegative;
  final bool showSign;

  const MoneyText({
    super.key,
    required this.amountMinor,
    this.style,
    this.isNegative = false,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    final amountDouble = amountMinor / 100.0;
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    
    String formatted = formatter.format(amountDouble.abs());
    
    if (showSign) {
      if (isNegative || amountDouble < 0) {
        formatted = '-$formatted';
      } else if (amountDouble > 0) {
        formatted = '+$formatted';
      }
    } else if (isNegative && !formatted.startsWith('-')) {
      formatted = '-$formatted';
    }

    return Text(
      formatted,
      style: (style ?? const TextStyle()).copyWith(
        fontFamily: 'IBMPlexMono',
      ),
      textAlign: TextAlign.right,
    );
  }
}
