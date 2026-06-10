import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';

/// Page footer — dense, bordered, editorial. Shared by all marketing pages.
class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final wide = Landing.isWide(context);

    final brand = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Wordmark(),
          const SizedBox(height: 16),
          Text(
            'The focused workspace for sprints, tasks and teams. '
            'Work smarter. Ship faster.',
            style: MType.body(context, size: 14),
          ),
          const SizedBox(height: 18),
          Text(
            'hello@smartsprint.app',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: mc.violet,
            ),
          ),
        ],
      ),
    );

    final columns = [
      _FooterCol(title: 'Product', links: const [
        ('Features', '/features'),
        ('Sprints', '/sprints'),
        ('Teams', '/teams'),
        ('Pricing', '/pricing'),
      ]),
      _FooterCol(title: 'Get started', links: const [
        ('Create account', '/signup'),
        ('Log in', '/login'),
      ]),
      _FooterCol(title: 'Company', links: const [
        ('About', '/'),
        ('Blog', '/'),
        ('Careers', '/'),
        ('Contact', '/'),
      ]),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: mc.border)),
      ),
      child: FramedContent(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: brand),
                  const Spacer(),
                  for (final c in columns) ...[
                    c,
                    const SizedBox(width: 64),
                  ],
                ],
              )
            else ...[
              brand,
              const SizedBox(height: 40),
              Wrap(spacing: 60, runSpacing: 32, children: columns),
            ],
            const SizedBox(height: 48),
            Divider(color: mc.borderSoft, height: 1),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Text(
                  '© 2026 SmartSprint — built with Flutter',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: mc.faint,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniLink('Privacy'),
                    const SizedBox(width: 22),
                    _MiniLink('Terms'),
                    const SizedBox(width: 22),
                    _MiniLink('Security'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  final String title;
  final List<(String, String)> links;
  const _FooterCol({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: mc.faint,
          ),
        ),
        const SizedBox(height: 16),
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FooterLink(label: l.$1, to: l.$2),
          ),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final String to;
  const _FooterLink({required this.label, required this.to});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: () => context.go(widget.to),
        child: Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _h ? mc.text : mc.muted,
          ),
        ),
      ),
    );
  }
}

class _MiniLink extends StatelessWidget {
  final String label;
  const _MiniLink(this.label);

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: mc.faint,
        ),
      ),
    );
  }
}
