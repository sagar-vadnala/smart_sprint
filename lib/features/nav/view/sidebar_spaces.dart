import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/nav/cubit/sidebar_cubit.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/model/project.dart';
import 'package:smart_sprint/features/workspace/view/widgets/create_sheets.dart';

/// The "Spaces" tree shown in the side rail: every workspace in the current
/// organization, expandable to its sprints, with favourites pinned on top.
class SidebarSpaces extends StatelessWidget {
  const SidebarSpaces({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final favIds = context.watch<SidebarCubit>().state.favoriteWorkspaceIds;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final workspaces = state.projects;
    final favourites = workspaces.where((w) => favIds.contains(w.id)).toList();
    final others = workspaces.where((w) => !favIds.contains(w.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (favourites.isNotEmpty) ...[
          _SectionHeader(label: 'Favorites', muted: muted),
          ...favourites.map((w) => _SpaceTile(workspace: w)),
          const SizedBox(height: 6),
        ],
        _SectionHeader(
          label: 'Spaces',
          muted: muted,
          onAdd: () => showCreateProjectSheet(context),
        ),
        ...others.map((w) => _SpaceTile(workspace: w)),
        _NewSpaceRow(onTap: () => showCreateProjectSheet(context)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color muted;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.label, required this.muted, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 4, 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: muted,
            ),
          ),
          const Spacer(),
          if (onAdd != null)
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.add_rounded, size: 16, color: muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpaceTile extends StatefulWidget {
  final Project workspace;

  const _SpaceTile({required this.workspace});

  @override
  State<_SpaceTile> createState() => _SpaceTileState();
}

class _SpaceTileState extends State<_SpaceTile> {
  bool _expanded = false;

  void _open() => context.push('/w/${widget.workspace.id}');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final sidebar = context.watch<SidebarCubit>();
    final w = widget.workspace;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final sprints = state.sprintsForProject(w.id);
    final taskCount = state.tasksForProject(w.id).length;
    final isFav = sidebar.state.favoriteWorkspaceIds.contains(w.id);
    final showCounts = sidebar.state.showCounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HoverRow(
          onTap: _open,
          child: Row(
            children: [
              // Expand chevron (sprints + backlog always expandable)
              SizedBox(
                width: 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                      color: muted,
                    ),
                  ),
                ),
              ),
              // Coloured space icon
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: w.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(w.icon, size: 14, color: w.color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  w.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (showCounts && taskCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '$taskCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
              // Favourite star
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => sidebar.toggleFavorite(w.id),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: isFav ? AppColors.warning : muted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Nested: sprints + backlog with a guide line
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: 19),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: border, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in sprints)
                    _SubRow(
                      icon: Icons.bolt_rounded,
                      iconColor: s.status.color,
                      label: s.name,
                      count: showCounts ? state.tasksForSprint(s.id).length : 0,
                      onTap: () => context.push('/w/${w.id}?sprint=${s.id}'),
                    ),
                  // Backlog — tasks in this workspace with no sprint set.
                  _SubRow(
                    icon: Icons.inbox_outlined,
                    iconColor: muted,
                    label: 'Backlog',
                    count: showCounts
                        ? state
                              .tasksForProject(w.id)
                              .where((t) => t.sprintId == null)
                              .length
                        : 0,
                    onTap: () => context.push('/w/${w.id}?sprint=backlog'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SubRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _SubRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return _HoverRow(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ),
          if (count > 0)
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _NewSpaceRow extends StatelessWidget {
  final VoidCallback onTap;

  const _NewSpaceRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return _HoverRow(
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: 20),
          Icon(Icons.add_rounded, size: 16, color: muted),
          const SizedBox(width: 9),
          Text(
            'New Space',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact row with a hover highlight, used throughout the tree.
class _HoverRow extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  const _HoverRow({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        hoverColor: (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.05,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ─── Customize sidebar ────────────────────────────────────────────────────────

Future<void> showCustomizeSidebar(BuildContext context) {
  final sidebar = context.read<SidebarCubit>();
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) =>
        BlocProvider.value(value: sidebar, child: const _CustomizeSheet()),
  );
}

class _CustomizeSheet extends StatelessWidget {
  const _CustomizeSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final cubit = context.watch<SidebarCubit>();
    final s = cubit.state;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
            child: Row(
              children: [
                Text(
                  'Customize sidebar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose what appears in your navigation.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _toggle(
            context,
            icon: Icons.grid_view_rounded,
            title: 'Spaces',
            subtitle: 'Show the full workspace tree',
            value: s.showSpaces,
            onChanged: cubit.setShowSpaces,
          ),
          _toggle(
            context,
            icon: Icons.history_rounded,
            title: 'Recents',
            subtitle: 'Quick access to recently opened',
            value: s.showRecents,
            onChanged: cubit.setShowRecents,
          ),
          _toggle(
            context,
            icon: Icons.tag_rounded,
            title: 'Task counts',
            subtitle: 'Show task totals beside items',
            value: s.showCounts,
            onChanged: cubit.setShowCounts,
          ),
          SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _toggle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}
