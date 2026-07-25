import 'package:flutter/material.dart';
import 'money_text.dart';

class ReceiptRow extends StatelessWidget {
  final String label;
  final int amountMinor;
  final bool isNegative;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;

  const ReceiptRow({
    super.key,
    required this.label,
    required this.amountMinor,
    this.isNegative = false,
    this.labelStyle,
    this.amountStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: (labelStyle ?? const TextStyle()).copyWith(
              fontFamily: 'PublicSans',
            ),
          ),
          MoneyText(
            amountMinor: amountMinor,
            isNegative: isNegative,
            style: amountStyle,
          ),
        ],
      ),
    );
  }
}
