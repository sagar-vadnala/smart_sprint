import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Surface kit. Two reusable treatments shared across the app so depth stays
/// consistent (don't hand-roll card decorations elsewhere):
///   • [GlassPanel]  — frosted, blurred translucent surface (nav, bars, sheets).
///   • [AppCard]     — crafted opaque card: subtle top-lit gradient + hairline
///                     border + soft shadow, with an optional accent glow.
/// ─────────────────────────────────────────────────────────────────────────────

class GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 22,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(20);
    final fill = (isDark ? AppColors.darkSurface : Colors.white).withValues(
      alpha: isDark ? 0.62 : 0.72,
    );
    final line = (isDark ? Colors.white : AppColors.lightText).withValues(
      alpha: isDark ? 0.08 : 0.06,
    );

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: border ?? Border.all(color: line, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Optional accent — tints the border + casts a faint coloured glow.
  final Color? glow;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.glow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurfaceHigh;
    final bottom = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = glow != null
        ? glow!.withValues(alpha: isDark ? 0.35 : 0.30)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: isDark ? 0.18 : 0.14),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
              blurRadius: 16,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}
