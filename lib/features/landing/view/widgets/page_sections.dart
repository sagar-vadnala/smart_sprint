import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';

/// Reusable building blocks for the marketing sub-pages (Features, Sprints,
/// Teams, Pricing). Keeps each page file thin and consistent.

/// Top-of-page hero for sub-pages: mono kicker, big title, lede, CTAs.
class PageHero extends StatelessWidget {
  final String kicker;
  final String title;
  final String lede;
  final Color accent;
  const PageHero({
    super.key,
    required this.kicker,
    required this.title,
    required this.lede,
    this.accent = AppColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    final compact = Landing.isCompact(context);
    return FramedContent(
      padding: EdgeInsets.only(top: compact ? 40 : 80, bottom: compact ? 24 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: MonoKicker(label: kicker, color: accent)),
          const SizedBox(height: 24),
          Reveal(
            delayMs: 80,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Text(title, style: MType.display(context)),
            ),
          ),
          const SizedBox(height: 24),
          Reveal(
            delayMs: 160,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Text(lede, style: MType.body(context, size: 18)),
            ),
          ),
          const SizedBox(height: 32),
          Reveal(
            delayMs: 240,
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                PrimaryCta(label: 'Start for free', onTap: () => context.go('/signup')),
                GhostCta(
                  label: 'Log in',
                  icon: Icons.arrow_outward_rounded,
                  onTap: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoItem {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  const InfoItem(this.icon, this.accent, this.title, this.body);
}

/// A responsive grid of bordered info cards.
class InfoGrid extends StatelessWidget {
  final String index;
  final String kicker;
  final String heading;
  final List<InfoItem> items;
  const InfoGrid({
    super.key,
    required this.index,
    required this.kicker,
    required this.heading,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= Landing.wide ? 3 : (width >= Landing.compact ? 2 : 1);

    return SectionBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: MonoKicker(index: index, label: kicker)),
          const SizedBox(height: 20),
          Reveal(
            delayMs: 60,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(heading, style: MType.heading(context)),
            ),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(builder: (context, c) {
            const gap = 16.0;
            final w = (c.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (int i = 0; i < items.length; i++)
                  SizedBox(
                    width: w,
                    child: Reveal(delayMs: (i % columns) * 70, child: _InfoCard(items[i])),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _InfoCard extends StatefulWidget {
  final InfoItem item;
  const _InfoCard(this.item);

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final it = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _h ? mc.panelHi : mc.panel,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _h ? it.accent.withValues(alpha: 0.5) : mc.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: it.accent.withValues(alpha: mc.dark ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: it.accent.withValues(alpha: 0.28)),
              ),
              child: Icon(it.icon, color: it.accent, size: 20),
            ),
            const SizedBox(height: 16),
            Text(it.title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5, fontWeight: FontWeight.w700, color: mc.text)),
            const SizedBox(height: 7),
            Text(it.body, style: MType.body(context, size: 14)),
          ],
        ),
      ),
    );
  }
}

/// Numbered "how it works" steps.
class StepList extends StatelessWidget {
  final String index;
  final String kicker;
  final String heading;
  final List<(String, String)> steps;
  const StepList({
    super.key,
    required this.index,
    required this.kicker,
    required this.heading,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return SectionBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: MonoKicker(index: index, label: kicker)),
          const SizedBox(height: 20),
          Reveal(
            delayMs: 60,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(heading, style: MType.heading(context)),
            ),
          ),
          const SizedBox(height: 36),
          for (int i = 0; i < steps.length; i++)
            Reveal(
              delayMs: i * 80,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: mc.panel,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: mc.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0${i + 1}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: mc.violet,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].$1,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18, fontWeight: FontWeight.w700, color: mc.text)),
                          const SizedBox(height: 6),
                          Text(steps[i].$2, style: MType.body(context, size: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PricingTier {
  final String name;
  final String price;
  final String period;
  final String blurb;
  final List<String> features;
  final bool highlighted;
  final String cta;
  const PricingTier({
    required this.name,
    required this.price,
    required this.period,
    required this.blurb,
    required this.features,
    required this.cta,
    this.highlighted = false,
  });
}

class PricingTiers extends StatelessWidget {
  final List<PricingTier> tiers;
  const PricingTiers({super.key, required this.tiers});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= Landing.wide ? 3 : (width >= Landing.compact ? 1 : 1);

    return SectionBand(
      topBorder: false,
      padding: const EdgeInsets.only(top: 8, bottom: 84),
      child: LayoutBuilder(builder: (context, c) {
        const gap = 18.0;
        final w = columns == 1
            ? c.maxWidth.clamp(0, 460).toDouble()
            : (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < tiers.length; i++)
              SizedBox(
                width: w,
                child: Reveal(delayMs: i * 90, child: _PricingCard(tiers[i])),
              ),
          ],
        );
      }),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final PricingTier tier;
  const _PricingCard(this.tier);

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final hi = tier.highlighted;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: hi ? mc.violet.withValues(alpha: mc.dark ? 0.10 : 0.05) : mc.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hi ? mc.violet.withValues(alpha: 0.6) : mc.border,
          width: hi ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(tier.name,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 17, fontWeight: FontWeight.w700, color: mc.text)),
              const Spacer(),
              if (hi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: mc.violet.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('POPULAR',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: mc.violet)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(tier.price,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      color: mc.text)),
              const SizedBox(width: 6),
              Text(tier.period, style: MType.body(context, size: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(tier.blurb, style: MType.body(context, size: 14)),
          const SizedBox(height: 22),
          for (final f in tier.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: mc.violet),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(f,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w500, color: mc.text)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: hi
                ? PrimaryCta(
                    label: tier.cta,
                    icon: null,
                    onTap: () => context.go('/signup'),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  )
                : GhostCta(
                    label: tier.cta,
                    onTap: () => context.go('/signup'),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Simple FAQ accordion list.
class FaqList extends StatelessWidget {
  final String index;
  final List<(String, String)> items;
  const FaqList({super.key, required this.index, required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(child: MonoKicker(index: index, label: 'FAQ')),
          const SizedBox(height: 20),
          Reveal(
            delayMs: 60,
            child: Text('Questions, answered', style: MType.heading(context)),
          ),
          const SizedBox(height: 32),
          for (int i = 0; i < items.length; i++)
            Reveal(delayMs: (i * 60).clamp(0, 300), child: _FaqRow(q: items[i].$1, a: items[i].$2)),
        ],
      ),
    );
  }
}

class _FaqRow extends StatefulWidget {
  final String q;
  final String a;
  const _FaqRow({required this.q, required this.a});

  @override
  State<_FaqRow> createState() => _FaqRowState();
}

class _FaqRowState extends State<_FaqRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: mc.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mc.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.q,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w700, color: mc.text)),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _open ? 0.125 : 0,
                    child: Icon(Icons.add_rounded, color: mc.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.a, style: MType.body(context, size: 15)),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
