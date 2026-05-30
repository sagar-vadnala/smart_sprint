import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';

/// Branded animated loader — replaces plain CircularProgressIndicator app-wide.
/// A rotating gradient ring, a softly pulsing brand glow, and the SmartSprint
/// bolt centred. Cheap (single AnimationController, painted in CustomPaint).
class BrandLoader extends StatefulWidget {
  final double size;

  /// When true, also displays a small label under the loader.
  final String? label;

  const BrandLoader({super.key, this.size = 64, this.label});

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with TickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _rotation.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotation, _pulse]),
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_pulse.value);
              return CustomPaint(
                painter: _RingPainter(
                  rotation: _rotation.value * 2 * math.pi,
                  glow: t,
                ),
                child: Center(
                  child: Container(
                    width: size * 0.5,
                    height: size * 0.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.brandGradient,
                      ),
                      borderRadius: BorderRadius.circular(size * 0.16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(
                            alpha: 0.45 + t * 0.25,
                          ),
                          blurRadius: 16,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: size * 0.28,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double rotation;
  final double glow; // 0..1

  _RingPainter({required this.rotation, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = (size.width / 2) - stroke;

    // Soft background track.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = AppColors.brand.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Rotating gradient sweep (a 3/4 arc).
    final sweep = SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      transform: GradientRotation(rotation),
      colors: const [
        Color(0x008B6FFF), // transparent
        Color(0xFF8B6FFF),
        Color(0xFF6C47FF),
        Color(0xFFFF6B35), // a hint of coral at the tip
      ],
      stops: const [0.0, 0.55, 0.85, 1.0],
    );

    final arcRect = Rect.fromCircle(center: centre, radius: radius);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 1.5,
      false,
      Paint()
        ..shader = sweep.createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Outer glow that pulses.
    canvas.drawCircle(
      centre,
      radius + stroke * 0.5,
      Paint()
        ..color = AppColors.brand.withValues(alpha: 0.05 + glow * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.rotation != rotation || old.glow != glow;
}
