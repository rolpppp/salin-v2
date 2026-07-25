import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/review_item.dart';
import '../../../../core/ai/parsed_transaction.dart';
import '../../../../core/ai/ai_validator.dart';
import './transaction_providers.dart';

class TransactionReviewNotifier extends StateNotifier<List<ReviewItem>> {
  final Ref _ref;
  static const _uuid = Uuid();

  TransactionReviewNotifier(this._ref) : super([]);

  /// Stage a new parsed transaction in the review state queue
  void stageTransaction(String rawInput, ParsedTransaction transaction) {
    final id = _uuid.v4();
    final warnings = AIValidator.validate(transaction);
    final item = ReviewItem(
      id: id,
      rawInput: rawInput,
      transaction: transaction,
      warnings: warnings,
    );
    state = [...state, item];
  }

  /// Update the transaction fields of a specific staged item (e.g. manual edit before save)
  void updateItem(String id, ParsedTransaction updatedTransaction) {
    state = state.map((item) {
      if (item.id == id) {
        final warnings = AIValidator.validate(updatedTransaction);
        return item.copyWith(
          transaction: updatedTransaction,
          warnings: warnings,
        );
      }
      return item;
    }).toList();
  }

  /// Confirm a specific review item, converting and writing it to database
  Future<void> confirmItem(String id, {required String accountId, String? categoryId}) async {
    final itemIndex = state.indexWhere((element) => element.id == id);
    if (itemIndex == -1) return;

    final item = state[itemIndex];
    final repo = _ref.read(transactionRepositoryProvider);

    await repo.createFromParsed(
      item.transaction,
      accountId: accountId,
      categoryId: categoryId,
    );

    // Remove from staging queue
    state = state.where((element) => element.id != id).toList();
  }

  /// Discard a specific review item from staging queue
  void discardItem(String id) {
    state = state.where((element) => element.id != id).toList();
  }

  /// Confirm all valid staged items that have no warnings
  Future<void> confirmAll({required String accountId}) async {
    final validItems = state.where((item) => item.warnings.isEmpty).toList();
    if (validItems.isEmpty) return;

    final repo = _ref.read(transactionRepositoryProvider);
    for (final item in validItems) {
      await repo.createFromParsed(
        item.transaction,
        accountId: accountId,
      );
    }

    // Keep only items that have warnings
    state = state.where((item) => item.warnings.isNotEmpty).toList();
  }

  /// Discard all items
  void discardAll() {
    state = [];
  }
}

final transactionReviewProvider = StateNotifierProvider<TransactionReviewNotifier, List<ReviewItem>>((ref) {
  return TransactionReviewNotifier(ref);
});
