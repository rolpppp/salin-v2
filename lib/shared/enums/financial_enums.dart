enum AccountType {
  cash,
  bank,
  savings,
  eWallet,
  creditCard,
  debitCard,
  investment,
}

enum MoneyDirection {
  inflow,
  outflow,
}

enum LedgerOrigin {
  manual,
  quickAdd,
  recurring,
  transfer,
  debtSettlement,
  splitSettlement,
  adjustment,
  import,
  migration,
}

enum CategoryType {
  income,
  expense,
}

enum BudgetPeriod {
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

enum RecurringInstanceStatus {
  pending,
  generated,
  paid,
  skipped,
  cancelled,
}

enum DebtStatus {
  active,
  paid,
  cancelled,
}

enum SplitStatus {
  active,
  settled,
  cancelled,
}

enum SyncStatus {
  localOnly,
  pendingUpload,
  synced,
  pendingDelete,
  conflicted,
}

enum AppThemeMode {
  system,
  light,
  dark,
}

enum WeekStart {
  sunday,
  monday,
}
