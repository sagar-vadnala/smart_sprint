import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/subtask.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/view/widgets/assignee_sheet.dart';
import 'package:smart_sprint/features/workspace/view/widgets/create_sheets.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';
import 'package:smart_sprint/features/workspace/view/widgets/status_picker.dart';
import 'package:smart_sprint/features/workspace/view/widgets/task_actions_menu.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Spreadsheet-style task list (ClickUp "List" view).
///
/// COMPONENT CONTRACT (read before adding new task widgets):
/// • [TaskColumns] is the single source of truth for column widths. The header
///   row, every task row, and every subtask row consume it, so they always
///   stay aligned. Never hard-code these widths anywhere else.
/// • All components here are presentational + dispatch existing WorkspaceBloc
///   events. They never fetch data, so the backend swap (SeedData → API) does
///   not touch this file.
/// • Use [TaskListView] to render a group of tasks as a list. Use the card-style
///   `TaskTile` (task_tile.dart) for dashboards/feeds. Don't invent a third.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class TaskColumns {
  /// Width reserved for the chevron + status dot before the name.
  static const double lead = 46;
  static const double assignee = 72;
  static const double due = 92;
  static const double priority = 52;
  static const double rowPadH = 14;
}

class TaskListView extends StatefulWidget {
  final List<Task> tasks;
  final String projectId;

  /// Optional sprint scope — when set, the per-group "Add Task" presets this
  /// sprint so new tasks join the sprint you're already viewing.
  final String? sprintId;

  /// Statuses to show as groups, in order. Defaults to all statuses.
  final List<TaskStatus> statuses;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.projectId,
    this.sprintId,
    this.statuses = TaskStatus.values,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final Set<TaskStatus> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
      children: [
        for (final status in widget.statuses)
          _TaskGroup(
            status: status,
            tasks: widget.tasks.where((t) => t.status == status).toList(),
            projectId: widget.projectId,
            sprintId: widget.sprintId,
            collapsed: _collapsed.contains(status),
            onToggleCollapse: () => setState(() {
              if (!_collapsed.remove(status)) _collapsed.add(status);
            }),
          ),
      ],
    );
  }
}

// ─── Group (status section) ───────────────────────────────────────────────────

class _TaskGroup extends StatelessWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final String projectId;
  final String? sprintId;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const _TaskGroup({
    required this.status,
    required this.tasks,
    required this.projectId,
    required this.sprintId,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        InkWell(
          onTap: onToggleCollapse,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: collapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: muted,
                  ),
                ),
                const SizedBox(width: 4),
                _StatusPill(status: status),
                const SizedBox(width: 8),
                Text(
                  '${tasks.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!collapsed) ...[
          const _ColumnHeader(),
          _Divider(),
          ...tasks.map((t) => TaskListRow(task: t)),
          _AddTaskRow(projectId: projectId, sprintId: sprintId, status: status),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final TaskStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.shortLabel,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Column header ────────────────────────────────────────────────────────────

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    TextStyle style() => GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: muted,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskColumns.rowPadH,
        vertical: 6,
      ),
      child: Row(
        children: [
          SizedBox(width: TaskColumns.lead),
          Expanded(child: Text('Name', style: style())),
          SizedBox(
            width: TaskColumns.assignee,
            child: Text('Assignee', style: style()),
          ),
          SizedBox(
            width: TaskColumns.due,
            child: Text('Due date', style: style()),
          ),
          SizedBox(
            width: TaskColumns.priority,
            child: Text('Priority', style: style()),
          ),
        ],
      ),
    );
  }
}

// ─── Task row (expandable to subtasks) ────────────────────────────────────────

class TaskListRow extends StatefulWidget {
  final Task task;

  const TaskListRow({super.key, required this.task});

  @override
  State<TaskListRow> createState() => _TaskListRowState();
}

class _TaskListRowState extends State<TaskListRow> {
  bool _expanded = false;

  void _openDetail() => context.push('/t/${widget.task.id}');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = widget.task;
    final state = context.watch<WorkspaceBloc>().state;
    final project = state.projectById(task.projectId);
    final assignees = state.membersFor(task.assigneeIds);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final hover = isDark ? AppColors.darkFill : AppColors.lightFill;

    return Column(
      children: [
        InkWell(
          onTap: _openDetail,
          hoverColor: hover.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TaskColumns.rowPadH,
              vertical: 9,
            ),
            child: Row(
              children: [
                // Name column (lead + name + subtask count)
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: task.hasSubtasks
                            ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => _expanded = !_expanded),
                                child: AnimatedRotation(
                                  turns: _expanded ? 0 : -0.25,
                                  duration: const Duration(milliseconds: 150),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: muted,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      StatusPickerButton(task: task, size: 18),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: task.isDone ? muted : textColor,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: muted,
                          ),
                        ),
                      ),
                      if (task.hasSubtasks) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.account_tree_outlined,
                          size: 13,
                          color: muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${task.subtaskDoneCount}/${task.subtaskTotal}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Assignee column
                SizedBox(
                  width: TaskColumns.assignee,
                  child: _AssigneeCell(
                    assignees: assignees,
                    onTap: () {
                      final members = state.membersFor(
                        project?.memberIds ?? [],
                      );
                      showAssigneeSheet(
                        context,
                        members: members,
                        selected: task.assigneeIds,
                        onChanged: (ids) => context.read<WorkspaceBloc>().add(
                          TaskAssigneesChanged(task.id, ids),
                        ),
                      );
                    },
                  ),
                ),

                // Due column
                SizedBox(
                  width: TaskColumns.due,
                  child: _DueCell(
                    task: task,
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: task.dueDate ?? now,
                        firstDate: now.subtract(const Duration(days: 365)),
                        lastDate: now.add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null && context.mounted) {
                        context.read<WorkspaceBloc>().add(
                          TaskDueDateChanged(task.id, picked),
                        );
                      }
                    },
                  ),
                ),

                // Priority column
                SizedBox(
                  width: TaskColumns.priority,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnchoredTap(
                      onTap: (pos) async {
                        final p = await pickPriority(
                          context,
                          pos,
                          task.priority,
                        );
                        if (p != null &&
                            p != task.priority &&
                            context.mounted) {
                          context.read<WorkspaceBloc>().add(
                            TaskPriorityChanged(task.id, p),
                          );
                        }
                      },
                      child: Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: task.priority == TaskPriority.normal
                            ? muted
                            : task.priority.color,
                      ),
                    ),
                  ),
                ),

                // 3-dots actions
                TaskActionsButton(task: task, compact: true),
              ],
            ),
          ),
        ),
        _Divider(),

        // Expanded subtasks (recursive)
        if (_expanded && task.hasSubtasks)
          ...task.subtasks.map(
            (s) => _SubtaskListNode(taskId: task.id, subtask: s, depth: 1),
          ),
      ],
    );
  }
}

/// Recursive subtask row in the list view. Indents by [depth] and expands its
/// own children. Columns stay aligned via [TaskColumns].
class _SubtaskListNode extends StatefulWidget {
  final String taskId;
  final SubTask subtask;
  final int depth;

  const _SubtaskListNode({
    required this.taskId,
    required this.subtask,
    required this.depth,
  });

  @override
  State<_SubtaskListNode> createState() => _SubtaskListNodeState();
}

class _SubtaskListNodeState extends State<_SubtaskListNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final state = context.watch<WorkspaceBloc>().state;
    final sub = widget.subtask;
    final project = state.projectById(widget.taskId);
    final pid = state.allTasks
        .where((t) => t.id == widget.taskId)
        .firstOrNull
        ?.projectId;
    final projectMembers = state.membersFor(
      state.projectById(pid ?? '')?.memberIds ?? project?.memberIds ?? [],
    );
    final assignees = state.membersFor(sub.assigneeIds);
    final indent = 22.0 + widget.depth * 18.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TaskColumns.rowPadH,
            vertical: 7,
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: indent,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: sub.hasSubtasks
                            ? GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => _expanded = !_expanded),
                                child: AnimatedRotation(
                                  turns: _expanded ? 0 : -0.25,
                                  duration: const Duration(milliseconds: 150),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: muted,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.subdirectory_arrow_right_rounded,
                                size: 14,
                                color: muted,
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnchoredTap(
                      onTap: (pos) async {
                        final s = await pickStatus(context, pos, sub.status);
                        if (s != null && context.mounted) {
                          context.read<WorkspaceBloc>().add(
                            SubTaskStatusChanged(widget.taskId, sub.id, s),
                          );
                        }
                      },
                      child: StatusDot(status: sub.status, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        sub.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: sub.isDone ? muted : textColor,
                          decoration: sub.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: muted,
                        ),
                      ),
                    ),
                    if (sub.hasSubtasks) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${sub.doneCount}/${sub.total}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: TaskColumns.assignee,
                child: _AssigneeCell(
                  assignees: assignees,
                  onTap: () => showAssigneeSheet(
                    context,
                    title: 'Assign subtask',
                    members: projectMembers,
                    selected: sub.assigneeIds,
                    onChanged: (ids) => context.read<WorkspaceBloc>().add(
                      SubTaskAssigneesChanged(widget.taskId, sub.id, ids),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: TaskColumns.due,
                child: sub.dueDate == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Fmt.dueLabel(sub.dueDate!),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sub.isOverdue ? AppColors.error : muted,
                          ),
                        ),
                      ),
              ),
              SizedBox(
                width: TaskColumns.priority,
                child: sub.priority == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.flag_rounded,
                          size: 15,
                          color: sub.priority!.color,
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (_expanded && sub.hasSubtasks)
          ...sub.subtasks.map(
            (c) => _SubtaskListNode(
              taskId: widget.taskId,
              subtask: c,
              depth: widget.depth + 1,
            ),
          ),
      ],
    );
  }
}

// ─── Cells ────────────────────────────────────────────────────────────────────

class _AssigneeCell extends StatelessWidget {
  final List<dynamic> assignees; // List<TeamMember>
  final VoidCallback onTap;

  const _AssigneeCell({required this.assignees, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.centerLeft,
        child: assignees.isEmpty
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: muted, width: 1.2),
                ),
                child: Icon(Icons.add_rounded, size: 13, color: muted),
              )
            : AvatarStack(
                members: assignees.cast(),
                size: 24,
                max: 2,
                borderColor: bg,
              ),
      ),
    );
  }
}

class _DueCell extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _DueCell({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.centerLeft,
        child: task.dueDate == null
            ? Icon(Icons.event_outlined, size: 16, color: muted)
            : Text(
                Fmt.dueLabel(task.dueDate!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: task.isOverdue ? AppColors.error : muted,
                ),
              ),
      ),
    );
  }
}

// ─── Add task row ─────────────────────────────────────────────────────────────

class _AddTaskRow extends StatelessWidget {
  final String projectId;
  final String? sprintId;
  final TaskStatus status;

  const _AddTaskRow({
    required this.projectId,
    required this.sprintId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: () => showCreateTaskSheet(
        context,
        projectId: projectId,
        sprintId: sprintId,
        initialStatus: status,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TaskColumns.rowPadH,
          vertical: 10,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Icon(Icons.add_rounded, size: 17, color: muted),
            ),
            Text(
              'Add Task',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}
