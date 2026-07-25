import '../entities/debt.dart';

abstract class DebtRepository {
  Future<void> createDebt(
    Debt debt, {
    bool isLent,
    String? accountId,
    DateTime? occurredAt,
  });

  Future<void> deleteDebt(String debtId);

  Future<void> recordRepayment(
    String debtId,
    String accountId,
    int amountMinor,
    DateTime occurredAt,
    String? note,
  );

  Future<Debt?> getById(String id);
  Future<List<Debt>> getAll();
  Stream<List<Debt>> watchAllActive();
  Stream<List<Debt>> watchAllSettled();
  Future<int> getRemainingBalance(String debtId);
}
