import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_sprint/features/auth/data/auth_repository.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_footer.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_nav.dart';

/// Shared chrome for every public marketing page: the dot-grid/blueprint
/// backdrop, a single page scroll (wired to the reveal system via
/// [RevealScope]), the sticky nav and the footer.
///
/// [redirectIfSignedIn] is used by the home landing page so already-logged-in
/// visitors skip straight to /home.
class MarketingScaffold extends StatefulWidget {
  final List<Widget> sections;
  final String currentPath;
  final bool redirectIfSignedIn;

  const MarketingScaffold({
    super.key,
    required this.sections,
    required this.currentPath,
    this.redirectIfSignedIn = false,
  });

  @override
  State<MarketingScaffold> createState() => _MarketingScaffoldState();
}

class _MarketingScaffoldState extends State<MarketingScaffold> {
  final _controller = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    if (widget.redirectIfSignedIn) _maybeRedirect();
  }

  Future<void> _maybeRedirect() async {
    final hasToken = await AuthRepository().hasToken();
    if (hasToken && mounted) context.go('/home');
  }

  void _onScroll() {
    final s = _controller.offset > 8;
    if (s != _scrolled) setState(() => _scrolled = s);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navHeight = Landing.isCompact(context) ? 58.0 : 68.0;

    return Scaffold(
      backgroundColor: MC.of(context).bg,
      body: Stack(
        children: [
          const MarketingBackdrop(),
          Positioned.fill(
            child: RevealScope(
              controller: _controller,
              child: ScrollConfiguration(
                behavior: const _SmoothScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: navHeight),
                      ...widget.sections,
                      const LandingFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LandingNav(
              scrolled: _scrolled,
              currentPath: widget.currentPath,
            ),
          ),
        ],
      ),
    );
  }
}

/// Removes the default scroll glow/stretch — cleaner on web.
class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
