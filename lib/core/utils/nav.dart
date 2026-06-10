import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension SafeNav on BuildContext {
  /// Pushes [location] only if it isn't already the current location.
  ///
  /// The side nav is persistent (it stays visible on detail screens), so its
  /// links can be tapped while you're already on the page they point to. A
  /// plain `push` would stack a duplicate history entry each time — making the
  /// browser back button require N presses to escape. This skips the no-op.
  void pushUnique(String location) {
    if (GoRouterState.of(this).uri.toString() == location) return;
    push(location);
  }
}
