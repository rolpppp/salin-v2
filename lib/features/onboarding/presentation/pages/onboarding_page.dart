import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/onboarding_config.dart';
import '../../../../core/services/sync/sync_providers.dart';
import '../widgets/onboarding_page_four.dart';
import '../widgets/onboarding_page_one.dart';
import '../widgets/onboarding_page_shell.dart';
import '../widgets/onboarding_page_three.dart';
import '../widgets/onboarding_page_two.dart';
import '../widgets/onboarding_top_bar.dart';

/// Hosts the entire 4-step first-run onboarding flow behind the single
/// `/onboarding` route: Welcome → Baseline Setup → Try It Out → the aha
/// moment. One [PageView], not four separate routes, so skip/back/progress
/// state lives in one place instead of being smeared across the router.
///
/// Unlike the previous 3-step flow, each page now owns its own primary
/// action (and, for pages 2 and 3, a real write to the database) instead of
/// a shared bottom CTA bar — screens 2 and 3 have real side effects
/// (writing the baseline, logging a real expense) that must fire from an
/// explicit tap, so navigation is programmatic-only.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _pageCount = 4;
  static const _transitionDuration = Duration(milliseconds: 300);
  static const _skipLabels = ['Skip', 'Skip', 'Not now'];

  final _pageController = PageController();
  int _currentPage = 0;
  int _baselineMinor = 0;
  int? _loggedAmountMinor;
  String? _loggedDescription;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: _transitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _markCompleted() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(OnboardingConfig.completedKey, true);
  }

  Future<void> _finishToHome() async {
    await _markCompleted();
    if (mounted) context.go('/');
  }

  void _handleBack() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _handleBaselineSet(int baselineMinor) {
    setState(() => _baselineMinor = baselineMinor);
    _goToPage(2);
  }

  void _handleExpenseLogged(int amountMinor, String description) {
    setState(() {
      _loggedAmountMinor = amountMinor;
      _loggedDescription = description;
    });
    _goToPage(3);
  }

  @override
  Widget build(BuildContext context) {
    // Page 3 (the aha screen) is only reachable after a real expense has
    // been logged on page 2, so it has no back/skip chrome of its own —
    // "Take me home" is the only way out, matching the other 3 pages'
    // consistent escape hatch not being needed once the payoff is shown.
    final showTopBar = _currentPage < 3;

    return PopScope(
      // Page 0: hardware back exits normally and must NOT set the
      // completion flag — a user who force-quits mid-flow should see
      // onboarding again next launch, since they never reached a terminal
      // state (finishing via the CTA or Skip). Pages 1-3: hardware back
      // steps to the previous page instead of popping the route.
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (showTopBar)
                OnboardingTopBar(
                  currentPage: _currentPage,
                  skipLabel: _skipLabels[_currentPage],
                  onSkip: _finishToHome,
                  onBack: _handleBack,
                ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  // Navigation is button-driven only — pages 2 and 3 gate
                  // real writes (baseline, logged expense) behind explicit
                  // taps, so a swipe gesture must not be able to skip past
                  // them into a state with no data to show.
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    OnboardingPageShell(
                      pageIndex: 0,
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                      child: OnboardingPageOne(onContinue: () => _goToPage(1)),
                    ),
                    OnboardingPageShell(
                      pageIndex: 1,
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                      child: OnboardingPageTwo(onContinue: _handleBaselineSet),
                    ),
                    OnboardingPageShell(
                      pageIndex: 2,
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                      child: OnboardingPageThree(onLogged: _handleExpenseLogged),
                    ),
                    OnboardingPageShell(
                      pageIndex: 3,
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                      child: OnboardingPageFour(
                        baselineMinor: _baselineMinor,
                        loggedAmountMinor: _loggedAmountMinor,
                        loggedDescription: _loggedDescription,
                        onFinish: _finishToHome,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
