import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';

class LandingFeatures extends StatelessWidget {
  const LandingFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = Landing.isWide(context);
    final medium = MediaQuery.sizeOf(context).width >= Landing.compact;

    return SectionBand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(child: MonoKicker(index: '01', label: 'Capabilities')),
          const SizedBox(height: 22),
          Reveal(
            delayMs: 60,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'One workspace that replaces the five tools your team keeps '
                'switching between.',
                style: MType.heading(context),
              ),
            ),
          ),
          const SizedBox(height: 44),
          if (wide)
            _bentoWide(context)
          else
            _stack(context, columns: medium ? 2 : 1),
        ],
      ),
    );
  }

  Widget _bentoWide(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: Reveal(child: _Tile(_features[0], visual: const _StatusFlow())),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Expanded(child: Reveal(delayMs: 80, child: _Tile(_features[1]))),
                    const SizedBox(height: 18),
                    Expanded(child: Reveal(delayMs: 140, child: _Tile(_features[2]))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Reveal(delayMs: 60, child: _Tile(_features[3]))),
              const SizedBox(width: 18),
              Expanded(child: Reveal(delayMs: 120, child: _Tile(_features[4]))),
              const SizedBox(width: 18),
              Expanded(child: Reveal(delayMs: 180, child: _Tile(_features[5]))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stack(BuildContext context, {required int columns}) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 16.0;
      final w = (c.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (int i = 0; i < _features.length; i++)
            SizedBox(
              width: w,
              child: Reveal(delayMs: (i % columns) * 70, child: _Tile(_features[i])),
            ),
        ],
      );
    });
  }
}

class _Feature {
  final String index;
  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  const _Feature(this.index, this.icon, this.accent, this.title, this.body);
}

const _features = <_Feature>[
  _Feature('01', Icons.check_circle_outline, AppColors.brand, 'Tasks that move',
      'Push every task through To do, In progress, In review and Done — from a tidy list or a visual board, whichever you prefer.'),
  _Feature('02', Icons.bolt_rounded, AppColors.accent, 'Sprints with focus',
      'Plan into sprints, zero in on what\'s active, keep a backlog one tap away.'),
  _Feature('03', Icons.account_tree_outlined, AppColors.glowTeal, 'Nested subtasks',
      'Break work down as far as it needs to go — each subtask owns its status, assignees and due date.'),
  _Feature('04', Icons.forum_outlined, AppColors.info, 'Activity & comments',
      'Every task keeps a live timeline and threaded comments, so the reasoning is never lost.'),
  _Feature('05', Icons.workspaces_outline, AppColors.brand, 'Solo or team',
      'A personal space for deep focus and shared orgs for teams — switch in one click.'),
  _Feature('06', Icons.search_rounded, AppColors.accent, 'Command search',
      'A keyboard-first palette jumps you to any space or task in the org.'),
];

class _Tile extends StatefulWidget {
  final _Feature feature;
  final Widget? visual;
  const _Tile(this.feature, {this.visual});

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    final f = widget.feature;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _h ? mc.panelHi : mc.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _h ? f.accent.withValues(alpha: 0.5) : mc.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: f.accent.withValues(alpha: mc.dark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: f.accent.withValues(alpha: 0.28)),
                  ),
                  child: Icon(f.icon, color: f.accent, size: 21),
                ),
                const Spacer(),
                Text(
                  f.index,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: mc.faint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              f.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: mc.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(f.body, style: MType.body(context, size: 14.5)),
            if (widget.visual != null) ...[
              const SizedBox(height: 22),
              widget.visual!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Mini status-pipeline visual for the big tile.
class _StatusFlow extends StatelessWidget {
  const _StatusFlow();

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    const stages = [
      ('To do', AppColors.warning),
      ('In progress', AppColors.info),
      ('In review', AppColors.brand),
      ('Done', AppColors.success),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: stages[i].$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: stages[i].$2.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: stages[i].$2, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  stages[i].$1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: mc.text,
                  ),
                ),
              ],
            ),
          ),
          if (i < stages.length - 1)
            Icon(Icons.arrow_forward_rounded, size: 14, color: mc.faint),
        ],
      ],
    );
  }
}
