import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/theme/theme_cubit.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/core/utils/responsive.dart';
import 'package:smart_sprint/core/widgets/surfaces.dart';
import 'package:smart_sprint/features/nav/cubit/nav_cubit.dart';
import 'package:smart_sprint/features/search/view/search_screen.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/sprint.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';
import 'package:smart_sprint/features/workspace/view/widgets/task_tile.dart';
import 'package:smart_sprint/features/workspace/view/widgets/organization_switcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final user = state.currentUser;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // Active sprint the user belongs to (first one found).
    final activeSprint = state.sprints
        .where((s) => s.status == SprintStatus.active)
        .where((s) {
          final p = state.projectById(s.projectId);
          return p != null && p.memberIds.contains(state.currentUserId);
        })
        .firstOrNull;

    final myOpen = state.myOpenTasks
      ..sort((a, b) {
        final ad = a.dueDate ?? DateTime(2100);
        final bd = b.dueDate ?? DateTime(2100);
        return ad.compareTo(bd);
      });
    final focusTasks = myOpen.take(4).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organization switcher + actions (mobile only — the side
                    // rail already carries these on wide screens).
                    if (!context.useSideNav) ...[
                      Row(
                        children: [
                          const OrganizationPill(),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: muted,
                            ),
                            onPressed: () => openSearch(context),
                          ),
                          IconButton(
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 21,
                              color: muted,
                            ),
                            onPressed: () =>
                                context.read<ThemeCubit>().toggle(),
                          ),
                          const SizedBox(width: 2),
                          GestureDetector(
                            onTap: () => _openProfile(context),
                            child: MemberAvatar(member: user, size: 36),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    // Greeting
                    Text(
                      '${Fmt.greeting()},',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      user.id == 'me' ? 'Welcome back' : user.firstName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stat cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '${state.myOpenTasks.length}',
                        label: 'Open tasks',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.brand,
                        onTap: () => context.read<NavCubit>().select(2),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _StatCard(
                        value: '${state.myDueTodayCount}',
                        label: 'Due today',
                        icon: Icons.today_rounded,
                        color: AppColors.accent,
                        onTap: () => context.read<NavCubit>().select(2),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _StatCard(
                        value: '${state.myOverdueCount}',
                        label: 'Overdue',
                        icon: Icons.error_outline_rounded,
                        color: AppColors.error,
                        onTap: () => context.read<NavCubit>().select(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Active sprint
            if (activeSprint != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: _ActiveSprintCard(sprint: activeSprint),
                ),
              ),

            // Focus section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                child: _SectionHeader(
                  title: 'Your focus',
                  actionLabel: myOpen.length > 4 ? 'View all' : null,
                  onAction: () => context.read<NavCubit>().select(2),
                ),
              ),
            ),

            // Focus tasks
            if (focusTasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _EmptyState(
                    icon: Icons.celebration_rounded,
                    title: 'All clear',
                    message: 'You have no open tasks. Time for a coffee.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: focusTasks.length,
                  itemBuilder: (_, i) => TaskTile(
                    task: focusTasks[i],
                    onTap: () => _openTask(context, focusTasks[i].id),
                  ),
                ),
              ),

            // Projects header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                child: _SectionHeader(
                  title: 'Workspaces',
                  actionLabel: 'View all',
                  onAction: () => context.read<NavCubit>().select(1),
                ),
              ),
            ),

            // Project cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList.builder(
                itemCount: state.projects.length,
                itemBuilder: (_, i) {
                  final p = state.projects[i];
                  return _ProjectCard(
                    name: p.name,
                    color: p.color,
                    icon: p.icon,
                    progress: state.projectProgress(p.id),
                    taskCount: state.tasksForProject(p.id).length,
                    members: state.membersFor(p.memberIds),
                    onTap: () => _openProject(context, p.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProject(BuildContext context, String projectId) =>
      context.push('/w/$projectId');

  void _openTask(BuildContext context, String taskId) =>
      context.push('/t/$taskId');

  void _openProfile(BuildContext context) => context.push('/profile');
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      onTap: onTap,
      glow: color,
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active sprint card ───────────────────────────────────────────────────────

class _ActiveSprintCard extends StatelessWidget {
  final Sprint sprint;

  const _ActiveSprintCard({required this.sprint});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WorkspaceBloc>().state;
    final project = state.projectById(sprint.projectId);
    final tasks = state.tasksForSprint(sprint.id);
    final done = tasks.where((t) => t.isDone).length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C5CFF), AppColors.brand, Color(0xFF5535CC)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'ACTIVE SPRINT',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${sprint.daysRemaining} days left',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            sprint.name,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${project?.name ?? ''}  ·  ${sprint.goal}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$done of ${tasks.length} done',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Project card ─────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final double progress;
  final int taskCount;
  final List<dynamic> members;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.name,
    required this.color,
    required this.icon,
    required this.progress,
    required this.taskCount,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface = isDark ? AppColors.darkSurfaceHigh : AppColors.lightSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        radius: 16,
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$taskCount tasks',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!context.watch<WorkspaceBloc>().state.isPersonal)
                  AvatarStack(
                    members: members.cast(),
                    size: 26,
                    max: 3,
                    borderColor: surface,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared bits ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.brand),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: muted),
          ),
        ],
      ),
    );
  }
}
