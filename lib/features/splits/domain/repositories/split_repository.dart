import '../entities/split.dart';
import '../entities/split_participant.dart';

abstract class SplitRepository {
  Future<void> createSplit(
    Split split,
    List<SplitParticipant> participants, {
    String? accountId,
    String? categoryId,
    DateTime? occurredAt,
  });
  
  Future<void> deleteSplit(String splitId);
  Future<void> restoreSplit(String splitId);
  
  Future<void> recordRepayment(
    String splitId,
    String contactId,
    String accountId,
    int amountMinor,
    DateTime occurredAt,
    String? note,
  );

  Future<Split?> getById(String id);
  Future<List<Split>> getAll();
  Stream<List<Split>> watchAllActive();
  Stream<List<Split>> watchAllSettled();
  Stream<List<SplitParticipant>> watchParticipantsForSplit(String splitId);
  Future<List<SplitParticipant>> getParticipantsForSplit(String splitId);
  Future<int> getRemainingBalance(String splitId);
}
