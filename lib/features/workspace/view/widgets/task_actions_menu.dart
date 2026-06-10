import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/adaptive_sheet.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';

/// Three-dots task action menu (Copy link / Move to workspace / Move to sprint
/// / Duplicate / Delete). Lives next to the task title in the detail screen
/// and behind the more-icon on board / list rows.
class TaskActionsButton extends StatelessWidget {
  final Task task;

  /// When true, deleting the task pops the current route afterwards (used on
  /// the task detail screen).
  final bool popOnDelete;

  /// Smaller icon variant used inline in list/board rows.
  final bool compact;

  const TaskActionsButton({
    super.key,
    required this.task,
    this.popOnDelete = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return IconButton(
      iconSize: compact ? 18 : 20,
      padding: compact ? EdgeInsets.zero : null,
      constraints: compact
          ? const BoxConstraints(minWidth: 28, minHeight: 28)
          : null,
      icon: Icon(
        Icons.more_horiz_rounded,
        color: muted,
        size: compact ? 18 : 20,
      ),
      tooltip: 'More',
      onPressed: () =>
          showTaskActions(context, task: task, popOnDelete: popOnDelete),
    );
  }
}

Future<void> showTaskActions(
  BuildContext context, {
  required Task task,
  bool popOnDelete = false,
}) {
  final bloc = context.read<WorkspaceBloc>();
  return showAdaptiveSheet(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _ActionsSheet(task: task, popOnDelete: popOnDelete),
    ),
  );
}

class _ActionsSheet extends StatelessWidget {
  final Task task;
  final bool popOnDelete;

  const _ActionsSheet({required this.task, required this.popOnDelete});

  String _taskUrl() {
    // Web: builds a shareable hash URL (go_router uses fragment routing by
    // default). On mobile this still yields a stable, copy-able token.
    final base = Uri.base;
    if (base.host.isEmpty) return 'smartsprint://t/${task.id}';
    return '${base.origin}/#/t/${task.id}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bloc = context.read<WorkspaceBloc>();

    void close() => Navigator.of(context).pop();
    void toast(String text, {bool danger = false}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: danger ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    return Container(
      decoration: sheetSurfaceDecoration(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            _Action(
              icon: Icons.link_rounded,
              label: 'Copy link',
              onTap: () async {
                final url = _taskUrl();
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  close();
                  toast('Link copied');
                }
              },
            ),
            _Action(
              icon: Icons.drive_file_move_outline,
              label: 'Move to workspace…',
              onTap: () async {
                // Keep this sheet mounted underneath so the picker can offer a
                // back button; close everything once a move is made.
                final moved = await _pickWorkspace(context, task, bloc);
                if (moved == true && context.mounted) close();
              },
            ),
            _Action(
              icon: Icons.bolt_outlined,
              label: 'Move to sprint…',
              onTap: () async {
                final moved = await _pickSprint(context, task, bloc);
                if (moved == true && context.mounted) close();
              },
            ),
            _Action(
              icon: Icons.copy_all_rounded,
              label: 'Duplicate',
              onTap: () {
                bloc.add(TaskDuplicated(task.id));
                close();
                toast('Task duplicated');
              },
            ),
            Divider(height: 1, color: border),
            _Action(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              danger: true,
              onTap: () {
                bloc.add(TaskDeleted(task.id));
                close();
                if (popOnDelete && context.mounted) {
                  Navigator.of(context).maybePop();
                }
                toast('Task deleted', danger: true);
              },
            ),
            const SizedBox(height: 8),
            // Hint
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: muted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Moving across workspaces clears the task\'s sprint.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = danger
        ? AppColors.error
        : (isDark ? AppColors.darkText : AppColors.lightText);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 19, color: textColor),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Move-to pickers ──────────────────────────────────────────────────────────

Future<bool?> _pickWorkspace(BuildContext context, Task task, WorkspaceBloc bloc) {
  final state = bloc.state;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showAdaptiveSheet<bool>(
    context: context,
    builder: (_) => _PickerSheet(
      title: 'Move to workspace',
      showBack: true,
      items: state.projects.map((p) {
        return _PickerItem(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(p.icon, size: 15, color: p.color),
          ),
          label: p.name,
          selected: p.id == task.projectId,
          onTap: () {
            bloc.add(TaskMovedToProject(task.id, p.id));
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Moved to ${p.name}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        );
      }).toList(),
      isDark: isDark,
    ),
  );
}

Future<bool?> _pickSprint(BuildContext context, Task task, WorkspaceBloc bloc) {
  final state = bloc.state;
  final sprints = state.sprintsForProject(task.projectId);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  return showAdaptiveSheet<bool>(
    context: context,
    builder: (_) => _PickerSheet(
      title: 'Move to sprint',
      isDark: isDark,
      showBack: true,
      items: [
        _PickerItem(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inbox_rounded, size: 15, color: muted),
          ),
          label: 'Backlog (no sprint)',
          selected: task.sprintId == null,
          onTap: () {
            bloc.add(TaskMovedToSprint(task.id, null));
            Navigator.of(context).pop(true);
          },
        ),
        ...sprints.map(
          (s) => _PickerItem(
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: s.status.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bolt_rounded, size: 15, color: s.status.color),
            ),
            label: s.name,
            selected: s.id == task.sprintId,
            onTap: () {
              bloc.add(TaskMovedToSprint(task.id, s.id));
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ],
    ),
  );
}

class _PickerItem {
  final Widget leading;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerItem({
    required this.leading,
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final bool isDark;

  /// Shows a back arrow that returns to the sheet that opened this picker.
  final bool showBack;

  const _PickerSheet({
    required this.title,
    required this.items,
    required this.isDark,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: sheetSurfaceDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          Padding(
            padding: EdgeInsets.fromLTRB(showBack ? 10 : 22, 8, 22, 12),
            child: Row(
              children: [
                if (showBack)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkFill : AppColors.lightFill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                bottom: 12 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                return InkWell(
                  onTap: it.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        it.leading,
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            it.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (it.selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.brand,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
