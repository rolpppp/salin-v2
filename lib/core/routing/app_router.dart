import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/onboarding_config.dart';
import '../services/sync/sync_providers.dart';
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
import '../../features/settings/presentation/pages/categories_page.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  // Computed once, synchronously, at router construction — see
  // OnboardingConfig.shouldShowOnboarding for the retroactive
  // existing-user heuristic and why it can't be an async ledger read.
  final shouldShowOnboarding = OnboardingConfig.shouldShowOnboarding(prefs);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: shouldShowOnboarding ? '/onboarding' : '/',
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
            path: '/edit/:id',
            pageBuilder: (context, state) => NoTransitionPage(
              child: AddTransactionPage(
                transactionId: state.pathParameters['id'],
              ),
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
            path: '/categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesPage(),
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      // Deliberately a root-level route, NOT nested inside ShellRoute above
      // — nesting it there would make it inherit AppScaffold's bottom nav,
      // which must never appear during onboarding.
      GoRoute(
        path: '/onboarding',
        // Bounces back to Home if already completed, so the route can't be
        // re-entered via deep link, hot restart, or back navigation after
        // completion.
        redirect: (context, state) {
          final completed = prefs.getBool(OnboardingConfig.completedKey) ?? false;
          return completed ? '/' : null;
        },
        builder: (context, state) => const OnboardingPage(),
      ),
    ],
  );
});
