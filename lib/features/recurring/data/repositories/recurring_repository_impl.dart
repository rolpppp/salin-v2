import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database.dart';
import '../../../../shared/enums/financial_enums.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/entities/recurring_instance.dart';
import '../../domain/repositories/recurring_repository.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  RecurringRepositoryImpl(this._db);

  // Mappers
  RecurringRule _mapRuleRowToDomain(RecurringRuleRow row) {
    return RecurringRule(
      id: row.id,
      title: row.title,
      accountId: row.accountId,
      categoryId: row.categoryId,
      amountMinor: row.amountMinor,
      direction: MoneyDirection.values[row.direction],
      frequency: RecurringFrequency.values[row.frequency],
      interval: row.interval,
      startDate: DateTime.fromMillisecondsSinceEpoch(row.startDate, isUtc: true),
      endDate: row.endDate != null ? DateTime.fromMillisecondsSinceEpoch(row.endDate!, isUtc: true) : null,
      autoGenerate: row.autoGenerate,
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      deletedAt: row.deletedAt != null ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!, isUtc: true) : null,
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  RecurringRulesCompanion _mapRuleDomainToCompanion(RecurringRule domain) {
    return RecurringRulesCompanion(
      id: Value(domain.id),
      title: Value(domain.title),
      accountId: Value(domain.accountId),
      categoryId: Value(domain.categoryId),
      amountMinor: Value(domain.amountMinor),
      direction: Value(domain.direction.index),
      frequency: Value(domain.frequency.index),
      interval: Value(domain.interval),
      startDate: Value(domain.startDate.millisecondsSinceEpoch),
      endDate: Value(domain.endDate?.millisecondsSinceEpoch),
      autoGenerate: Value(domain.autoGenerate),
      note: Value(domain.note),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      deletedAt: Value(domain.deletedAt?.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  RecurringInstance _mapInstanceRowToDomain(RecurringInstanceRow row) {
    return RecurringInstance(
      id: row.id,
      recurringRuleId: row.recurringRuleId,
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(row.scheduledDate, isUtc: true),
      ledgerEntryId: row.ledgerEntryId,
      status: RecurringInstanceStatus.values[row.status],
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
      syncStatus: SyncStatus.values[row.syncStatus],
    );
  }

  RecurringInstancesCompanion _mapInstanceDomainToCompanion(RecurringInstance domain) {
    return RecurringInstancesCompanion(
      id: Value(domain.id),
      recurringRuleId: Value(domain.recurringRuleId),
      scheduledDate: Value(domain.scheduledDate.millisecondsSinceEpoch),
      ledgerEntryId: Value(domain.ledgerEntryId),
      status: Value(domain.status.index),
      createdAt: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAt: Value(domain.updatedAt.millisecondsSinceEpoch),
      syncStatus: Value(domain.syncStatus.index),
    );
  }

  DateTime _calculateNextDate(DateTime current, RecurringFrequency frequency, int interval) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return current.add(Duration(days: interval));
      case RecurringFrequency.weekly:
        return current.add(Duration(days: 7 * interval));
      case RecurringFrequency.monthly:
        return DateTime(current.year, current.month + interval, current.day);
      case RecurringFrequency.quarterly:
        return DateTime(current.year, current.month + 3 * interval, current.day);
      case RecurringFrequency.yearly:
        return DateTime(current.year + interval, current.month, current.day);
      case RecurringFrequency.custom:
        return current.add(Duration(days: interval));
    }
  }

  @override
  Future<void> createRule(RecurringRule rule) async {
    await _db.transaction(() async {
      await _db.into(_db.recurringRules).insert(_mapRuleDomainToCompanion(rule));
      // Automatically generate initial 5 occurrences
      await _generateNextInstancesInternal(rule, 5);
    });
  }

  @override
  Future<void> updateRule(RecurringRule rule) async {
    await _db.transaction(() async {
      await (_db.update(_db.recurringRules)..where((t) => t.id.equals(rule.id))).write(
        _mapRuleDomainToCompanion(rule.copyWith(updatedAt: DateTime.now().toUtc())),
      );
      // Cancel pending instances and recreate them
      await (_db.delete(_db.recurringInstances)
            ..where((t) => t.recurringRuleId.equals(rule.id) & t.status.equals(RecurringInstanceStatus.pending.index)))
          .go();
      await _generateNextInstancesInternal(rule, 5);
    });
  }

  Future<void> _generateNextInstancesInternal(RecurringRule rule, int count) async {
    // Find the latest instance date for this rule
    final query = _db.select(_db.recurringInstances)
      ..where((t) => t.recurringRuleId.equals(rule.id))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate, mode: OrderingMode.desc)])
      ..limit(1);
    final lastRow = await query.getSingleOrNull();

    DateTime current = rule.startDate;
    if (lastRow != null) {
      current = _calculateNextDate(
        DateTime.fromMillisecondsSinceEpoch(lastRow.scheduledDate, isUtc: true),
        rule.frequency,
        rule.interval,
      );
    }

    final now = DateTime.now().toUtc();

    for (int i = 0; i < count; i++) {
      if (rule.endDate != null && current.isAfter(rule.endDate!)) {
        break;
      }
      final inst = RecurringInstance(
        id: _uuid.v4(),
        recurringRuleId: rule.id,
        scheduledDate: current,
        ledgerEntryId: null,
        status: RecurringInstanceStatus.pending,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.localOnly,
      );
      await _db.into(_db.recurringInstances).insert(_mapInstanceDomainToCompanion(inst));
      current = _calculateNextDate(current, rule.frequency, rule.interval);
    }
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    await _db.transaction(() async {
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (_db.update(_db.recurringRules)..where((t) => t.id.equals(ruleId))).write(
        RecurringRulesCompanion(
          deletedAt: Value(nowMs),
          syncStatus: Value(SyncStatus.pendingUpload.index),
        ),
      );
      // Cancel pending instances
      await (_db.update(_db.recurringInstances)
            ..where((t) => t.recurringRuleId.equals(ruleId) & t.status.equals(RecurringInstanceStatus.pending.index)))
          .write(
        RecurringInstancesCompanion(
          status: Value(RecurringInstanceStatus.cancelled.index),
        ),
      );
    });
  }

  @override
  Future<void> markAsPaid(String instanceId, String accountId, DateTime paidDate) async {
    await _db.transaction(() async {
      // Get instance
      final instRow = await (_db.select(_db.recurringInstances)..where((t) => t.id.equals(instanceId))).getSingle();
      final ruleRow = await (_db.select(_db.recurringRules)..where((t) => t.id.equals(instRow.recurringRuleId))).getSingle();
      final rule = _mapRuleRowToDomain(ruleRow);

      final entryId = _uuid.v4();
      final now = DateTime.now().toUtc();

      // 1. Create the LedgerEntry
      final entry = LedgerEntriesCompanion(
        id: Value(entryId),
        accountId: Value(accountId),
        categoryId: Value(rule.categoryId),
        recurringInstanceId: Value(instanceId),
        amountMinor: Value(rule.amountMinor),
        direction: Value(rule.direction.index),
        origin: Value(LedgerOrigin.recurring.index),
        occurredAt: Value(paidDate.millisecondsSinceEpoch),
        note: Value(rule.note ?? rule.title),
        createdAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: Value(SyncStatus.localOnly.index),
      );
      await _db.into(_db.ledgerEntries).insert(entry);

      // 2. Update the instance status
      await (_db.update(_db.recurringInstances)..where((t) => t.id.equals(instanceId))).write(
        RecurringInstancesCompanion(
          status: Value(RecurringInstanceStatus.paid.index),
          ledgerEntryId: Value(entryId),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

      // 3. Generate the next instance to keep the rolling window
      await _generateNextInstancesInternal(rule, 1);
    });
  }

  @override
  Future<void> skipOccurrence(String instanceId) async {
    await _db.transaction(() async {
      final instRow = await (_db.select(_db.recurringInstances)..where((t) => t.id.equals(instanceId))).getSingle();
      final ruleRow = await (_db.select(_db.recurringRules)..where((t) => t.id.equals(instRow.recurringRuleId))).getSingle();
      final rule = _mapRuleRowToDomain(ruleRow);

      final now = DateTime.now().toUtc();

      // 1. Update status to skipped
      await (_db.update(_db.recurringInstances)..where((t) => t.id.equals(instanceId))).write(
        RecurringInstancesCompanion(
          status: Value(RecurringInstanceStatus.skipped.index),
          updatedAt: Value(now.millisecondsSinceEpoch),
        ),
      );

      // 2. Generate next instance
      await _generateNextInstancesInternal(rule, 1);
    });
  }

  @override
  Future<void> generateNextInstances(String ruleId, int count) async {
    final ruleRow = await (_db.select(_db.recurringRules)..where((t) => t.id.equals(ruleId))).getSingle();
    final rule = _mapRuleRowToDomain(ruleRow);
    await _generateNextInstancesInternal(rule, count);
  }

  @override
  Future<RecurringRule?> getRuleById(String ruleId) async {
    final query = _db.select(_db.recurringRules)..where((t) => t.id.equals(ruleId) & t.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _mapRuleRowToDomain(row) : null;
  }

  @override
  Future<List<RecurringRule>> getAllRules() async {
    final query = _db.select(_db.recurringRules)..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.map(_mapRuleRowToDomain).toList();
  }

  @override
  Stream<List<RecurringRule>> watchAllRules() {
    final query = _db.select(_db.recurringRules)..where((t) => t.deletedAt.isNull());
    return query.watch().map((rows) => rows.map(_mapRuleRowToDomain).toList());
  }

  @override
  Stream<List<RecurringInstance>> watchAllInstances() {
    final query = _db.select(_db.recurringInstances);
    return query.watch().map((rows) => rows.map(_mapInstanceRowToDomain).toList());
  }

  @override
  Stream<List<RecurringInstance>> watchInstancesForRule(String ruleId) {
    final query = _db.select(_db.recurringInstances)..where((t) => t.recurringRuleId.equals(ruleId));
    return query.watch().map((rows) => rows.map(_mapInstanceRowToDomain).toList());
  }

  @override
  Stream<List<RecurringInstance>> watchUpcomingInstances() {
    // Upcoming: pending status, ordered by scheduledDate
    final query = _db.select(_db.recurringInstances)
      ..where((t) => t.status.equals(RecurringInstanceStatus.pending.index))
      ..orderBy([(t) => OrderingTerm(expression: t.scheduledDate, mode: OrderingMode.asc)]);
    return query.watch().map((rows) => rows.map(_mapInstanceRowToDomain).toList());
  }
}
