import 'package:flutter/widgets.dart';

abstract final class Breakpoints {
  /// At or above this width we switch from bottom-nav to a side rail.
  static const double sideNav = 760;

  /// Wide desktop — used for tuning max content width.
  static const double desktop = 1240;

  /// Content is centred and never wider than this on large screens.
  static const double contentMax = 1120;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Use a persistent side navigation rail (web / tablet / desktop).
  bool get useSideNav => screenWidth >= Breakpoints.sideNav;

  bool get isDesktop => screenWidth >= Breakpoints.desktop;
}
