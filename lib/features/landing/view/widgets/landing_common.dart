import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Marketing-surface design system (web only).
///
/// Deliberately its OWN palette + primitives, separate from the in-app theme:
/// crisp hairline borders, a blue-charcoal ink (not pure black), a faint dot
/// grid and a blueprint content-frame. Editorial, not "AI-SaaS template".
/// Reuse these — don't hand-roll section chrome.
/// ─────────────────────────────────────────────────────────────────────────────

abstract final class Landing {
  /// The content column. Section bands go full-bleed; their inner content sits
  /// inside this width, framed by faint vertical guides.
  static const double maxWidth = 1280.0;

  static const double wide = 1000.0;
  static const double compact = 680.0;

  static double gutter(BuildContext c) =>
      MediaQuery.sizeOf(c).width < compact ? 22 : 40;

  static bool isWide(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= wide;

  static bool isCompact(BuildContext c) =>
      MediaQuery.sizeOf(c).width < compact;
}

/// Resolved marketing colours for the current brightness.
class MC {
  final bool dark;
  const MC(this.dark);

  factory MC.of(BuildContext c) => MC(Theme.of(c).brightness == Brightness.dark);

  Color get bg => dark ? const Color(0xFF0C0D12) : const Color(0xFFFBFBFC);
  Color get panel => dark ? const Color(0xFF14151C) : Colors.white;
  Color get panelHi => dark ? const Color(0xFF191B24) : const Color(0xFFF7F8FA);
  Color get border => dark ? const Color(0xFF262833) : const Color(0xFFE7E8EC);
  Color get borderSoft =>
      dark ? const Color(0xFF1B1D26) : const Color(0xFFEDEEF1);
  Color get text => dark ? const Color(0xFFF2F3F7) : const Color(0xFF0D0E14);
  Color get muted => dark ? const Color(0xFF9B9DA9) : const Color(0xFF55575F);
  Color get faint => dark ? const Color(0xFF63656F) : const Color(0xFF9A9CA5);

  Color get violet => dark ? const Color(0xFF9B85FF) : AppColors.brand;
  Color get coral => AppColors.accent;
  Color get teal => AppColors.glowTeal;
}

// ── Type helpers ─────────────────────────────────────────────────────────────

abstract final class MType {
  static TextStyle display(BuildContext c, {double? size}) {
    final mc = MC.of(c);
    final w = MediaQuery.sizeOf(c).width;
    return GoogleFonts.plusJakartaSans(
      fontSize: size ?? (w < Landing.compact ? 40 : (w < Landing.wide ? 52 : 64)),
      fontWeight: FontWeight.w800,
      height: 1.04,
      letterSpacing: -1.6,
      color: mc.text,
    );
  }

  static TextStyle heading(BuildContext c, {double? size}) {
    final mc = MC.of(c);
    return GoogleFonts.plusJakartaSans(
      fontSize: size ?? (Landing.isCompact(c) ? 28 : 36),
      fontWeight: FontWeight.w800,
      height: 1.12,
      letterSpacing: -0.8,
      color: mc.text,
    );
  }

  static TextStyle body(BuildContext c, {double size = 16, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: 1.6,
      fontWeight: FontWeight.w400,
      color: color ?? MC.of(c).muted,
    );
  }
}

/// Monospace section kicker — e.g. `01 / FEATURES`. The technical, indexed feel
/// is a deliberate move away from the generic gradient-pill eyebrow.
class MonoKicker extends StatelessWidget {
  final String label;
  final String? index;
  final Color? color;

  const MonoKicker({super.key, required this.label, this.index, this.color});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final accent = color ?? mc.violet;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, color: accent),
        const SizedBox(width: 10),
        if (index != null) ...[
          Text(
            index!,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: accent,
            ),
          ),
          Text(
            '  /  ',
            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: mc.faint),
          ),
        ],
        Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: mc.muted,
          ),
        ),
      ],
    );
  }
}

/// The brand bolt mark (gradient rounded square).
class BrandMark extends StatelessWidget {
  final double size;
  final bool glow;
  const BrandMark({super.key, this.size = 30, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B6FFF), AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.45),
                  blurRadius: size * 0.5,
                  offset: Offset(0, size * 0.18),
                ),
              ]
            : null,
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.62),
    );
  }
}

class Wordmark extends StatelessWidget {
  final double markSize;
  final double fontSize;
  const Wordmark({super.key, this.markSize = 28, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(width: 10),
        Text(
          'SmartSprint',
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: MC.of(context).text,
          ),
        ),
      ],
    );
  }
}

/// Constrains content to [Landing.maxWidth] with the page gutter.
class FramedContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const FramedContent({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Landing.maxWidth),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: Landing.gutter(context)).add(padding),
          child: child,
        ),
      ),
    );
  }
}

/// A full-bleed horizontal band with an optional top hairline. The border spans
/// the entire viewport width so sections read as a structured stack — this is
/// what removes the "narrow column floating in empty space" feeling.
class SectionBand extends StatelessWidget {
  final Widget child;
  final bool topBorder;
  final EdgeInsetsGeometry padding;
  final Color? background;

  const SectionBand({
    super.key,
    required this.child,
    this.topBorder = true,
    this.padding = const EdgeInsets.symmetric(vertical: 84),
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: topBorder
            ? Border(top: BorderSide(color: mc.borderSoft))
            : null,
      ),
      child: Padding(
        padding: padding,
        child: FramedContent(child: child),
      ),
    );
  }
}

// ── Background: dot grid + blueprint vertical guides ─────────────────────────

class MarketingBackdrop extends StatelessWidget {
  const MarketingBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: mc.bg,
        child: CustomPaint(
          painter: _GridPainter(
            dot: mc.text.withValues(alpha: mc.dark ? 0.045 : 0.05),
            guide: mc.border.withValues(alpha: mc.dark ? 0.9 : 1),
            wash: mc.violet.withValues(alpha: mc.dark ? 0.05 : 0.035),
            coral: mc.coral.withValues(alpha: mc.dark ? 0.035 : 0.02),
            frame: Landing.maxWidth,
            gutter: Landing.gutter(context),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color dot;
  final Color guide;
  final Color wash;
  final Color coral;
  final double frame;
  final double gutter;

  _GridPainter({
    required this.dot,
    required this.guide,
    required this.wash,
    required this.coral,
    required this.frame,
    required this.gutter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Soft top-left violet wash + bottom-right coral hint (restrained, no orbs).
    final washRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      washRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -1.1),
          radius: 1.1,
          colors: [wash, wash.withValues(alpha: 0)],
        ).createShader(washRect),
    );
    canvas.drawRect(
      washRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(1.1, 0.9),
          radius: 1.0,
          colors: [coral, coral.withValues(alpha: 0)],
        ).createShader(washRect),
    );

    // Dot grid.
    const step = 30.0;
    final p = Paint()..color = dot;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }

    // Blueprint vertical guides at the content-column edges (wide screens only).
    final colW = frame - gutter * 2;
    if (size.width > colW + 80) {
      final left = (size.width - colW) / 2;
      final right = left + colW;
      final gp = Paint()
        ..color = guide
        ..strokeWidth = 1;
      canvas.drawLine(Offset(left, 0), Offset(left, size.height), gp);
      canvas.drawLine(Offset(right, 0), Offset(right, size.height), gp);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.dot != dot || old.guide != guide || old.frame != frame;
}

// ── Scroll-reveal animation system ───────────────────────────────────────────

/// Exposes the page [ScrollController] to descendant [Reveal] / [Parallax]
/// widgets so they can react to scroll without each wiring their own listener.
class RevealScope extends InheritedWidget {
  final ScrollController controller;
  const RevealScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static ScrollController? of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<RevealScope>()?.controller;

  @override
  bool updateShouldNotify(RevealScope old) => old.controller != controller;
}

/// Fades + lifts its child into view the first time it enters the viewport.
class Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double dy;

  const Reveal({super.key, required this.child, this.delayMs = 0, this.dy = 28});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  ScrollController? _scroll;
  bool _fired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scroll?.removeListener(_check);
    _scroll = RevealScope.of(context);
    _scroll?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_fired || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final dy = box.localToGlobal(Offset.zero).dy;
    final vh = MediaQuery.sizeOf(context).height;
    if (dy < vh - 60) {
      _fired = true;
      _scroll?.removeListener(_check);
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.dy * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Translates its child by a fraction of the scroll offset (subtle parallax).
class Parallax extends StatelessWidget {
  final Widget child;
  final double factor;
  const Parallax({super.key, required this.child, this.factor = -0.05});

  @override
  Widget build(BuildContext context) {
    final controller = RevealScope.of(context);
    if (controller == null) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, c) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        return Transform.translate(offset: Offset(0, offset * factor), child: c);
      },
      child: child,
    );
  }
}

// ── Buttons ──────────────────────────────────────────────────────────────────

class PrimaryCta extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  const PrimaryCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
  });

  @override
  State<PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<PrimaryCta> {
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _h ? AppColors.brandDark : AppColors.brand,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: _h ? 0.5 : 0.32),
                blurRadius: _h ? 26 : 16,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (widget.icon != null) ...[
                AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  offset: _h ? const Offset(0.18, 0) : Offset.zero,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(widget.icon, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GhostCta extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  const GhostCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
  });

  @override
  State<GhostCta> createState() => _GhostCtaState();
}

class _GhostCtaState extends State<GhostCta> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _h ? mc.panelHi : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _h ? mc.muted : mc.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: mc.text),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: mc.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
