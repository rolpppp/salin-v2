import 'parsed_transaction.dart';

class AIValidator {
  static List<String> validate(ParsedTransaction transaction) {
    final List<String> warnings = [];

    if (transaction.description.trim().isEmpty) {
      warnings.add('Description is required.');
    }
    
    if (transaction.amountMinor == null || transaction.amountMinor! <= 0) {
      warnings.add('Amount must be greater than zero.');
    }

    final type = transaction.transactionType.toLowerCase();
    if (type != 'expense' && type != 'income' && type != 'transfer') {
      warnings.add('Unsupported transaction type: $type.');
    }

    if (type == 'expense' && transaction.category == null) {
      warnings.add('Category is required for expenses.');
    }

    return warnings;
  }
}
