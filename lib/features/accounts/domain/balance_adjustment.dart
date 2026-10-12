import '../../../shared/enums/financial_enums.dart';

/// Note written on every balance-adjustment ledger entry. The web app reads
/// this exact string; do not change it.
const String kBalanceAdjustmentNote = 'Balance adjustment';

/// What one account's correction looks like: a single ledger entry for the
/// difference between what the user says they hold and what Salin computes.
///
/// Pure value type, integer centavos only.
class BalanceAdjustment {
  final String accountId;
  final MoneyDirection direction;

  /// Always > 0.
  final int amountMinor;

  const BalanceAdjustment({
    required this.accountId,
    required this.direction,
    required this.amountMinor,
  });

  @override
  bool operator ==(Object other) =>
      other is BalanceAdjustment &&
      other.accountId == accountId &&
      other.direction == direction &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(accountId, direction, amountMinor);

  @override
  String toString() => 'BalanceAdjustment($accountId, $direction, $amountMinor)';
}

/// Maps (computed, real) balances to the one entry that reconciles them, or
/// `null` when they already match. `real < computed` is an outflow,
/// `real > computed` an inflow, amount is `|real - computed|`.
BalanceAdjustment? planBalanceAdjustment({
  required String accountId,
  required int computedMinor,
  required int realMinor,
}) {
  final diff = realMinor - computedMinor;
  if (diff == 0) return null;
  return BalanceAdjustment(
    accountId: accountId,
    direction: diff < 0 ? MoneyDirection.outflow : MoneyDirection.inflow,
    amountMinor: diff.abs(),
  );
}

/// Parses a typed peso amount to integer centavos without any floating point.
///
/// Accepts an optional leading sign (`-`, `−`, or `+`), an optional currency
/// symbol/code, thousands commas, and up to two decimal places:
/// `"1,234.5"` -> 123450, `"-₱3,160"` -> -316000, `".5"` -> 50.
/// Returns `null` for empty or malformed input, or more than two decimals
/// (rather than silently rounding someone's money).
int? parseCentavos(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;

  var negative = false;
  if (s.startsWith('-') || s.startsWith('−')) {
    negative = true;
    s = s.substring(1).trim();
  } else if (s.startsWith('+')) {
    s = s.substring(1).trim();
  }

  // Strip a leading currency symbol or 3-letter code (e.g. ₱, $, PHP).
  s = s.replaceFirst(RegExp(r'^(₱|\$|[A-Za-z]{3})\s*'), '');
  // A sign may also follow the symbol ("₱-50").
  if (s.startsWith('-') || s.startsWith('−')) {
    negative = !negative;
    s = s.substring(1).trim();
  }

  final match = RegExp(r'^(\d{1,3}(?:,\d{3})+|\d+)?(?:\.(\d{0,2}))?$').firstMatch(s);
  if (match == null) return null;
  final whole = (match.group(1) ?? '').replaceAll(',', '');
  final frac = match.group(2) ?? '';
  if (whole.isEmpty && frac.isEmpty) return null;

  final wholeValue = whole.isEmpty ? 0 : int.parse(whole);
  final fracValue = frac.isEmpty ? 0 : int.parse(frac.padRight(2, '0'));
  final total = wholeValue * 100 + fracValue;
  return negative ? -total : total;
}

/// Plain editable text for a centavo amount, e.g. `123450` -> `"1234.50"`,
/// `-316000` -> `"-3160.00"`. No grouping so it round-trips through
/// [parseCentavos].
String minorToInputText(int minor) {
  final abs = minor.abs();
  final whole = abs ~/ 100;
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '${minor < 0 ? '-' : ''}$whole.$cents';
}

String _currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'PHP':
      return '₱';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'JPY':
      return '¥';
    case 'GBP':
      return '£';
    default:
      return '${currency.toUpperCase()} ';
  }
}

/// Display text such as `₱3,160` or `₱3,160.50` (decimals only when the
/// centavos are non-zero), in the account's own currency. With
/// [showSign], zero-or-positive gets `+` and negative gets `−` (U+2212),
/// which is how differences are shown ("−₱3,160").
String formatMinor(int minor, {String currency = 'PHP', bool showSign = false}) {
  final abs = minor.abs();
  final whole = (abs ~/ 100).toString();
  final cents = abs % 100;
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  final decimals = cents == 0 ? '' : '.${cents.toString().padLeft(2, '0')}';
  final sign = minor < 0
      ? '−'
      : (showSign && minor > 0 ? '+' : '');
  return '$sign${_currencySymbol(currency)}$buf$decimals';
}
