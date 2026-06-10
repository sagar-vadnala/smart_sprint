import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/theme_cubit.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';

const marketingNavLinks = <(String, String)>[
  ('Features', '/features'),
  ('Sprints', '/sprints'),
  ('Teams', '/teams'),
  ('Pricing', '/pricing'),
];

/// Sticky top navigation shared by every marketing page.
class LandingNav extends StatelessWidget {
  final bool scrolled;
  final String currentPath;
  const LandingNav({
    super.key,
    required this.scrolled,
    this.currentPath = '/',
  });

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final compact = Landing.isCompact(context);
    final showLinks = MediaQuery.sizeOf(context).width >= Landing.wide;

    return ClipRect(
      child: BackdropFilter(
        filter: scrolled
            ? ImageFilter.blur(sigmaX: 16, sigmaY: 16)
            : ImageFilter.blur(sigmaX: 0.001, sigmaY: 0.001),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: scrolled
                ? mc.bg.withValues(alpha: mc.dark ? 0.72 : 0.78)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: scrolled ? mc.border : Colors.transparent,
              ),
            ),
          ),
          child: FramedContent(
            padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: const Wordmark(),
                  ),
                ),
                const Spacer(),
                if (showLinks) ...[
                  for (final l in marketingNavLinks)
                    _NavLink(
                      label: l.$1,
                      active: currentPath == l.$2,
                      onTap: () => context.go(l.$2),
                    ),
                  const SizedBox(width: 14),
                  _ThemeToggle(mc: mc),
                  const SizedBox(width: 6),
                  _NavLink(label: 'Log in', onTap: () => context.go('/login')),
                  const SizedBox(width: 12),
                  PrimaryCta(
                    label: 'Get started',
                    icon: null,
                    onTap: () => context.go('/signup'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  ),
                ] else ...[
                  _ThemeToggle(mc: mc),
                  const SizedBox(width: 4),
                  PrimaryCta(
                    label: 'Start',
                    icon: null,
                    onTap: () => context.go('/signup'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  const SizedBox(width: 4),
                  _MobileMenu(currentPath: currentPath),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavLink({required this.label, required this.onTap, this.active = false});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final on = _h || widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: on ? mc.text : mc.muted,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: widget.active ? 16 : (_h ? 16 : 0),
                color: mc.violet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final MC mc;
  const _ThemeToggle({required this.mc});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: mc.dark ? 'Light mode' : 'Dark mode',
      onPressed: () => context.read<ThemeCubit>().toggle(),
      icon: Icon(
        mc.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 20,
        color: mc.text,
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  final String currentPath;
  const _MobileMenu({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu_rounded, color: mc.text),
      color: mc.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: mc.border),
      ),
      onSelected: (v) => context.go(v),
      itemBuilder: (context) => [
        for (final l in marketingNavLinks)
          PopupMenuItem(
            value: l.$2,
            child: Text(
              l.$1,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: currentPath == l.$2 ? mc.violet : mc.text,
              ),
            ),
          ),
        PopupMenuItem(
          value: '/login',
          child: Text(
            'Log in',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: mc.text,
            ),
          ),
        ),
      ],
    );
  }
}
