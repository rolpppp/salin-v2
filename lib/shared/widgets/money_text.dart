import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders a peso amount in the app's monospace ledger style.
///
/// Two optional, backward-compatible flags were added:
/// - [muteDecimals]: renders the decimal portion (".00") smaller and in a
///   muted tone, while the whole-number portion stays full weight. Used on
///   Accounts and Budgets hero figures.
/// - [strikeIntegers]: draws a thin horizontal rule through the whole-number
///   portion only — the "ledger tally" look used specifically on the
///   Accounts screen (Net Worth hero + account cards). Never combine this
///   with transaction list rows; it's reserved for balance figures.
///
/// Existing call sites that don't pass these flags render exactly as before.
class MoneyText extends StatelessWidget {
  final int amountMinor;
  final TextStyle? style;
  final bool isNegative;
  final bool showSign;
  final bool muteDecimals;
  final bool strikeIntegers;
  final Color? muteColor;
  final Color? strikeColor;

  const MoneyText({
    super.key,
    required this.amountMinor,
    this.style,
    this.isNegative = false,
    this.showSign = false,
    this.muteDecimals = false,
    this.strikeIntegers = false,
    this.muteColor,
    this.strikeColor,
  });

  @override
  Widget build(BuildContext context) {
    final amountDouble = amountMinor / 100.0;
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    String formatted = formatter.format(amountDouble.abs());
    String sign = '';

    if (showSign) {
      if (isNegative || amountDouble < 0) {
        sign = '-';
      } else if (amountDouble > 0) {
        sign = '+';
      }
    } else if (isNegative && !formatted.startsWith('-')) {
      sign = '-';
    }

    final baseStyle = (style ?? const TextStyle()).copyWith(
      fontFamily: 'IBMPlexMono',
      fontFamilyFallback: const ['RobotoMono', 'monospace'],
    );

    if (!muteDecimals && !strikeIntegers) {
      return Text('$sign$formatted', style: baseStyle, textAlign: TextAlign.right);
    }

    // Split "1,245,600.50" into whole = "1,245,600" and decimals = ".50"
    final dotIndex = formatted.lastIndexOf('.');
    final whole = dotIndex == -1 ? formatted : formatted.substring(0, dotIndex);
    final decimals = dotIndex == -1 ? '' : formatted.substring(dotIndex);

    final theme = Theme.of(context);
    final mutedTone = muteColor ?? theme.colorScheme.onSurface.withOpacity(0.35);
    final ruleTone = strikeColor ?? theme.colorScheme.onSurface.withOpacity(0.3);

    return RichText(
      textAlign: TextAlign.right,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$sign$whole',
            style: baseStyle.copyWith(
              decoration: strikeIntegers ? TextDecoration.lineThrough : null,
              decorationColor: ruleTone,
              decorationThickness: 1.5,
            ),
          ),
          if (decimals.isNotEmpty)
            TextSpan(
              text: decimals,
              style: baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 16) * 0.62,
                color: muteDecimals ? mutedTone : baseStyle.color,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}