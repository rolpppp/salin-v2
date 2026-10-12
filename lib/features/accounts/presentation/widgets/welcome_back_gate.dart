import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/onboarding_config.dart';
import '../../../../core/config/welcome_back_config.dart';
import '../../../../core/services/sync/sync_providers.dart';
import '../providers/account_providers.dart';
import 'update_balances_sheet.dart';

/// Wraps the app and, each time it comes to the foreground (cold start or
/// resume), stamps the last-opened time and shows the "Welcome back" balance
/// prompt if the user has been away [kWelcomeBackThresholdDays] or more.
///
/// Only for users who finished onboarding and have an active account.
class WelcomeBackGate extends ConsumerStatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  /// Injectable clock for tests.
  final DateTime Function() now;

  const WelcomeBackGate({
    super.key,
    required this.navigatorKey,
    required this.child,
    this.now = DateTime.now,
  });

  @override
  ConsumerState<WelcomeBackGate> createState() => _WelcomeBackGateState();
}

class _WelcomeBackGateState extends ConsumerState<WelcomeBackGate> with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After the first frame so the router/navigator exist.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onOpen());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onOpen();
  }

  Future<void> _onOpen() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      // Always stamp, even if we end up not showing anything.
      final daysAway = await WelcomeBackConfig.recordOpen(prefs, widget.now());
      if (daysAway == null || !mounted) return;
      if (!(prefs.getBool(OnboardingConfig.completedKey) ?? false)) return;

      final accounts = await ref.read(accountRepositoryProvider).getAll();
      if (!accounts.any((a) => !a.isArchived) || !mounted) return;

      final navContext = widget.navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      await showUpdateBalancesSheet(navContext, daysAway: daysAway);
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
