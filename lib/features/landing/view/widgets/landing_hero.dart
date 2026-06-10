import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';
import 'package:smart_sprint/features/landing/view/widgets/product_preview.dart';

class LandingHero extends StatelessWidget {
  const LandingHero({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = Landing.isWide(context);
    final compact = Landing.isCompact(context);

    final left = _HeroCopy(wide: wide, compact: compact);
    final right = const Parallax(
      factor: -0.06,
      child: Reveal(delayMs: 220, dy: 40, child: _FloatingPreview()),
    );

    return FramedContent(
      padding: EdgeInsets.only(top: compact ? 32 : 64, bottom: compact ? 48 : 96),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 47, child: left),
                const SizedBox(width: 48),
                Expanded(flex: 53, child: right),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 48), right],
            ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool wide;
  final bool compact;
  const _HeroCopy({required this.wide, required this.compact});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final headlineSize = compact ? 42.0 : (wide ? 66.0 : 56.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Reveal(delayMs: 0, child: _AnnouncementChip()),
        const SizedBox(height: 28),
        Reveal(
          delayMs: 80,
          child: _Headline(size: headlineSize),
        ),
        const SizedBox(height: 24),
        Reveal(
          delayMs: 160,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'SmartSprint pulls your tasks, sprints, nested subtasks and team '
              'activity into one fast workspace — so planning takes minutes and '
              'nothing slips through the cracks.',
              style: MType.body(context, size: compact ? 16 : 18),
            ),
          ),
        ),
        const SizedBox(height: 34),
        Reveal(
          delayMs: 240,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              PrimaryCta(
                label: 'Start for free',
                onTap: () => context.go('/signup'),
              ),
              GhostCta(
                label: 'Log in',
                icon: Icons.arrow_outward_rounded,
                onTap: () => context.go('/login'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Reveal(delayMs: 320, child: _ProofRow(mc: mc)),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  final double size;
  const _Headline({required this.size});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final base = GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.02,
      letterSpacing: -1.8,
      color: mc.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plan the sprint.', style: base),
        Text('Track the work.', style: base),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Marker(color: mc.coral, child: Text('Ship', style: base)),
            Text(' faster.', style: base),
          ],
        ),
      ],
    );
  }
}

/// A felt-tip highlight behind a word — hand-made feel, not a gradient fill.
class _Marker extends StatelessWidget {
  final Widget child;
  final Color color;
  const _Marker({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -4,
          right: -6,
          bottom: 8,
          height: 18,
          child: Transform.rotate(
            angle: -0.012,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AnnouncementChip extends StatelessWidget {
  const _AnnouncementChip();

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/features'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: mc.panel,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: mc.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: mc.violet.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: mc.violet,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Nested subtasks + live activity timeline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mc.text,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 14, color: mc.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  final MC mc;
  const _ProofRow({required this.mc});

  @override
  Widget build(BuildContext context) {
    const avatarColors = [
      Color(0xFF6C47FF),
      Color(0xFF14B8A6),
      Color(0xFFFF6B35),
      Color(0xFF3B82F6),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24.0 + (avatarColors.length - 1) * 16,
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < avatarColors.length; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: avatarColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: mc.bg, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            'Built for makers and teams who ship on a cadence.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: mc.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// The product preview with a gentle perpetual float.
class _FloatingPreview extends StatefulWidget {
  const _FloatingPreview();

  @override
  State<_FloatingPreview> createState() => _FloatingPreviewState();
}

class _FloatingPreviewState extends State<_FloatingPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(offset: Offset(0, -6 + t * 12), child: child);
      },
      child: const ProductPreview(),
    );
  }
}
