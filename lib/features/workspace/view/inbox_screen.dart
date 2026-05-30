import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/model/activity.dart';
import 'package:smart_sprint/features/workspace/view/widgets/member_avatar.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final activities = state.activities;
    final today = <Activity>[];
    final earlier = <Activity>[];
    final now = DateTime.now();
    for (final a in activities) {
      if (now.difference(a.timestamp).inHours < 24) {
        today.add(a);
      } else {
        earlier.add(a);
      }
    }

    // Tasks needing attention (overdue / due today, assigned to me).
    final attention = state.myOpenTasks
        .where((t) => t.isOverdue || t.isDueToday)
        .toList()
      ..sort((a, b) =>
          (a.dueDate ?? now).compareTo(b.dueDate ?? now));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Activity across your workspace',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Needs attention
            if (attention.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Text(
                    'NEEDS ATTENTION',
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: attention.take(3).map((t) {
                      final project = state.projectById(t.projectId);
                      return _AttentionCard(
                        title: t.title,
                        projectName: project?.name ?? '',
                        projectColor: project?.color ?? AppColors.brand,
                        isOverdue: t.isOverdue,
                        dueLabel:
                            t.dueDate != null ? Fmt.dueLabel(t.dueDate!) : '',
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            // Today
            if (today.isNotEmpty) ...[
              _sectionHeader('TODAY', muted),
              SliverList.builder(
                itemCount: today.length,
                itemBuilder: (_, i) =>
                    _ActivityRow(activity: today[i]),
              ),
            ],

            // Earlier
            if (earlier.isNotEmpty) ...[
              _sectionHeader('EARLIER', muted),
              SliverList.builder(
                itemCount: earlier.length,
                itemBuilder: (_, i) =>
                    _ActivityRow(activity: earlier[i]),
              ),
            ],

            if (activities.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 40, color: muted),
                      const SizedBox(height: 12),
                      Text(
                        'No activity yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(String label, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final String title;
  final String projectName;
  final Color projectColor;
  final bool isOverdue;
  final String dueLabel;

  const _AttentionCard({
    required this.title,
    required this.projectName,
    required this.projectColor,
    required this.isOverdue,
    required this.dueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final accent = isOverdue ? AppColors.error : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOverdue
                  ? Icons.error_outline_rounded
                  : Icons.schedule_rounded,
              color: accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: projectColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      projectName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dueLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Activity activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final actor = state.memberById(activity.actorId);
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with kind badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (actor != null)
                MemberAvatar(member: actor, size: 38)
              else
                CircleAvatar(radius: 19, backgroundColor: muted),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: activity.kind.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      width: 2,
                    ),
                  ),
                  child: Icon(activity.kind.icon,
                      size: 9, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
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
                      TextSpan(text: '${activity.text} '),
                      if (activity.taskTitle != null)
                        TextSpan(
                          text: activity.taskTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.timeAgo(activity.timestamp),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
