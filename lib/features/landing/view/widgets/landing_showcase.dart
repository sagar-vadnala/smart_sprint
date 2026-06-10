import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';

// ── Logo marquee ─────────────────────────────────────────────────────────────

class LandingLogos extends StatelessWidget {
  const LandingLogos({super.key});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return SectionBand(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Text(
            'TRUSTED BY TEAMS THAT SHIP',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: mc.faint,
            ),
          ),
          const SizedBox(height: 28),
          const _Marquee(),
        ],
      ),
    );
  }
}

class _Marquee extends StatefulWidget {
  const _Marquee();

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  static const _names = [
    'Northwind', 'Acme Labs', 'Lumen', 'Foundry', 'Quanta', 'Hikigai', 'Vertex',
  ];
  static const _itemWidth = 190.0;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 28),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final stripWidth = _names.length * _itemWidth;

    Widget row() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final n in _names)
              SizedBox(
                width: _itemWidth,
                child: Center(
                  child: Text(
                    n,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: mc.muted.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
          ],
        );

    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: [
          mc.bg,
          mc.bg.withValues(alpha: 0),
          mc.bg.withValues(alpha: 0),
          mc.bg,
        ],
        stops: const [0.0, 0.08, 0.92, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstOut,
      child: SizedBox(
        height: 34,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final dx = -_c.value * stripWidth;
              // The strip is intentionally wider than the viewport; let it
              // overflow the width constraint (ClipRect hides the excess).
              return OverflowBox(
                maxWidth: double.infinity,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: stripWidth * 2,
                  child: Stack(
                    children: [
                      Transform.translate(offset: Offset(dx, 0), child: row()),
                      Transform.translate(
                          offset: Offset(dx + stripWidth, 0), child: row()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Alternating showcase rows ────────────────────────────────────────────────

class LandingShowcase extends StatelessWidget {
  const LandingShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ShowcaseRow(
          index: '02',
          flip: false,
          kicker: 'Sprints & views',
          accent: AppColors.brand,
          title: 'Plan the sprint,\nthen watch it move.',
          body: 'Group work by sprint, filter to what\'s active, and flip between '
              'a clean list and a visual board without losing your place.',
          bullets: [
            'List and Board, one click apart',
            'Drag work across statuses',
            'Per-sprint progress at a glance',
          ],
          visual: _SprintVisual(),
        ),
        _ShowcaseRow(
          index: '03',
          flip: true,
          kicker: 'Solo & teams',
          accent: AppColors.accent,
          title: 'One app for you —\nand for everyone.',
          body: 'Start solo in your personal space, spin up a shared org when the '
              'team grows. Assignees and invites appear only where collaboration '
              'actually happens.',
          bullets: [
            'Personal space for deep focus',
            'Shared orgs with real members',
            'Invite teammates by email',
          ],
          visual: _TeamVisual(),
        ),
        _ShowcaseRow(
          index: '04',
          flip: false,
          kicker: 'Search',
          accent: AppColors.glowTeal,
          title: 'Find anything\nin a heartbeat.',
          body: 'A keyboard-first command palette searches every workspace and task '
              'in your org and drops you straight onto it — no menu spelunking.',
          bullets: [
            'Search across the whole org',
            'Jump to any task or space',
            'Dark and light, your call',
          ],
          visual: _SearchVisual(),
        ),
      ],
    );
  }
}

class _ShowcaseRow extends StatelessWidget {
  final String index;
  final bool flip;
  final String kicker;
  final Color accent;
  final String title;
  final String body;
  final List<String> bullets;
  final Widget visual;

  const _ShowcaseRow({
    required this.index,
    required this.flip,
    required this.kicker,
    required this.accent,
    required this.title,
    required this.body,
    required this.bullets,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final wide = Landing.isWide(context);
    final mc = MC.of(context);

    final text = Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MonoKicker(index: index, label: kicker, color: accent),
          const SizedBox(height: 20),
          Text(title, style: MType.heading(context)),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(body, style: MType.body(context, size: 16.5)),
          ),
          const SizedBox(height: 24),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, size: 18, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: mc.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final frame = Reveal(
      delayMs: 120,
      child: Parallax(
        factor: flip ? 0.025 : -0.025,
        child: _VisualFrame(accent: accent, child: visual),
      ),
    );

    return SectionBand(
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: flip
                  ? [
                      Expanded(flex: 6, child: frame),
                      const SizedBox(width: 72),
                      Expanded(flex: 5, child: text),
                    ]
                  : [
                      Expanded(flex: 5, child: text),
                      const SizedBox(width: 72),
                      Expanded(flex: 6, child: frame),
                    ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 36), frame],
            ),
    );
  }
}

class _VisualFrame extends StatelessWidget {
  final Color accent;
  final Widget child;
  const _VisualFrame({required this.accent, required this.child});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: mc.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mc.border),
        boxShadow: [
          BoxShadow(
            color: (mc.dark ? Colors.black : accent)
                .withValues(alpha: mc.dark ? 0.4 : 0.08),
            blurRadius: 44,
            spreadRadius: -18,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Mini mocks ───────────────────────────────────────────────────────────────

class _MockRow extends StatelessWidget {
  final Color dot;
  final String label;
  final List<Color> avatars;
  final bool done;
  const _MockRow({
    required this.dot,
    required this.label,
    this.avatars = const [],
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: mc.panelHi,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: mc.borderSoft),
      ),
      child: Row(children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? dot : null,
            border: Border.all(color: dot, width: 2),
          ),
          child: done ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: done ? mc.muted : mc.text,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        for (final c in avatars)
          Container(
            margin: const EdgeInsets.only(left: 4),
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: mc.panelHi, width: 1.5),
            ),
          ),
      ]),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _GroupLabel(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.jetBrainsMono(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: color)),
        const SizedBox(width: 7),
        Text('$count', style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: mc.faint)),
      ]),
    );
  }
}

class _SprintVisual extends StatelessWidget {
  const _SprintVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        _GroupLabel('In progress', AppColors.info, 2),
        _MockRow(dot: AppColors.info, label: 'Ship board ↔ list toggle', avatars: [AppColors.brand, AppColors.glowTeal]),
        _MockRow(dot: AppColors.info, label: 'Sprint filter chips', avatars: [AppColors.accent]),
        SizedBox(height: 6),
        _GroupLabel('Done', AppColors.success, 1),
        _MockRow(dot: AppColors.success, label: 'Design sprint board', avatars: [AppColors.brand], done: true),
      ],
    );
  }
}

class _TeamVisual extends StatelessWidget {
  const _TeamVisual();

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);

    Widget org(IconData icon, Color color, String name, String sub, bool active) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: active ? color.withValues(alpha: 0.4) : mc.borderSoft),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: mc.text)),
            Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: mc.muted)),
          ]),
          const Spacer(),
          if (active) Icon(Icons.check_circle, size: 18, color: color),
        ]),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      org(Icons.person_rounded, AppColors.brand, 'Personal', 'Just you', true),
      org(Icons.groups_rounded, AppColors.glowTeal, 'Hikigai', '5 members', false),
      const SizedBox(height: 4),
      Row(children: [
        for (final c in const [AppColors.brand, AppColors.glowTeal, AppColors.accent, AppColors.info])
          Container(
            margin: const EdgeInsets.only(right: 6),
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: mc.panel, width: 1.5)),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: mc.violet.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
          child: Text('+ Invite', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: mc.violet)),
        ),
      ]),
    ]);
  }
}

class _SearchVisual extends StatelessWidget {
  const _SearchVisual();

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);

    Widget result(IconData icon, Color color, String title, String sub) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: mc.text)),
            Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: mc.muted)),
          ]),
          const Spacer(),
          Icon(Icons.north_east_rounded, size: 14, color: mc.faint),
        ]),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: mc.panelHi,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: mc.violet.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.search_rounded, size: 18, color: mc.muted),
          const SizedBox(width: 10),
          Text('sprint', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: mc.text)),
          Container(width: 1.5, height: 16, margin: const EdgeInsets.only(left: 2), color: mc.violet),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: mc.panel, borderRadius: BorderRadius.circular(5), border: Border.all(color: mc.border)),
            child: Text('⌘K', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: mc.muted)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      result(Icons.grid_view_rounded, AppColors.brand, 'Sprint 14', 'Mobile App · Active'),
      result(Icons.check_circle_outline, AppColors.info, 'Build sprint board', 'Task · In progress'),
      result(Icons.bolt_rounded, AppColors.accent, 'Sprint planning', 'Design System · Backlog'),
    ]);
  }
}

// ── Metrics strip ────────────────────────────────────────────────────────────

class LandingMetrics extends StatelessWidget {
  const LandingMetrics({super.key});

  static const _items = [
    ('2', 'views', 'List & Board'),
    ('∞', 'depth', 'Nested subtasks'),
    ('1', 'workspace', 'Everything together'),
    ('0', 'to start', 'Free, solo or team'),
  ];

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final wide = Landing.isWide(context);

    return SectionBand(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Reveal(
        child: Container(
          decoration: BoxDecoration(
            color: mc.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: mc.border),
          ),
          child: wide
              ? IntrinsicHeight(
                  child: Row(
                    children: [
                      for (int i = 0; i < _items.length; i++) ...[
                        Expanded(child: _Metric(_items[i])),
                        if (i < _items.length - 1)
                          VerticalDivider(width: 1, color: mc.borderSoft),
                      ],
                    ],
                  ),
                )
              : Wrap(
                  children: [
                    for (int i = 0; i < _items.length; i++)
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < Landing.compact
                            ? double.infinity
                            : 260,
                        child: _Metric(_items[i]),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final (String, String, String) data;
  const _Metric(this.data);

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.$1,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -2,
                  color: mc.text,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data.$2,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: mc.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.$3, style: MType.body(context, size: 13.5)),
        ],
      ),
    );
  }
}
