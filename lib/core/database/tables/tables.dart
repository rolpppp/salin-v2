import 'package:drift/drift.dart';

@DataClassName('SettingRow')
class Settings extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get id => text()();
  TextColumn get currency => text()();
  TextColumn get accentTheme => text().named('accent_theme')();
  IntColumn get themeMode => integer().named('theme_mode')();
  IntColumn get weekStart => integer().named('week_start')();
  BoolColumn get compactMode => boolean().named('compact_mode')();
  BoolColumn get homeGreetingEnabled => boolean().named('home_greeting_enabled')();
  BoolColumn get biometricLock => boolean().named('biometric_lock')();
  BoolColumn get notificationsEnabled => boolean().named('notifications_enabled')();
  BoolColumn get syncEnabled => boolean().named('sync_enabled')();
  IntColumn get lastSyncAt => integer().nullable().named('last_sync_at')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountRow')
class Accounts extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get accountType => integer().named('account_type')();
  IntColumn get openingBalanceMinor => integer().named('opening_balance_minor')();
  TextColumn get currency => text()();
  TextColumn get icon => text()();
  TextColumn get color => text().nullable()();
  IntColumn get displayOrder => integer().named('display_order')();
  BoolColumn get isArchived => boolean().named('is_archived')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  IntColumn get categoryType => integer().named('category_type')();
  BoolColumn get isSystem => boolean().named('is_system')();
  IntColumn get displayOrder => integer().named('display_order')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetRow')
class Budgets extends Table {
  @override
  String get tableName => 'budgets';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get limitMinor => integer().nullable().named('limit_minor')();
  IntColumn get period => integer()();
  IntColumn get startDate => integer().named('start_date')();
  IntColumn get endDate => integer().named('end_date')();
  BoolColumn get rolloverEnabled => boolean().named('rollover_enabled')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetCategoryRow')
class BudgetCategories extends Table {
  @override
  String get tableName => 'budget_categories';

  TextColumn get id => text()();
  TextColumn get budgetId => text().named('budget_id').references(Budgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoryId => text().named('category_id').references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get limitMinor => integer().named('limit_minor')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  @override
  String get tableName => 'recurring_rules';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get accountId => text().named('account_id').references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoryId => text().nullable().named('category_id').references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get amountMinor => integer().named('amount_minor')();
  IntColumn get direction => integer()();
  IntColumn get frequency => integer()();
  IntColumn get interval => integer()();
  IntColumn get startDate => integer().named('start_date')();
  IntColumn get endDate => integer().nullable().named('end_date')();
  BoolColumn get autoGenerate => boolean().named('auto_generate')();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecurringInstanceRow')
class RecurringInstances extends Table {
  @override
  String get tableName => 'recurring_instances';

  TextColumn get id => text()();
  TextColumn get recurringRuleId => text().named('recurring_rule_id').references(RecurringRules, #id, onDelete: KeyAction.cascade)();
  IntColumn get scheduledDate => integer().named('scheduled_date')();
  TextColumn get ledgerEntryId => text().nullable().named('ledger_entry_id').references(LedgerEntries, #id, onDelete: KeyAction.setNull)();
  IntColumn get status => integer()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ContactRow')
class Contacts extends Table {
  @override
  String get tableName => 'contacts';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get avatarPath => text().nullable().named('avatar_path')();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtRow')
class Debts extends Table {
  @override
  String get tableName => 'debts';

  TextColumn get id => text()();
  TextColumn get contactId => text().named('contact_id').references(Contacts, #id, onDelete: KeyAction.cascade)();
  TextColumn get originLedgerEntryId => text().nullable().named('origin_ledger_entry_id').references(LedgerEntries, #id, onDelete: KeyAction.setNull)();
  IntColumn get principalMinor => integer().named('principal_minor')();
  IntColumn get dueDate => integer().nullable().named('due_date')();
  IntColumn get status => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SplitRow')
class Splits extends Table {
  @override
  String get tableName => 'splits';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get originLedgerEntryId => text().nullable().named('origin_ledger_entry_id').references(LedgerEntries, #id, onDelete: KeyAction.setNull)();
  IntColumn get totalMinor => integer().named('total_minor')();
  IntColumn get status => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SplitParticipantRow')
class SplitParticipants extends Table {
  @override
  String get tableName => 'split_participants';

  TextColumn get id => text()();
  TextColumn get splitId => text().named('split_id').references(Splits, #id, onDelete: KeyAction.cascade)();
  TextColumn get contactId => text().named('contact_id').references(Contacts, #id, onDelete: KeyAction.cascade)();
  IntColumn get shareMinor => integer().named('share_minor')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransferRow')
class Transfers extends Table {
  @override
  String get tableName => 'transfers';

  TextColumn get id => text()();
  TextColumn get fromAccountId => text().named('from_account_id').references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get toAccountId => text().named('to_account_id').references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LedgerEntryRow')
class LedgerEntries extends Table {
  @override
  String get tableName => 'ledger_entries';

  TextColumn get id => text()();
  TextColumn get accountId => text().named('account_id').references(Accounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoryId => text().nullable().named('category_id').references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get recurringInstanceId => text().nullable().named('recurring_instance_id').references(RecurringInstances, #id, onDelete: KeyAction.setNull)();
  TextColumn get debtId => text().nullable().named('debt_id').references(Debts, #id, onDelete: KeyAction.setNull)();
  TextColumn get splitId => text().nullable().named('split_id').references(Splits, #id, onDelete: KeyAction.setNull)();
  TextColumn get transferId => text().nullable().named('transfer_id').references(Transfers, #id, onDelete: KeyAction.setNull)();
  IntColumn get amountMinor => integer().named('amount_minor')();
  IntColumn get direction => integer()();
  IntColumn get origin => integer()();
  IntColumn get occurredAt => integer().named('occurred_at')();
  TextColumn get note => text().nullable()();
  TextColumn get metadataJson => text().nullable().named('metadata_json')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  IntColumn get deletedAt => integer().nullable().named('deleted_at')();
  IntColumn get syncStatus => integer().named('sync_status')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MediaRow')
class Media extends Table {
  @override
  String get tableName => 'media';

  TextColumn get id => text()();
  TextColumn get ledgerEntryId => text().named('ledger_entry_id').references(LedgerEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get path => text()();
  TextColumn get mimeType => text().named('mime_type')();
  IntColumn get sizeBytes => integer().named('size_bytes')();
  IntColumn get createdAt => integer().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
