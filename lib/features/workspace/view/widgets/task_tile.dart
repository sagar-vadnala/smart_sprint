import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';
import 'package:smart_sprint/core/utils/formatting.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_bloc.dart';
import 'package:smart_sprint/features/workspace/bloc/workspace_state.dart';
import 'package:smart_sprint/features/workspace/model/task.dart';
import 'member_avatar.dart';
import 'status_picker.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final bool showProject;
  final VoidCallback? onTap;

  const TaskTile({
    super.key,
    required this.task,
    this.showProject = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<WorkspaceBloc>().state;
    final project = state.projectById(task.projectId);
    final assignees = state.membersFor(task.assigneeIds);
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status control — tap to pick a status (not just toggle done)
            Padding(
              padding: const EdgeInsets.only(top: 1, right: 11),
              child: StatusPickerButton(task: task, size: 20),
            ),

            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: task.isDone ? mutedColor : textColor,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 9),

                  // Meta row
                  Row(
                    children: [
                      // Priority
                      Icon(
                        Icons.flag_rounded,
                        size: 13,
                        color: task.priority.color,
                      ),
                      const SizedBox(width: 8),

                      // Project chip
                      if (showProject && project != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: project.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Due date
                      if (task.dueDate != null) ...[
                        Icon(
                          Icons.event_rounded,
                          size: 12,
                          color: task.isOverdue ? AppColors.error : mutedColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          Fmt.dueLabel(task.dueDate!),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: task.isOverdue
                                ? AppColors.error
                                : mutedColor,
                          ),
                        ),
                      ],

                      // Subtask progress
                      if (task.hasSubtasks) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.checklist_rounded,
                          size: 13,
                          color: mutedColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${task.subtaskDoneCount}/${task.subtaskTotal}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Assignees — only meaningful with a team.
            if (!state.isPersonal) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: AvatarStack(
                  members: assignees,
                  size: 24,
                  overlap: 8,
                  max: 3,
                  borderColor: surface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small status pill used in board headers and task detail.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

/// Convenience to read derived state with rebuilds.
extension WorkspaceContext on BuildContext {
  WorkspaceState get workspace => watch<WorkspaceBloc>().state;
}
