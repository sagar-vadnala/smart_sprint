import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/landing/view/widgets/landing_common.dart';

/// A Flutter-drawn mock of the SmartSprint app window — window chrome, a mini
/// sidebar and a sprint list with status dots, assignees and priority flags.
/// Pure decoration; shows the product's visual language in the hero.
class ProductPreview extends StatelessWidget {
  const ProductPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final mc = MC.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mc.border),
        boxShadow: [
          BoxShadow(
            color: (mc.dark ? Colors.black : AppColors.brand)
                .withValues(alpha: mc.dark ? 0.55 : 0.10),
            blurRadius: 50,
            spreadRadius: -16,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: mc.panel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WindowBar(mc: mc),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MiniSidebar(mc: mc),
                    Expanded(child: _BoardArea(mc: mc)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowBar extends StatelessWidget {
  final MC mc;
  const _WindowBar({required this.mc});

  Widget _dot(Color c) => Container(
      width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: mc.panelHi,
        border: Border(bottom: BorderSide(color: mc.borderSoft)),
      ),
      child: Row(
        children: [
          _dot(const Color(0xFFFF5F57)),
          const SizedBox(width: 7),
          _dot(const Color(0xFFFEBC2E)),
          const SizedBox(width: 7),
          _dot(const Color(0xFF28C840)),
          const Spacer(),
          Text(
            'app.smartsprint.io',
            style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: mc.faint),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _MiniSidebar extends StatelessWidget {
  final MC mc;
  const _MiniSidebar({required this.mc});

  @override
  Widget build(BuildContext context) {
    Widget nav(IconData i, String l, {bool active = false}) => Container(
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: active ? mc.violet.withValues(alpha: 0.14) : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(children: [
            Icon(i, size: 14, color: active ? mc.violet : mc.faint),
            const SizedBox(width: 9),
            Text(l,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? mc.text : mc.muted,
                )),
          ]),
        );

    Widget space(Color c, String l) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(children: [
            Container(
                width: 11,
                height: 11,
                decoration:
                    BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 9),
            Text(l,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, fontWeight: FontWeight.w500, color: mc.muted)),
          ]),
        );

    return Container(
      width: 156,
      decoration: BoxDecoration(
        color: mc.bg,
        border: Border(right: BorderSide(color: mc.borderSoft)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          nav(Icons.home_rounded, 'Home'),
          nav(Icons.bolt_rounded, 'My Tasks', active: true),
          nav(Icons.grid_view_rounded, 'Spaces'),
          nav(Icons.inbox_rounded, 'Inbox'),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 9, bottom: 6),
            child: Text('SPACES',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: mc.faint,
                )),
          ),
          space(AppColors.brand, 'Mobile App'),
          space(AppColors.glowTeal, 'Design System'),
          space(AppColors.accent, 'API Platform'),
        ],
      ),
    );
  }
}

class _BoardArea extends StatelessWidget {
  final MC mc;
  const _BoardArea({required this.mc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text('Sprint 14',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w800, color: mc.text)),
            const SizedBox(width: 8),
            _Tag(label: 'Active', color: AppColors.success),
            const Spacer(),
            Icon(Icons.view_list_rounded, size: 15, color: mc.violet),
            const SizedBox(width: 8),
            Icon(Icons.view_kanban_outlined, size: 15, color: mc.faint),
          ]),
          const SizedBox(height: 14),
          _Group(mc: mc, status: 'In progress', color: AppColors.info, count: 2, rows: const [
            _RowData('Build sprint board view', _Pri.high, [Color(0xFF6C47FF), Color(0xFF14B8A6)]),
            _RowData('Wire activity timeline', _Pri.normal, [Color(0xFFFF6B35)]),
          ]),
          const SizedBox(height: 12),
          _Group(mc: mc, status: 'To do', color: AppColors.warning, count: 2, rows: const [
            _RowData('Design task detail panel', _Pri.urgent, [Color(0xFF14B8A6)]),
            _RowData('Add nested subtasks', _Pri.low, [Color(0xFF6C47FF), Color(0xFFFF6B35)]),
          ]),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final MC mc;
  final String status;
  final Color color;
  final int count;
  final List<_RowData> rows;
  const _Group({
    required this.mc,
    required this.status,
    required this.color,
    required this.count,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(5)),
            child: Text(status.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: color)),
          ),
          const SizedBox(width: 8),
          Text('$count',
              style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: mc.faint)),
        ]),
        const SizedBox(height: 8),
        for (final r in rows) ...[
          _TaskRow(mc: mc, data: r, color: color),
          const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  final MC mc;
  final _RowData data;
  final Color color;
  const _TaskRow({required this.mc, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: mc.panelHi,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mc.borderSoft),
      ),
      child: Row(children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: mc.text)),
        ),
        const SizedBox(width: 8),
        Icon(Icons.flag_rounded, size: 13, color: _priColor(data.priority)),
        const SizedBox(width: 10),
        _Avatars(colors: data.assignees, ring: mc.panelHi),
      ]),
    );
  }

  Color _priColor(_Pri p) => switch (p) {
        _Pri.urgent => AppColors.error,
        _Pri.high => AppColors.accent,
        _Pri.normal => AppColors.info,
        _Pri.low => AppColors.lightTextMuted,
      };
}

class _Avatars extends StatelessWidget {
  final List<Color> colors;
  final Color ring;
  const _Avatars({required this.colors, required this.ring});

  @override
  Widget build(BuildContext context) {
    const s = 19.0;
    return SizedBox(
      width: s + (colors.length - 1) * 12,
      height: s,
      child: Stack(children: [
        for (int i = 0; i < colors.length; i++)
          Positioned(
            left: i * 12.0,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 1.5)),
            ),
          ),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(100)),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

enum _Pri { urgent, high, normal, low }

class _RowData {
  final String title;
  final _Pri priority;
  final List<Color> assignees;
  const _RowData(this.title, this.priority, this.assignees);
}
