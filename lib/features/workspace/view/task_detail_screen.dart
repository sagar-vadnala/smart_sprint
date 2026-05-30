import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/core/utils/responsive.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/model/activity.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/subtask.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/view/widgets/assignee_sheet.dart';
import 'package:smart_sprint/features/workspace/view/widgets/inline_editable_text.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';
import 'package:smart_sprint/features/workspace/view/widgets/status_picker.dart';
import 'package:smart_sprint/features/workspace/view/widgets/task_actions_menu.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final task = state.allTasks.where((t) => t.id == taskId).firstOrNull;

    if (task == null) {
      return const Scaffold(body: Center(child: Text('Task not found')));
    }

    final project = state.projectById(task.projectId);
    final wide = context.useSideNav;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (project != null) ...[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: project.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(project.icon, color: project.color, size: 13),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  project.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [TaskActionsButton(task: task, popOnDelete: true)],
      ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _MainColumn(task: task)),
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    border: Border(
                      left: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: _ActivityPanel(task: task),
                ),
              ],
            )
          : ListView(
              children: [
                _MainColumn(task: task, scrollable: false),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                _ActivityPanel(task: task, scrollable: false),
              ],
            ),
    );
  }
}

// ─── Left / main column ───────────────────────────────────────────────────────

class _MainColumn extends StatelessWidget {
  final Task task;
  final bool scrollable;

  const _MainColumn({required this.task, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    // Capture the bloc once so inline-edit commits are safe during dispose.
    final bloc = context.read<WorkspaceBloc>();

    final children = <Widget>[
      // Editable title
      Padding(
        padding: const EdgeInsets.only(left: 0),
        child: InlineEditableText(
          value: task.title,
          hintText: 'Task title',
          style: inlineTitleStyle(context),
          maxLines: 3,
          onCommit: (v) => bloc.add(TaskTitleChanged(task.id, v)),
        ),
      ),
      const SizedBox(height: 16),

      // Fields
      _FieldRow(
        label: 'Status',
        icon: Icons.adjust_rounded,
        child: _StatusField(task: task),
      ),
      _FieldRow(
        label: 'Assignees',
        icon: Icons.person_outline_rounded,
        child: _AssigneesField(task: task),
      ),
      _FieldRow(
        label: 'Priority',
        icon: Icons.flag_outlined,
        child: _PriorityField(task: task),
      ),
      _FieldRow(
        label: 'Due date',
        icon: Icons.event_outlined,
        child: _DueField(task: task),
      ),

      const SizedBox(height: 18),
      Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
      const SizedBox(height: 14),

      // Description (inline editable)
      Text(
        'DESCRIPTION',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: muted,
        ),
      ),
      const SizedBox(height: 4),
      InlineEditableText(
        value: task.description,
        hintText: 'Add a description…',
        required: false,
        maxLines: 8,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.55,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
        onCommit: (v) => bloc.add(TaskDescriptionChanged(task.id, v)),
      ),

      const SizedBox(height: 22),

      // Subtasks
      _SubtasksBlock(task: task),
      const SizedBox(height: 24),
    ];

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    if (!scrollable) return content;
    return SingleChildScrollView(child: content);
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _FieldRow({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Icon(icon, size: 16, color: muted),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
  }
}

class _StatusField extends StatelessWidget {
  final Task task;

  const _StatusField({required this.task});

  @override
  Widget build(BuildContext context) {
    return AnchoredTap(
      onTap: (pos) async {
        final s = await pickStatus(context, pos, task.status);
        if (s != null && s != task.status && context.mounted) {
          context.read<WorkspaceBloc>().add(TaskStatusChanged(task.id, s));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: task.status.color,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.status.shortLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.expand_more_rounded,
              size: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneesField extends StatelessWidget {
  final Task task;

  const _AssigneesField({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final state = context.watch<WorkspaceBloc>().state;
    final project = state.projectById(task.projectId);
    final assignees = state.membersFor(task.assigneeIds);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final members = state.membersFor(project?.memberIds ?? []);
        showAssigneeSheet(
          context,
          members: members,
          selected: task.assigneeIds,
          onChanged: (ids) => context.read<WorkspaceBloc>().add(
            TaskAssigneesChanged(task.id, ids),
          ),
        );
      },
      child: assignees.isEmpty
          ? Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 18, color: muted),
                const SizedBox(width: 7),
                Text(
                  'Assign',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: muted,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                AvatarStack(
                  members: assignees,
                  size: 28,
                  max: 5,
                  borderColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                ),
                const SizedBox(width: 8),
                Text(
                  assignees.length == 1
                      ? (assignees.first.id == 'me'
                            ? 'You'
                            : assignees.first.firstName)
                      : '${assignees.length} people',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
    );
  }
}

class _PriorityField extends StatelessWidget {
  final Task task;

  const _PriorityField({required this.task});

  @override
  Widget build(BuildContext context) {
    return AnchoredTap(
      onTap: (pos) async {
        final p = await pickPriority(context, pos, task.priority);
        if (p != null && p != task.priority && context.mounted) {
          context.read<WorkspaceBloc>().add(TaskPriorityChanged(task.id, p));
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 16, color: task.priority.color),
          const SizedBox(width: 7),
          Text(
            task.priority.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: task.priority.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueField extends StatelessWidget {
  final Task task;

  const _DueField({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
      child: task.dueDate == null
          ? Row(
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 18, color: muted),
                const SizedBox(width: 7),
                Text(
                  'Set date',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: muted,
                  ),
                ),
              ],
            )
          : Text(
              Fmt.dueLabel(task.dueDate!),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: task.isOverdue ? AppColors.error : textColor,
              ),
            ),
    );
  }
}

// ─── Subtasks ─────────────────────────────────────────────────────────────────

class _SubtasksBlock extends StatelessWidget {
  final Task task;

  const _SubtasksBlock({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final total = task.subtaskTotal;
    final done = task.subtaskDoneCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SUBTASKS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: muted,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Text(
                '$done/$total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: done == total ? AppColors.success : muted,
                ),
              ),
            ],
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: done / total,
              backgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              minHeight: 5,
            ),
          ),
        ],
        const SizedBox(height: 6),
        ...task.subtasks.map(
          (s) => _SubtaskNode(taskId: task.id, subtask: s, depth: 0),
        ),
        const SizedBox(height: 6),
        _SubtaskAdder(taskId: task.id),
      ],
    );
  }
}

/// Recursive subtask row. Each node manages its own expand state and renders
/// its children (and a nested adder) at depth + 1.
class _SubtaskNode extends StatefulWidget {
  final String taskId;
  final SubTask subtask;
  final int depth;

  const _SubtaskNode({
    required this.taskId,
    required this.subtask,
    required this.depth,
  });

  @override
  State<_SubtaskNode> createState() => _SubtaskNodeState();
}

class _SubtaskNodeState extends State<_SubtaskNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface = isDark ? AppColors.darkBg : AppColors.lightBg;
    final state = context.watch<WorkspaceBloc>().state;
    final bloc = context.read<WorkspaceBloc>();
    final sub = widget.subtask;
    final project = state.projectById(
      widget.taskId == ''
          ? ''
          : (state.allTasks
                    .where((t) => t.id == widget.taskId)
                    .firstOrNull
                    ?.projectId ??
                ''),
    );
    final assignees = state.membersFor(sub.assigneeIds);

    void setPriority() => showPriorityPicker(
      context,
      current: sub.priority,
      onPick: (p) => bloc.add(SubTaskPriorityChanged(widget.taskId, sub.id, p)),
    );

    Future<void> setDue() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: sub.dueDate ?? now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365 * 2)),
      );
      if (picked != null) {
        bloc.add(SubTaskDueDateChanged(widget.taskId, sub.id, picked));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: widget.depth * 18.0, top: 3, bottom: 3),
          padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: sub.hasSubtasks
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _expanded = !_expanded),
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
                  AnchoredTap(
                    onTap: (pos) async {
                      final s = await pickStatus(context, pos, sub.status);
                      if (s != null) {
                        bloc.add(
                          SubTaskStatusChanged(widget.taskId, sub.id, s),
                        );
                      }
                    },
                    child: StatusDot(status: sub.status, size: 18),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: InlineEditableText(
                      value: sub.title,
                      hintText: 'Subtask',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: sub.isDone
                            ? muted
                            : (isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        decoration: sub.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: muted,
                      ),
                      onCommit: (v) => bloc.add(
                        SubTaskTitleChanged(widget.taskId, sub.id, v),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final members = state.membersFor(
                        project?.memberIds ?? [],
                      );
                      showAssigneeSheet(
                        context,
                        title: 'Assign subtask',
                        members: members,
                        selected: sub.assigneeIds,
                        onChanged: (ids) => bloc.add(
                          SubTaskAssigneesChanged(widget.taskId, sub.id, ids),
                        ),
                      );
                    },
                    child: assignees.isEmpty
                        ? Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: muted, width: 1.2),
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 13,
                              color: muted,
                            ),
                          )
                        : AvatarStack(
                            members: assignees,
                            size: 26,
                            max: 2,
                            borderColor: surface,
                          ),
                  ),
                  _SubtaskMenu(
                    onAddChild: () {
                      bloc.add(
                        SubTaskAdded(
                          widget.taskId,
                          'New subtask',
                          parentSubTaskId: sub.id,
                        ),
                      );
                      setState(() => _expanded = true);
                    },
                    onSetPriority: setPriority,
                    onSetDue: setDue,
                    onClearDue: sub.dueDate != null
                        ? () => bloc.add(
                            SubTaskDueDateChanged(widget.taskId, sub.id, null),
                          )
                        : null,
                    onDelete: () =>
                        bloc.add(SubTaskDeleted(widget.taskId, sub.id)),
                  ),
                ],
              ),
              // Optional metadata chips
              if (sub.priority != null || sub.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Row(
                    children: [
                      if (sub.priority != null)
                        GestureDetector(
                          onTap: setPriority,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  size: 13,
                                  color: sub.priority!.color,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  sub.priority!.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: sub.priority!.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (sub.dueDate != null)
                        GestureDetector(
                          onTap: setDue,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 13,
                                color: sub.isOverdue ? AppColors.error : muted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                Fmt.dueLabel(sub.dueDate!),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: sub.isOverdue
                                      ? AppColors.error
                                      : muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Nested children + nested adder
        if (_expanded && sub.hasSubtasks)
          ...sub.subtasks.map(
            (c) => _SubtaskNode(
              taskId: widget.taskId,
              subtask: c,
              depth: widget.depth + 1,
            ),
          ),
        if (_expanded && sub.hasSubtasks)
          Padding(
            padding: EdgeInsets.only(left: (widget.depth + 1) * 18.0 + 4),
            child: _SubtaskAdder(
              taskId: widget.taskId,
              parentSubTaskId: sub.id,
            ),
          ),
      ],
    );
  }
}

class _SubtaskMenu extends StatelessWidget {
  final VoidCallback onAddChild;
  final VoidCallback onSetPriority;
  final VoidCallback onSetDue;
  final VoidCallback? onClearDue;
  final VoidCallback onDelete;

  const _SubtaskMenu({
    required this.onAddChild,
    required this.onSetPriority,
    required this.onSetDue,
    required this.onClearDue,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: muted),
      padding: EdgeInsets.zero,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      onSelected: (v) {
        switch (v) {
          case 'add':
            onAddChild();
          case 'priority':
            onSetPriority();
          case 'due':
            onSetDue();
          case 'cleardue':
            onClearDue?.call();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        _item('add', Icons.add_rounded, 'Add subtask'),
        _item('priority', Icons.flag_outlined, 'Set priority'),
        _item('due', Icons.event_outlined, 'Set due date'),
        if (onClearDue != null)
          _item('cleardue', Icons.event_busy_rounded, 'Clear due date'),
        _item('delete', Icons.delete_outline_rounded, 'Delete', danger: true),
      ],
    );
  }

  PopupMenuItem<String> _item(
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger ? AppColors.error : null;
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskAdder extends StatefulWidget {
  final String taskId;
  final String? parentSubTaskId;

  const _SubtaskAdder({required this.taskId, this.parentSubTaskId});

  @override
  State<_SubtaskAdder> createState() => _SubtaskAdderState();
}

class _SubtaskAdderState extends State<_SubtaskAdder> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<WorkspaceBloc>().add(
      SubTaskAdded(
        widget.taskId,
        text,
        parentSubTaskId: widget.parentSubTaskId,
      ),
    );
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final fill = isDark ? AppColors.darkFill : AppColors.lightFill;

    return Row(
      children: [
        Icon(Icons.add_rounded, size: 18, color: muted),
        const SizedBox(width: 9),
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _add(),
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fill,
              hintText: 'Add a subtask',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: muted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _add,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Activity panel ───────────────────────────────────────────────────────────

class _ActivityPanel extends StatelessWidget {
  final Task task;
  final bool scrollable;

  const _ActivityPanel({required this.task, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final state = context.watch<WorkspaceBloc>().state;
    final items = state.allActivities
        .where((a) => a.taskId == task.id)
        .toList();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Text(
            'Activity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Live',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ],
      ),
    );

    final timeline = items.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text(
              'No activity yet.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted),
            ),
          )
        : Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _TimelineRow(activity: items[i], isLast: i == items.length - 1),
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        if (scrollable)
          Expanded(child: SingleChildScrollView(child: timeline))
        else
          timeline,
        _CommentBox(taskId: task.id),
      ],
    );

    return body;
  }
}

class _TimelineRow extends StatelessWidget {
  final Activity activity;
  final bool isLast;

  const _TimelineRow({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final state = context.watch<WorkspaceBloc>().state;
    final actor = state.memberById(activity.actorId);
    final isComment = activity.kind == ActivityKind.comment;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rail
            Column(
              children: [
                if (actor != null)
                  MemberAvatar(member: actor, size: 30)
                else
                  CircleAvatar(radius: 15, backgroundColor: muted),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 14 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.4,
                          color: muted,
                        ),
                        children: [
                          TextSpan(
                            text: actor?.id == 'me'
                                ? 'You '
                                : '${actor?.firstName ?? 'Someone'} ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          TextSpan(text: activity.text),
                          if (activity.taskTitle != null && !isComment)
                            TextSpan(
                              text: ' ${activity.taskTitle}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isComment && activity.body != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          activity.body!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            height: 1.45,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      Fmt.timeAgo(activity.timestamp),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBox extends StatefulWidget {
  final String taskId;

  const _CommentBox({required this.taskId});

  @override
  State<_CommentBox> createState() => _CommentBoxState();
}

class _CommentBoxState extends State<_CommentBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<WorkspaceBloc>().add(CommentAdded(widget.taskId, text));
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final fill = isDark ? AppColors.darkFill : AppColors.lightFill;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _send(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: textColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: fill,
                hintText: 'Write a comment…',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: muted,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
