import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/adaptive_sheet.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_event.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/sprint.dart';
import 'member_avatar.dart';

// ─── Public entry points ──────────────────────────────────────────────────────

Future<void> showCreateMenu(BuildContext context) {
  final bloc = context.read<WorkspaceBloc>();
  return _open(context, bloc, const _CreateMenu());
}

/// Returns `true` once the sheet finishes its task (created / dismissed), or
/// `null` if the user backed out — the [showCreateMenu] flow uses this to
/// decide whether to close the menu underneath or reveal it again.
Future<bool?> showCreateTaskSheet(
  BuildContext context, {
  String? projectId,
  String? sprintId,
  TaskStatus? initialStatus,
  bool fromMenu = false,
}) {
  final bloc = context.read<WorkspaceBloc>();
  return _open(
    context,
    bloc,
    _CreateTaskSheet(
      initialProjectId: projectId,
      initialSprintId: sprintId,
      initialStatus: initialStatus,
      fromMenu: fromMenu,
    ),
  );
}

Future<bool?> showCreateSprintSheet(
  BuildContext context, {
  String? projectId,
  bool fromMenu = false,
}) {
  final bloc = context.read<WorkspaceBloc>();
  return _open(
    context,
    bloc,
    _CreateSprintSheet(initialProjectId: projectId, fromMenu: fromMenu),
  );
}

Future<bool?> showCreateProjectSheet(
  BuildContext context, {
  bool fromMenu = false,
}) {
  final bloc = context.read<WorkspaceBloc>();
  return _open(context, bloc, _CreateProjectSheet(fromMenu: fromMenu));
}

Future<bool?> _open(BuildContext context, WorkspaceBloc bloc, Widget child) {
  return showAdaptiveSheet<bool>(
    context: context,
    // Use the sheet's own context for MediaQuery — the captured outer context
    // can be stale/unmounted by the time the sheet rebuilds (e.g. when the
    // keyboard opens), which throws "Unexpected null value".
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      // The glass dialog frame already lifts itself above the keyboard, so we
      // only add the inset padding in bottom-sheet mode.
      child: useGlassDialog(sheetContext)
          ? child
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: child,
            ),
    ),
  );
}

/// A create-sheet entry point — all three share the `{bool fromMenu}` named
/// parameter, so the menu can open any of them through one helper.
typedef _SheetOpener = Future<bool?> Function(
  BuildContext context, {
  bool fromMenu,
});

/// Opens [open] from the create menu, keeping the menu mounted underneath so a
/// back press returns to it. When the sheet completes (created / dismissed via
/// X), the menu closes too.
Future<void> _openFromMenu(BuildContext context, _SheetOpener open) async {
  final done = await open(context, fromMenu: true);
  if (done == true && context.mounted) Navigator.of(context).pop(true);
}

// ─── Shared sheet chrome ──────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;

  /// When set, a back arrow is shown that returns to the previous sheet (the
  /// create menu) instead of dismissing the whole flow.
  final VoidCallback? onBack;

  const _SheetShell({
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: sheetSurfaceDecoration(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          Padding(
            padding: EdgeInsets.fromLTRB(onBack != null ? 10 : 22, 8, 22, 14),
            child: Row(
              children: [
                if (onBack != null)
                  GestureDetector(
                    onTap: onBack,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: textColor,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkFill : AppColors.lightFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: muted),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: child,
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: footer!,
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9, top: 2),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }
}

/// A muted, bordered informational note used inside the create sheets.
class _HintNote extends StatelessWidget {
  final String text;

  const _HintNote(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final fill = isDark ? AppColors.darkFill : AppColors.lightFill;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.brand),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Widget? leading;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accent : border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 7)],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? accent : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context, String hint) {
  return InputDecoration(hintText: hint);
}

Widget _primaryButton({
  required String label,
  required bool enabled,
  required VoidCallback onTap,
}) {
  return ElevatedButton(onPressed: enabled ? onTap : null, child: Text(label));
}

// ─── Create menu ──────────────────────────────────────────────────────────────

class _CreateMenu extends StatelessWidget {
  const _CreateMenu();

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Create',
      subtitle: 'What would you like to add?',
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.brand,
            title: 'New Task',
            subtitle: 'Add work and assign it to your team',
            onTap: () => _openFromMenu(context, showCreateTaskSheet),
          ),
          _MenuRow(
            icon: Icons.bolt_rounded,
            color: AppColors.accent,
            title: 'New Sprint',
            subtitle: 'Plan a time-boxed cycle of work',
            onTap: () => _openFromMenu(context, showCreateSprintSheet),
          ),
          _MenuRow(
            icon: Icons.folder_open_rounded,
            color: const Color(0xFF14B8A6),
            title: 'New Workspace',
            subtitle: 'Spin up a space for a new initiative',
            onTap: () => _openFromMenu(context, showCreateProjectSheet),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: muted),
          ],
        ),
      ),
    );
  }
}

// ─── Create task ──────────────────────────────────────────────────────────────

class _CreateTaskSheet extends StatefulWidget {
  final String? initialProjectId;
  final String? initialSprintId;
  final TaskStatus? initialStatus;
  final bool fromMenu;

  const _CreateTaskSheet({
    this.initialProjectId,
    this.initialSprintId,
    this.initialStatus,
    this.fromMenu = false,
  });

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late String _projectId;
  String? _sprintId;
  late TaskStatus _status;
  TaskPriority _priority = TaskPriority.normal;
  final Set<String> _assignees = {};
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final state = context.read<WorkspaceBloc>().state;
    final projects = state.projects;
    // May have no workspace yet — the bloc will auto-create a default one on
    // submit, so an empty id here is fine.
    _projectId =
        widget.initialProjectId ??
        (projects.isNotEmpty ? projects.first.id : '');
    _sprintId = widget.initialSprintId;
    _status = widget.initialStatus ?? TaskStatus.todo;
    _assignees.add(state.currentUserId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    context.read<WorkspaceBloc>().add(
      TaskCreated(
        title: title,
        description: _descController.text.trim(),
        projectId: _projectId,
        sprintId: _sprintId,
        status: _status,
        priority: _priority,
        assigneeIds: _assignees.toList(),
        dueDate: _dueDate,
      ),
    );
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(_toast(context, 'Task created'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkspaceBloc>().state;
    final project = state.projectById(_projectId);
    final sprints = project == null
        ? const <Sprint>[]
        : state.sprintsForProject(_projectId);
    // Fall back to the org's members when there's no workspace yet.
    final projectMembers = project != null
        ? state.membersFor(project.memberIds)
        : state.members;
    final hasWorkspace = state.projects.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    // Drop sprint selection if it no longer belongs to the chosen project.
    if (_sprintId != null && !sprints.any((s) => s.id == _sprintId)) {
      _sprintId = null;
    }

    return _SheetShell(
      title: 'New Task',
      subtitle: 'Capture work and assign an owner',
      onBack: widget.fromMenu ? () => Navigator.of(context).pop() : null,
      footer: _primaryButton(
        label: 'Create Task',
        enabled: true,
        onTap: _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            decoration: _fieldDecoration(context, 'Task title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
            decoration: _fieldDecoration(context, 'Description (optional)'),
          ),
          const SizedBox(height: 20),

          const _Label('WORKSPACE'),
          if (!hasWorkspace)
            const _HintNote(
              'No workspace yet — we\'ll create one called "My Tasks" for you.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.projects.map((p) {
                return _SelectChip(
                  label: p.name,
                  selected: p.id == _projectId,
                  accent: p.color,
                  leading: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => setState(() => _projectId = p.id),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          if (sprints.isNotEmpty) ...[
            const _Label('SPRINT'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SelectChip(
                  label: 'No sprint',
                  selected: _sprintId == null,
                  accent: AppColors.brand,
                  onTap: () => setState(() => _sprintId = null),
                ),
                ...sprints.map(
                  (s) => _SelectChip(
                    label: s.name,
                    selected: _sprintId == s.id,
                    accent: AppColors.brand,
                    onTap: () => setState(() => _sprintId = s.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          const _Label('STATUS'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskStatus.values.map((s) {
              return _SelectChip(
                label: s.label,
                selected: _status == s,
                accent: s.color,
                onTap: () => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const _Label('PRIORITY'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskPriority.values.map((p) {
              return _SelectChip(
                label: p.label,
                selected: _priority == p,
                accent: p.color,
                leading: Icon(Icons.flag_rounded, size: 13, color: p.color),
                onTap: () => setState(() => _priority = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Assignees — optional, always shown.
          const _Label('ASSIGNEES'),
          _AssigneePicker(
            members: projectMembers,
            selected: _assignees,
            onToggle: (id) => setState(() {
              if (_assignees.contains(id)) {
                _assignees.remove(id);
              } else {
                _assignees.add(id);
              }
            }),
          ),
          const SizedBox(height: 20),

          const _Label('DUE DATE'),
          _DateField(
            value: _dueDate,
            onTap: _pickDueDate,
            onClear: () => setState(() => _dueDate = null),
          ),
        ],
      ),
    );
  }
}

class _AssigneePicker extends StatelessWidget {
  final List<dynamic> members; // List<TeamMember>
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _AssigneePicker({
    required this.members,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: members.map<Widget>((m) {
        final isSel = selected.contains(m.id);
        return GestureDetector(
          onTap: () => onToggle(m.id),
          child: SizedBox(
            width: 54,
            child: Column(
              children: [
                Stack(
                  children: [
                    Opacity(
                      opacity: isSel ? 1 : 0.55,
                      child: MemberAvatar(member: m, size: 46),
                    ),
                    if (isSel)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                            border: Border.all(color: bg, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  m.id == 'me' ? 'You' : m.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final fill = isDark ? AppColors.darkFill : AppColors.lightFill;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 18, color: muted),
            const SizedBox(width: 10),
            Text(
              value == null ? 'Set due date' : Fmt.shortDate(value!),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: value == null ? muted : textColor,
              ),
            ),
            const Spacer(),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 18, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Create sprint ────────────────────────────────────────────────────────────

class _CreateSprintSheet extends StatefulWidget {
  final String? initialProjectId;
  final bool fromMenu;

  const _CreateSprintSheet({this.initialProjectId, this.fromMenu = false});

  @override
  State<_CreateSprintSheet> createState() => _CreateSprintSheetState();
}

class _CreateSprintSheetState extends State<_CreateSprintSheet> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();

  late String _projectId;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final state = context.read<WorkspaceBloc>().state;
    final projects = state.projects;
    // May have no workspace yet — the bloc auto-creates a default one on submit.
    _projectId =
        widget.initialProjectId ??
        (projects.isNotEmpty ? projects.first.id : '');
    _start = DateTime.now();
    _end = _start.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) {
          _end = _start.add(const Duration(days: 14));
        }
      } else {
        _end = picked.isBefore(_start) ? _start : picked;
      }
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<WorkspaceBloc>().add(
      SprintCreated(
        name: name,
        goal: _goalController.text.trim(),
        projectId: _projectId,
        startDate: _start,
        endDate: _end,
      ),
    );
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_toast(context, 'Sprint created'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkspaceBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return _SheetShell(
      title: 'New Sprint',
      subtitle: 'Plan a focused cycle of work',
      onBack: widget.fromMenu ? () => Navigator.of(context).pop() : null,
      footer: _primaryButton(
        label: 'Create Sprint',
        enabled: true,
        onTap: _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            decoration: _fieldDecoration(
              context,
              'Sprint name (e.g. Sprint 25)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalController,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
            decoration: _fieldDecoration(context, 'Sprint goal (optional)'),
          ),
          const SizedBox(height: 20),

          const _Label('WORKSPACE'),
          if (state.projects.isEmpty)
            const _HintNote(
              'No workspace yet — we\'ll create one called "My Tasks" for you.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.projects.map((p) {
                return _SelectChip(
                  label: p.name,
                  selected: p.id == _projectId,
                  accent: p.color,
                  leading: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => setState(() => _projectId = p.id),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          const _Label('DURATION'),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  value: _start,
                  onTap: () => _pickDate(isStart: true),
                  onClear: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  value: _end,
                  onTap: () => _pickDate(isStart: false),
                  onClear: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Create project ───────────────────────────────────────────────────────────

class _CreateProjectSheet extends StatefulWidget {
  final bool fromMenu;

  const _CreateProjectSheet({this.fromMenu = false});

  @override
  State<_CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<_CreateProjectSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  static const _palette = [
    Color(0xFF6C47FF),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
  ];

  static const _icons = [
    Icons.rocket_launch_rounded,
    Icons.phone_iphone_rounded,
    Icons.palette_rounded,
    Icons.dns_rounded,
    Icons.campaign_rounded,
    Icons.science_rounded,
  ];

  Color _color = _palette.first;
  IconData _icon = _icons.first;
  final Set<String> _members = {'me'};

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    context.read<WorkspaceBloc>().add(
      ProjectCreated(
        name: name,
        description: _descController.text.trim(),
        color: _color,
        icon: _icon,
        memberIds: _members.toList(),
      ),
    );
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_toast(context, 'Workspace created'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkspaceBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return _SheetShell(
      title: 'New Workspace',
      subtitle: 'Create a space for a new initiative',
      onBack: widget.fromMenu ? () => Navigator.of(context).pop() : null,
      footer: _primaryButton(
        label: 'Create Workspace',
        enabled: true,
        onTap: _submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: _color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: _fieldDecoration(context, 'Workspace name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: textColor),
            decoration: _fieldDecoration(context, 'Description (optional)'),
          ),
          const SizedBox(height: 20),

          const _Label('COLOR'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _palette.map((c) {
              final sel = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? c : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.45),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: sel
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const _Label('ICON'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _icons.map((ic) {
              final sel = ic == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = ic),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sel
                        ? _color.withValues(alpha: 0.13)
                        : (isDark ? AppColors.darkFill : AppColors.lightFill),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? _color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    ic,
                    size: 20,
                    color: sel
                        ? _color
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                  ),
                ),
              );
            }).toList(),
          ),
          // Team selection only applies to team workspaces.
          if (!state.isPersonal) ...[
            const SizedBox(height: 20),
            const _Label('TEAM'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: state.members.map<Widget>((m) {
                final isSel = _members.contains(m.id);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSel && m.id != 'me') {
                      _members.remove(m.id);
                    } else {
                      _members.add(m.id);
                    }
                  }),
                  child: SizedBox(
                    width: 54,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Opacity(
                              opacity: isSel ? 1 : 0.55,
                              child: MemberAvatar(member: m, size: 46),
                            ),
                            if (isSel)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.brand,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: bg, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          m.id == 'me' ? 'You' : m.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isSel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Shared toast ─────────────────────────────────────────────────────────────

SnackBar _toast(BuildContext context, String message) {
  return SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
    backgroundColor: AppColors.success,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  );
}
