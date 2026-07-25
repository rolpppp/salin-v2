import '../entities/recurring_rule.dart';
import '../entities/recurring_instance.dart';

abstract class RecurringRepository {
  Future<void> createRule(RecurringRule rule);
  Future<void> deleteRule(String ruleId);
  Future<void> markAsPaid(String instanceId, String accountId, DateTime paidDate);
  Future<void> skipOccurrence(String instanceId);
  Future<void> generateNextInstances(String ruleId, int count);
  Future<RecurringRule?> getRuleById(String ruleId);
  Future<List<RecurringRule>> getAllRules();
  Stream<List<RecurringRule>> watchAllRules();
  Stream<List<RecurringInstance>> watchAllInstances();
  Stream<List<RecurringInstance>> watchInstancesForRule(String ruleId);
  Stream<List<RecurringInstance>> watchUpcomingInstances();
}
