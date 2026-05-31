import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/view/widgets/create_sheets.dart';
import 'package:smart_sprint/features/workspace/view/widgets/invite_member_sheet.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';

class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workspaces',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${state.currentOrganization.name} · ${state.projects.length} workspaces',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showCreateProjectSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'New',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Team members strip (team orgs only) with an invite affordance.
            if (!state.isPersonal)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 4),
                  child: Row(
                    children: [
                      AvatarStack(
                        members: state.members,
                        size: 30,
                        max: 6,
                        borderColor: isDark
                            ? AppColors.darkBg
                            : AppColors.lightBg,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${state.members.length} ${state.members.length == 1 ? 'member' : 'members'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: muted,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => showInviteMemberSheet(
                          context,
                          state.currentOrganizationId,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 15,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Invite',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brand,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Active sprints strip
            if (state.sprints.any((s) => s.status == SprintStatus.active)) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
                  child: Text(
                    'ACTIVE SPRINTS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: muted,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 116,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: state.sprints
                        .where((s) => s.status == SprintStatus.active)
                        .map((s) {
                          final project = state.projectById(s.projectId);
                          final tasks = state.tasksForSprint(s.id);
                          final done = tasks.where((t) => t.isDone).length;
                          final progress = tasks.isEmpty
                              ? 0.0
                              : done / tasks.length;
                          return _SprintChip(
                            name: s.name,
                            projectName: project?.name ?? '',
                            color: project?.color ?? AppColors.brand,
                            daysLeft: s.daysRemaining,
                            progress: progress,
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
            ],

            // Projects list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 10),
                child: Text(
                  'ALL WORKSPACES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: muted,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList.builder(
                itemCount: state.projects.length,
                itemBuilder: (_, i) {
                  final p = state.projects[i];
                  final tasks = state.tasksForProject(p.id);
                  final done = tasks.where((t) => t.isDone).length;
                  return _ProjectListCard(
                    color: p.color,
                    icon: p.icon,
                    name: p.name,
                    description: p.description,
                    total: tasks.length,
                    done: done,
                    members: state.membersFor(p.memberIds),
                    onTap: () => context.push('/w/${p.id}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SprintChip extends StatelessWidget {
  final String name;
  final String projectName;
  final Color color;
  final int daysLeft;
  final double progress;

  const _SprintChip({
    required this.name,
    required this.projectName,
    required this.color,
    required this.daysLeft,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 15, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            projectName,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: muted),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${daysLeft}d left',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectListCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String name;
  final String description;
  final int total;
  final int done;
  final List<dynamic> members;
  final VoidCallback onTap;

  const _ProjectListCard({
    required this.color,
    required this.icon,
    required this.name,
    required this.description,
    required this.total,
    required this.done,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final progress = total == 0 ? 0.0 : done / total;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: muted, size: 22),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                if (!context.watch<WorkspaceBloc>().state.isPersonal)
                  AvatarStack(
                    members: members.cast(),
                    size: 26,
                    max: 4,
                    borderColor: surface,
                  ),
                const Spacer(),
                Text(
                  '$done/$total done',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
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
          ],
        ),
      ),
    );
  }
}
