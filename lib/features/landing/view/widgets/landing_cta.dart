import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';

/// Full-bleed closing call-to-action. A deep violet band textured with a faint
/// dot grid (echoing the page backdrop) — bordered top and bottom, not a
/// floating rounded card.
class LandingCtaBand extends StatelessWidget {
  const LandingCtaBand({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = Landing.isCompact(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B3DCC), AppColors.brand, Color(0xFF7C5BFF)],
        ),
      ),
      child: CustomPaint(
        painter: _DotPainter(Colors.white.withValues(alpha: 0.06)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 64 : 96),
          child: FramedContent(
            child: Reveal(
              child: Column(
                children: [
                  Text(
                    'START / FREE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Set up your first sprint\nin the next five minutes.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: compact ? 30 : 48,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      'Free for solo work and small teams. No credit card, no setup '
                      'call, no migration headache.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.5,
                        height: 1.55,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      _WhiteCta(
                        label: 'Create your workspace',
                        onTap: () => context.go('/signup'),
                      ),
                      _OutlineCta(label: 'Log in', onTap: () => context.go('/login')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final Color color;
  _DotPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 26.0;
    final p = Paint()..color = color;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.color != color;
}

class _WhiteCta extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _WhiteCta({required this.label, required this.onTap});

  @override
  State<_WhiteCta> createState() => _WhiteCtaState();
}

class _WhiteCtaState extends State<_WhiteCta> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(
            color: _h ? const Color(0xFFF1EDFF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandDark,
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                offset: _h ? const Offset(0.18, 0) : Offset.zero,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.brandDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
