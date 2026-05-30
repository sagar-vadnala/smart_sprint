import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/view/widgets/create_sheets.dart';
import 'package:smart_sprint/features/workspace/view/widgets/task_tile.dart';

enum _Filter { all, today, overdue, done }

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final all = state.myTasks;
    final filtered = switch (_filter) {
      _Filter.all => all.where((t) => !t.isDone).toList(),
      _Filter.today => all.where((t) => t.isDueToday && !t.isDone).toList(),
      _Filter.overdue => all.where((t) => t.isOverdue).toList(),
      _Filter.done => all.where((t) => t.isDone).toList(),
    };

    // Group by status (except when viewing Done).
    final grouped = <TaskStatus, List<Task>>{};
    for (final s in TaskStatus.values) {
      final list = filtered.where((t) => t.status == s).toList();
      if (list.isNotEmpty) grouped[s] = list;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Tasks',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${all.where((t) => !t.isDone).length} open · ${all.where((t) => t.isDone).length} done',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showCreateTaskSheet(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: 'All',
                    count: all.where((t) => !t.isDone).length,
                    selected: _filter == _Filter.all,
                    onTap: () => setState(() => _filter = _Filter.all),
                  ),
                  _FilterChip(
                    label: 'Today',
                    count: state.myDueTodayCount,
                    selected: _filter == _Filter.today,
                    onTap: () => setState(() => _filter = _Filter.today),
                  ),
                  _FilterChip(
                    label: 'Overdue',
                    count: state.myOverdueCount,
                    selected: _filter == _Filter.overdue,
                    accent: AppColors.error,
                    onTap: () => setState(() => _filter = _Filter.overdue),
                  ),
                  _FilterChip(
                    label: 'Done',
                    count: all.where((t) => t.isDone).length,
                    selected: _filter == _Filter.done,
                    accent: AppColors.success,
                    onTap: () => setState(() => _filter = _Filter.done),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? _Empty(filter: _filter)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      children: [
                        for (final entry in grouped.entries) ...[
                          _GroupHeader(
                            status: entry.key,
                            count: entry.value.length,
                          ),
                          ...entry.value.map(
                            (t) => TaskTile(
                              task: t,
                              onTap: () => context.push('/t/${t.id}'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color? accent;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accent ?? AppColors.brand;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? color : border, width: 1.5),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : textColor,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (isDark ? AppColors.darkFill : AppColors.lightFill),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                    ),
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

class _GroupHeader extends StatelessWidget {
  final TaskStatus status;
  final int count;

  const _GroupHeader({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final _Filter filter;

  const _Empty({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final (icon, msg) = switch (filter) {
      _Filter.all => (Icons.task_alt_rounded, 'No open tasks assigned to you'),
      _Filter.today => (Icons.today_rounded, 'Nothing due today'),
      _Filter.overdue => (
        Icons.check_circle_outline_rounded,
        'No overdue tasks — nice work',
      ),
      _Filter.done => (Icons.inbox_rounded, 'No completed tasks yet'),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: muted),
          const SizedBox(height: 14),
          Text(
            msg,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
