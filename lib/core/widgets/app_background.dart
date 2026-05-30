import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';

/// Ambient app backdrop: a tinted base with a few soft, blurred colour "blobs".
/// Gives every screen depth so content (glass nav, cards) reads as layered
/// rather than flat-on-black. Place a screen's content as [child]; the screen's
/// own Scaffold should be transparent so this shows through.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkBase : AppColors.lightBase;
    final a = isDark ? 1.0 : 0.55; // blobs are subtler in light mode

    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _Blob(
              color: AppColors.glowViolet,
              size: 460,
              opacity: (isDark ? 0.20 : 0.10) * a,
            ),
          ),
          Positioned(
            top: 80,
            right: -160,
            child: _Blob(
              color: AppColors.glowTeal,
              size: 420,
              opacity: (isDark ? 0.12 : 0.07) * a,
            ),
          ),
          Positioned(
            bottom: -180,
            left: 60,
            child: _Blob(
              color: AppColors.glowCoral,
              size: 420,
              opacity: (isDark ? 0.10 : 0.06) * a,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _Blob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
