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

    // Only genuine amount ambiguity (more than one number found on the
    // line, so it's unclear which one is the transaction amount) blocks
    // confirmation. A merely non-exact-format parse with a single,
    // unambiguous number ('needs_review') does not warn here — amount and
    // direction are already solid, so it's auto-save eligible; category is
    // auto-assigned and visible-but-editable rather than gated. See
    // docs/NEXT_ITERATION.md's Core Value Proposition revision.
    if (transaction.notes == 'ambiguous_amount') {
      warnings.add('More than one number found — please confirm the correct amount.');
    }

    return warnings;
  }
}
