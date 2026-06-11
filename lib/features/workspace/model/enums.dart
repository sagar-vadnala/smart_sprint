import 'package:flutter/material.dart';
import 'package:smart_sprint/core/theme/app_colors.dart';

enum TaskStatus {
  todo,
  inProgress,
  inReview,
  done;

  String get label => switch (this) {
    TaskStatus.todo => 'To Do',
    TaskStatus.inProgress => 'In Progress',
    TaskStatus.inReview => 'In Review',
    TaskStatus.done => 'Done',
  };

  String get shortLabel => switch (this) {
    TaskStatus.todo => 'TO DO',
    TaskStatus.inProgress => 'IN PROGRESS',
    TaskStatus.inReview => 'IN REVIEW',
    TaskStatus.done => 'DONE',
  };

  Color get color => switch (this) {
    TaskStatus.todo => const Color(0xFF94A3B8),
    TaskStatus.inProgress => const Color(0xFF3B82F6),
    TaskStatus.inReview => const Color(0xFFA855F7),
    TaskStatus.done => AppColors.success,
  };
}

enum TaskPriority {
  urgent,
  high,
  normal,
  low;

  String get label => switch (this) {
    TaskPriority.urgent => 'Urgent',
    TaskPriority.high => 'High',
    TaskPriority.normal => 'Normal',
    TaskPriority.low => 'Low',
  };

  Color get color => switch (this) {
    TaskPriority.urgent => const Color(0xFFEF4444),
    TaskPriority.high => const Color(0xFFF59E0B),
    TaskPriority.normal => const Color(0xFF3B82F6),
    TaskPriority.low => const Color(0xFF94A3B8),
  };

  IconData get icon => Icons.flag_rounded;
}

enum SprintStatus {
  planned,
  active,
  completed;

  String get label => switch (this) {
    SprintStatus.planned => 'Planned',
    SprintStatus.active => 'Active',
    SprintStatus.completed => 'Completed',
  };

  Color get color => switch (this) {
    SprintStatus.planned => const Color(0xFF94A3B8),
    SprintStatus.active => AppColors.brand,
    SprintStatus.completed => AppColors.success,
  };
}

/// The silhouette of a workspace/space icon badge. Stored alongside the glyph
/// in the workspace's icon string (see `workspaceIconKey`).
enum IconShape {
  roundedSquare,
  circle,
  square;

  String get label => switch (this) {
    IconShape.roundedSquare => 'Rounded',
    IconShape.circle => 'Circle',
    IconShape.square => 'Square',
  };

  BorderRadius radius(double size) => switch (this) {
    IconShape.roundedSquare => BorderRadius.circular(size * 0.30),
    IconShape.circle => BorderRadius.circular(size),
    IconShape.square => BorderRadius.circular(size * 0.12),
  };
}

enum ActivityKind {
  taskCreated,
  taskCompleted,
  taskAssigned,
  statusChanged,
  edited,
  sprintCreated,
  projectCreated,
  comment;

  IconData get icon => switch (this) {
    ActivityKind.taskCreated => Icons.add_task_rounded,
    ActivityKind.taskCompleted => Icons.check_circle_rounded,
    ActivityKind.taskAssigned => Icons.person_add_alt_rounded,
    ActivityKind.statusChanged => Icons.swap_horiz_rounded,
    ActivityKind.edited => Icons.edit_rounded,
    ActivityKind.sprintCreated => Icons.bolt_rounded,
    ActivityKind.projectCreated => Icons.folder_rounded,
    ActivityKind.comment => Icons.chat_bubble_rounded,
  };

  Color get color => switch (this) {
    ActivityKind.taskCreated => const Color(0xFF3B82F6),
    ActivityKind.taskCompleted => AppColors.success,
    ActivityKind.taskAssigned => AppColors.brand,
    ActivityKind.statusChanged => const Color(0xFFA855F7),
    ActivityKind.edited => const Color(0xFF8B8B94),
    ActivityKind.sprintCreated => AppColors.accent,
    ActivityKind.projectCreated => const Color(0xFF14B8A6),
    ActivityKind.comment => const Color(0xFF94A3B8),
  };
}
