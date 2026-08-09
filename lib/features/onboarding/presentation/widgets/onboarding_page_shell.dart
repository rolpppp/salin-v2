import 'package:flutter/material.dart';

/// Common per-page wrapper for each of the 3 onboarding bodies hosted in
/// the [PageView].
///
/// Handles three things every page needs identically:
///  - Scrolls its own content independently ([SingleChildScrollView])
///    instead of relying on Expanded/Spacer-based vertical centering, which
///    breaks at large text-scale settings.
///  - Removes itself from the semantics tree while off-screen
///    ([ExcludeSemantics]) — [PageView] keeps all of its children built
///    simultaneously, so without this a screen reader concatenates all 3
///    pages into a single continuous document. This is the single most
///    common [PageView] accessibility bug.
///  - Announces its own step position as a live region, since there is no
///    visual progress indicator to otherwise convey it — each page owns its
///    own CTA now rather than sharing one bottom bar.
class OnboardingPageShell extends StatelessWidget {
  final int pageIndex;
  final int currentPage;
  final int pageCount;
  final Widget child;

  const OnboardingPageShell({
    super.key,
    required this.pageIndex,
    required this.currentPage,
    required this.child,
    this.pageCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: pageIndex != currentPage,
      child: Semantics(
        liveRegion: true,
        label: 'Step ${pageIndex + 1} of $pageCount',
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: child,
        ),
      ),
    );
  }
}
