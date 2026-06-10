import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';

/// Presents modal content adaptively:
///
/// * On mobile (and narrow web windows) it stays a native **bottom sheet** —
///   the right pattern for touch.
/// * On the web / wide layouts it becomes a centered **glassmorphism dialog** —
///   a frosted, width-constrained card that floats over a blurred backdrop.
///   Bottom sheets glued to the edge of a desktop browser look out of place;
///   a popup reads as deliberate, polished UI.
///
/// Content widgets stay presentation-agnostic: they paint their chrome through
/// [sheetSurfaceDecoration] and gate the drag grabber on
/// [AdaptiveSheetScope.isDialog], so the same widget renders correctly in both
/// modes.
///
/// The decision is intentionally based on the *window* (web + width), not just
/// `kIsWeb`, so a narrow browser window — which behaves like a phone — keeps the
/// bottom sheet.
bool useGlassDialog(BuildContext context) =>
    kIsWeb && MediaQuery.sizeOf(context).width >= 600;

/// Exposes the active presentation mode to descendant content so shells can
/// adapt their chrome (background, corner radius, grabber) without each call
/// site having to know which form was chosen.
class AdaptiveSheetScope extends InheritedWidget {
  final bool isDialog;

  const AdaptiveSheetScope({
    super.key,
    required this.isDialog,
    required super.child,
  });

  static bool isDialogOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AdaptiveSheetScope>()
          ?.isDialog ??
      false;

  @override
  bool updateShouldNotify(AdaptiveSheetScope oldWidget) =>
      oldWidget.isDialog != isDialog;
}

/// The surface decoration a sheet/dialog shell should paint as its root.
///
/// * Bottom sheet → opaque surface with a top-only rounded edge (the grabber
///   sits above it).
/// * Glass dialog → fully transparent + all-round radius, so the frosted
///   [_GlassDialogFrame] behind it shows through and provides the glass look.
BoxDecoration sheetSurfaceDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (AdaptiveSheetScope.isDialogOf(context)) {
    return BoxDecoration(borderRadius: BorderRadius.circular(24));
  }
  return BoxDecoration(
    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
  );
}

/// The drag handle shown at the top of a bottom sheet. Renders nothing (just a
/// little breathing room) when presented as a dialog, where a grabber would be
/// meaningless.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    if (AdaptiveSheetScope.isDialogOf(context)) {
      return const SizedBox(height: 10);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 8),
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Drop-in replacement for `showModalBottomSheet` that picks the right
/// presentation for the platform/width (see [useGlassDialog]).
///
/// [builder] receives a context beneath the modal route. Use [useGlassDialog]
/// or [AdaptiveSheetScope.isDialog] inside it if a builder needs to branch
/// (e.g. to skip keyboard-inset padding the dialog frame already handles).
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  if (!useGlassDialog(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdaptiveSheetScope(isDialog: false, child: builder(ctx)),
    );
  }

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => AdaptiveSheetScope(
      isDialog: true,
      child: _GlassDialogFrame(child: Builder(builder: builder)),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final t = Curves.easeOutCubic.transform(anim.value);
      return FadeTransition(
        opacity: anim,
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      );
    },
  );
}

/// The frosted, width-constrained card that hosts dialog content on the web.
class _GlassDialogFrame extends StatelessWidget {
  final Widget child;

  const _GlassDialogFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    // Translucent surface — the blurred backdrop showing through is what reads
    // as "glass".
    final surface = (isDark ? const Color(0xFF18181B) : Colors.white)
        .withValues(alpha: isDark ? 0.72 : 0.78);
    final borderColor = (isDark ? Colors.white : Colors.white).withValues(
      alpha: isDark ? 0.10 : 0.65,
    );

    return Stack(
      children: [
        // A gentle frost on the app content behind the dialog — just enough to
        // push it back without washing the whole screen out.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: const SizedBox.expand(),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              // Lift the card above the keyboard when a field is focused.
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + media.viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 460,
                  maxHeight: media.size.height * 0.88,
                ),
                // Shadow lives on the outer container so it isn't clipped.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 48,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    // The card itself keeps a stronger blur so its translucent
                    // surface reads as glass.
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      // A real Material surface: provides the ancestor that
                      // TextField/InkWell require (showGeneralDialog doesn't
                      // insert one), renders ink ripples, and paints the
                      // translucent glass fill + hairline border.
                      child: Material(
                        color: surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: borderColor, width: 1.2),
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
