import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/view/widgets/workspace_badge.dart';
import 'package:smart_sprint/features/workspace/model/sprint.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/view/widgets/create_sheets.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';
import 'package:smart_sprint/features/workspace/view/widgets/task_actions_menu.dart';
import 'package:smart_sprint/features/workspace/view/widgets/task_list.dart';

enum _WorkspaceView { list, board }

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  /// Initial sprint filter from the URL. `null` = All sprints, `'backlog'` =
  /// Backlog (no sprint), otherwise a Sprint.id.
  final String? initialSprintId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.initialSprintId,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

/// Sentinel sprint filter id for the "Backlog" (tasks with no sprint).
const _kBacklog = 'backlog';

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  _WorkspaceView _view = _WorkspaceView.list;

  /// null = all sprints, [_kBacklog] = no sprint, otherwise a Sprint.id.
  String? _sprintFilter;

  String get projectId => widget.projectId;

  @override
  void didUpdateWidget(ProjectDetailScreen old) {
    super.didUpdateWidget(old);
    if (old.initialSprintId != widget.initialSprintId) {
      setState(() => _sprintFilter = widget.initialSprintId);
    }
  }

  @override
  void initState() {
    super.initState();
    _sprintFilter = widget.initialSprintId;
    // Record this workspace as recently opened (powers Quick access).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkspaceBloc>().add(WorkspaceOpened(projectId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final project = state.projectById(projectId);

    if (project == null) {
      return const Scaffold(body: Center(child: Text('Workspace not found')));
    }

    final allTasks = state.tasksForProject(projectId);
    final tasks = switch (_sprintFilter) {
      null => allTasks,
      _kBacklog => allTasks.where((t) => t.sprintId == null).toList(),
      final id => allTasks.where((t) => t.sprintId == id).toList(),
    };
    final sprints = state.sprintsForProject(projectId);
    final done = tasks.where((t) => t.isDone).length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
    final members = state.membersFor(project.memberIds);
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            WorkspaceBadge.project(project, size: 28),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                project.name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showCreateTaskSheet(
              context,
              projectId: projectId,
              sprintId: _sprintFilter == _kBacklog ? null : _sprintFilter,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (!state.isPersonal)
                        AvatarStack(
                          members: members,
                          size: 28,
                          max: 5,
                          borderColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                        ),
                      if (!state.isPersonal) const Spacer(),
                      Text(
                        '$done of ${tasks.length} done · ${(progress * 100).round()}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      valueColor: AlwaysStoppedAnimation(project.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sprint filter chips
          if (sprints.isNotEmpty)
            _SprintFilterRow(
              sprints: sprints,
              selected: _sprintFilter,
              onSelect: (v) => setState(() => _sprintFilter = v),
            ),

          // ── All sprints → sprint-grouped overview (sprint names as
          //   section headers, no List/Board toggle).
          //   Specific sprint → List/Board with that sprint's tasks. ──
          if (_sprintFilter == null && sprints.isNotEmpty)
            Expanded(
              child: _SprintsOverview(
                projectId: projectId,
                sprints: sprints,
                allTasks: allTasks,
                onSelectSprint: (id) => setState(() => _sprintFilter = id),
              ),
            )
          else ...[
            // View toggle (List / Board)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _ViewToggle(
                    view: _view,
                    onChanged: (v) => setState(() => _view = v),
                  ),
                  const Spacer(),
                  _AddTaskButton(
                    projectId: projectId,
                    sprintId: _sprintFilter == _kBacklog ? null : _sprintFilter,
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _view == _WorkspaceView.list
                  ? TaskListView(
                      tasks: tasks,
                      projectId: projectId,
                      sprintId: _sprintFilter == _kBacklog
                          ? null
                          : _sprintFilter,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final status in TaskStatus.values)
                          _StatusSection(
                            status: status,
                            tasks: state.tasksByStatus(tasks, status),
                            onAdd: () => showCreateTaskSheet(
                              context,
                              projectId: projectId,
                              sprintId: _sprintFilter == _kBacklog
                                  ? null
                                  : _sprintFilter,
                              initialStatus: status,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sprint-grouped overview rendered for the "All sprints" view: each sprint
/// (and Backlog) is its own section. Tapping the section header focuses that
/// sprint in the filter chips above.
class _SprintsOverview extends StatelessWidget {
  final String projectId;
  final List<Sprint> sprints;
  final List<Task> allTasks;
  final ValueChanged<String?> onSelectSprint;

  const _SprintsOverview({
    required this.projectId,
    required this.sprints,
    required this.allTasks,
    required this.onSelectSprint,
  });

  @override
  Widget build(BuildContext context) {
    final backlog = allTasks.where((t) => t.sprintId == null).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
      children: [
        for (final s in sprints)
          _SprintSection(
            sprint: s,
            tasks: allTasks.where((t) => t.sprintId == s.id).toList(),
            onAddTask: () => showCreateTaskSheet(
              context,
              projectId: projectId,
              sprintId: s.id,
            ),
            onFocus: () => onSelectSprint(s.id),
          ),
        _SprintSection(
          sprint: null,
          tasks: backlog,
          onAddTask: () => showCreateTaskSheet(context, projectId: projectId),
          onFocus: () => onSelectSprint(_kBacklog),
        ),
      ],
    );
  }
}

class _SprintSection extends StatefulWidget {
  /// `null` = Backlog section.
  final Sprint? sprint;
  final List<Task> tasks;
  final VoidCallback onAddTask;
  final VoidCallback onFocus;

  const _SprintSection({
    required this.sprint,
    required this.tasks,
    required this.onAddTask,
    required this.onFocus,
  });

  @override
  State<_SprintSection> createState() => _SprintSectionState();
}

class _SprintSectionState extends State<_SprintSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final isBacklog = widget.sprint == null;
    final accent = isBacklog ? muted : widget.sprint!.status.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: muted,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onFocus,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBacklog ? Icons.inbox_outlined : Icons.bolt_rounded,
                        size: 13,
                        color: accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isBacklog ? 'BACKLOG' : widget.sprint!.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.tasks.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onAddTask,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.add_rounded, size: 18, color: muted),
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          if (widget.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 16, 14),
              child: Text(
                'No tasks yet.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: muted,
                ),
              ),
            )
          else
            for (final t in widget.tasks) TaskListRow(task: t),
          // Quiet "Add task" affordance
          GestureDetector(
            onTap: widget.onAddTask,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Text(
                    'Add task',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        // Subtle separator
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              .withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

class _SprintFilterRow extends StatelessWidget {
  final List<Sprint> sprints;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _SprintFilterRow({
    required this.sprints,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.darkFill : AppColors.lightFill;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    Widget chip({
      required String label,
      required String? value,
      IconData? icon,
      Color? accent,
    }) {
      final isSelected = value == selected;
      final color = accent ?? AppColors.brand;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelect(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.13) : fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: isSelected ? color : muted),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        children: [
          chip(label: 'All sprints', value: null),
          chip(label: 'Backlog', value: _kBacklog, icon: Icons.inbox_outlined),
          for (final s in sprints)
            chip(
              label: s.name,
              value: s.id,
              icon: Icons.bolt_rounded,
              accent: s.status.color,
            ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final _WorkspaceView view;
  final ValueChanged<_WorkspaceView> onChanged;

  const _ViewToggle({required this.view, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.darkFill : AppColors.lightFill;

    Widget tab(_WorkspaceView v, IconData icon, String label) {
      final selected = v == view;
      final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
      final textColor = isDark ? AppColors.darkText : AppColors.lightText;
      final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: selected ? AppColors.brand : muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? textColor : muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          tab(_WorkspaceView.list, Icons.format_list_bulleted_rounded, 'List'),
          const SizedBox(width: 2),
          tab(_WorkspaceView.board, Icons.view_kanban_outlined, 'Board'),
        ],
      ),
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  final String projectId;
  final String? sprintId;

  const _AddTaskButton({required this.projectId, this.sprintId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showCreateTaskSheet(
        context,
        projectId: projectId,
        sprintId: sprintId,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 17),
            const SizedBox(width: 4),
            Text(
              'Task',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final TaskStatus status;
  final List<Task> tasks;
  final VoidCallback onAdd;

  const _StatusSection({
    required this.status,
    required this.tasks,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                status.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkFill : AppColors.lightFill,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${tasks.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAdd,
                behavior: HitTestBehavior.opaque,
                child: Icon(Icons.add_rounded, size: 20, color: muted),
              ),
            ],
          ),
        ),

        if (tasks.isEmpty)
          _EmptyRow(onAdd: onAdd)
        else
          ...tasks.map((t) => _BoardCard(task: t)),
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyRow({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 17, color: muted),
            const SizedBox(width: 5),
            Text(
              'Add task',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final Task task;

  const _BoardCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final assignees = state.membersFor(task.assigneeIds);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: () => context.push('/t/${task.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 13, color: task.priority.color),
                const SizedBox(width: 5),
                Text(
                  task.priority.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: task.priority.color,
                  ),
                ),
                const Spacer(),
                if (task.dueDate != null)
                  Text(
                    Fmt.dueLabel(task.dueDate!),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: task.isOverdue ? AppColors.error : muted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              task.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: textColor,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: muted,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!state.isPersonal)
                  AvatarStack(
                    members: assignees,
                    size: 24,
                    max: 3,
                    borderColor: surface,
                  ),
                if (task.hasSubtasks) ...[
                  if (!state.isPersonal) const SizedBox(width: 10),
                  Icon(Icons.checklist_rounded, size: 14, color: muted),
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
                const Spacer(),
                TaskActionsButton(task: task, compact: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
