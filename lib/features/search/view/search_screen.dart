import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/model/project.dart';
import 'package:smart_sprint/features/workspace/view/widgets/workspace_badge.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'package:smart_sprint/features/workspace/view/widgets/status_picker.dart';

/// Quick-search / command palette across the current organization. Read-only:
/// it filters existing bloc state and navigates — it never mutates data.
Future<void> openSearch(BuildContext context) async {
  context.push('/search');
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openTask(Task t) {
    context.pushReplacement('/t/${t.id}');
  }

  void _openWorkspace(Project p) {
    context.pushReplacement('/w/${p.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final q = _query.trim().toLowerCase();

    final workspaces = q.isEmpty
        ? <Project>[]
        : state.projects
              .where((p) => p.name.toLowerCase().contains(q))
              .toList();
    final tasks = q.isEmpty
        ? <Task>[]
        : state.tasks
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.description.toLowerCase().contains(q),
              )
              .take(30)
              .toList();

    final hasResults = workspaces.isNotEmpty || tasks.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: muted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  onChanged: (v) => setState(() => _query = v),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                  decoration: InputDecoration(
                                    isCollapsed: true,
                                    border: InputBorder.none,
                                    hintText:
                                        'Search ${state.currentOrganization.name}…',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ),
                              if (_query.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: q.isEmpty
                      ? _Hint(muted: muted)
                      : !hasResults
                      ? _Empty(query: _query, muted: muted)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          children: [
                            if (workspaces.isNotEmpty) ...[
                              _GroupLabel('WORKSPACES', muted),
                              ...workspaces.map(
                                (p) => _WorkspaceResult(
                                  project: p,
                                  onTap: () => _openWorkspace(p),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (tasks.isNotEmpty) ...[
                              _GroupLabel('TASKS', muted),
                              ...tasks.map(
                                (t) => _TaskResult(
                                  task: t,
                                  onTap: () => _openTask(t),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  final Color muted;

  const _GroupLabel(this.text, this.muted);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: muted,
        ),
      ),
    );
  }
}

class _WorkspaceResult extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const _WorkspaceResult({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            WorkspaceBadge.project(project, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                project.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.north_east_rounded, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}

class _TaskResult extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskResult({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final state = context.watch<WorkspaceBloc>().state;
    final project = state.projectById(task.projectId);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            StatusDot(status: task.status, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (project != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: project.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          project.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: muted,
                          ),
                        ),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          Fmt.dueLabel(task.dueDate!),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: task.isOverdue ? AppColors.error : muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.north_east_rounded, size: 16, color: muted),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final Color muted;

  const _Hint({required this.muted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 40, color: muted),
          const SizedBox(height: 12),
          Text(
            'Search tasks and workspaces',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: muted),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String query;
  final Color muted;

  const _Empty({required this.query, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: muted),
          const SizedBox(height: 12),
          Text(
            'No results for "$query"',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: muted),
          ),
        ],
      ),
    );
  }
}
