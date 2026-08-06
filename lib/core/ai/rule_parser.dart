import 'dart:convert';
import 'ai_provider.dart';
import 'inference_result.dart';
import 'parsed_transaction.dart';

class RuleParser implements AIProvider {
  @override
  String get name => 'Rule Parser';

  @override
  Future<InferenceResult<List<ParsedTransaction>>> parseTransaction(String input) async {
    final startTime = DateTime.now();
    final trimmed = input.trim();

    // Split input strictly by lines (one transaction per line, no sentence-splitting/comma-detection)
    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      throw const FormatException('No transaction lines to parse.');
    }

    final parsedList = <ParsedTransaction>[];

    // Regex to match a currency-prefixed/suffixed number.
    // e.g. 150, ₱150.50, $150, PHP 150
    final amountPattern = RegExp(
      r'(?:[pP][hH][pP]|₱|\$)?\s*(\d+(?:\.\d{1,2})?)',
      unicode: true,
    );

    // Regex for #category tag
    final categoryPattern = RegExp(r'#(\w+)\b');

    for (final line in lines) {
      // 1. Extract optional #category tag first
      String? tagCategory;
      String lineWithoutCategory = line;
      final categoryMatch = categoryPattern.firstMatch(line);
      if (categoryMatch != null) {
        tagCategory = categoryMatch.group(1)?.toLowerCase();
        lineWithoutCategory = line.replaceAll(categoryPattern, '').replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      // 2. Find all number matches in the line
      final matches = amountPattern.allMatches(lineWithoutCategory).toList();

      // Principle 6: Ghost transactions are eliminated at the source.
      // Any line with no number match is simply skipped.
      if (matches.isEmpty) {
        continue;
      }

      final firstMatch = matches.first;
      final double? amount = double.tryParse(firstMatch.group(1) ?? '');
      if (amount == null) {
        continue;
      }

      final amountMinor = (amount * 100).round();
      final matchStart = firstMatch.start;
      final matchEnd = firstMatch.end;
      final lineLength = lineWithoutCategory.length;

      bool isExact = false;
      String description = '';

      // Check if it matches exactly <amount> <description> or <description> <amount>
      if (matches.length == 1) {
        if (matchStart == 0) {
          // Starts with amount. The rest is description.
          description = lineWithoutCategory.substring(matchEnd).trim();
          if (description.isNotEmpty) {
            isExact = true;
          }
        } else if (matchEnd == lineLength) {
          // Ends with amount. The beginning is description.
          description = lineWithoutCategory.substring(0, matchStart).trim();
          if (description.isNotEmpty) {
            isExact = true;
          }
        }
      }

      // If it doesn't match the exact format, do a best-effort parse
      if (!isExact) {
        description = (lineWithoutCategory.substring(0, matchStart) + lineWithoutCategory.substring(matchEnd))
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (description.isEmpty) {
          description = 'Quick Add';
        }
      }

      final lowerDesc = description.toLowerCase();
      final isIncome = _isIncomeKeyword(lowerDesc);
      final transactionType = isIncome ? 'income' : 'expense';

      // #category tag always wins over keyword-guessing when present
      String? categoryId;
      if (tagCategory != null) {
        // Map common spec tags to database seeded ones
        if (tagCategory == 'dorm') {
          categoryId = 'rent';
        } else if (tagCategory == 'leisure') {
          categoryId = 'entertainment';
        } else if (tagCategory == 'academics') {
          categoryId = 'utilities';
        } else {
          categoryId = tagCategory;
        }
      } else {
        categoryId = _mapCategory(lowerDesc, isIncome);
      }

      // Mark needs review note if it is not an exact match
      final notes = isExact ? null : 'needs_review';

      parsedList.add(ParsedTransaction(
        description: description,
        amountMinor: amountMinor,
        currency: 'PHP',
        transactionType: transactionType,
        category: categoryId,
        transactionDate: DateTime.now().toUtc(),
        notes: notes,
      ));
    }

    if (parsedList.isEmpty) {
      throw const FormatException('No valid transactions found. Format: <amount> <description> or <description> <amount> #category');
    }

    final latency = DateTime.now().difference(startTime);

    return InferenceResult<List<ParsedTransaction>>(
      provider: name,
      model: 'Regex',
      latency: latency,
      finishReason: 'stop',
      safetyFlags: const {},
      usage: const {},
      rawResponse: jsonEncode(parsedList.map((tx) => tx.toJson()).toList()),
      parsedPayload: parsedList,
    );
  }

  bool _isIncomeKeyword(String desc) {
    const incomeKeywords = {
      'salary',
      'wage',
      'allowance',
      'income',
      'bonus',
      'dividend',
      'interest',
      'payday',
      'refund',
      'deposit',
      'cash-in',
      'cashin',
    };
    return incomeKeywords.any((kw) => desc.contains(kw));
  }

  String? _mapCategory(String desc, bool isIncome) {
    if (isIncome) {
      if (desc.contains('salary') || desc.contains('wage') || desc.contains('payday')) {
        return 'salary';
      }
      if (desc.contains('invest') || desc.contains('stock') || desc.contains('crypto')) {
        return 'investments';
      }
      return 'other_income';
    } else {
      if (const {'food', 'lunch', 'dinner', 'breakfast', 'coffee', 'starbucks', 'jollibee', 'mcdonalds', 'kfc', 'restaurant', 'snack', 'groceries', 'grocery', 'ozone', 'coke', 'meals', 'eat'}.any((kw) => desc.contains(kw))) {
        return 'food';
      }
      if (const {'transport', 'grab', 'taxi', 'bus', 'jeep', 'tricycle', 'angkas', 'fuel', 'gas', 'fare', 'toll', 'uber', 'flight', 'ride', 'travel'}.any((kw) => desc.contains(kw))) {
        return 'transport';
      }
      if (const {'rent', 'apartment', 'condo', 'housing', 'room', 'lease', 'dorm'}.any((kw) => desc.contains(kw))) {
        return 'rent';
      }
      if (const {'utilities', 'electricity', 'water', 'internet', 'wifi', 'meralco', 'phone', 'load', 'bill', 'subscription', 'netflix', 'spotify', 'academics'}.any((kw) => desc.contains(kw))) {
        return 'utilities';
      }
      if (const {'entertainment', 'movie', 'cinema', 'game', 'gig', 'concert', 'arcade', 'bar', 'beer', 'drink', 'recreation', 'hobby', 'leisure'}.any((kw) => desc.contains(kw))) {
        return 'entertainment';
      }
      return null;
    }
  }
}
