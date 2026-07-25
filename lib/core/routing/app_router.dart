import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/recurring/presentation/pages/recurring_page.dart';
import '../../features/splits/presentation/pages/splits_debts_page.dart';
import '../../shared/widgets/app_scaffold.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AppScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionsPage(),
            ),
          ),
          GoRoute(
            path: '/add',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AddTransactionPage(),
            ),
          ),
          GoRoute(
            path: '/insights',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InsightsPage(),
            ),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
          GoRoute(
            path: '/budgets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BudgetsPage(),
            ),
          ),
          GoRoute(
            path: '/accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsPage(),
            ),
          ),
          GoRoute(
            path: '/contacts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ContactsPage(),
            ),
          ),
          GoRoute(
            path: '/recurring',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RecurringPage(),
            ),
          ),
          GoRoute(
            path: '/splits_debts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SplitsDebtsPage(),
            ),
          ),
        ],
      ),
    ],
  );
});
