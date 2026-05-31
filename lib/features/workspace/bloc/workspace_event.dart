import 'package:flutter/material.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/organization.dart';
import 'package:smart_sprint/features/workspace/model/team_member.dart';

sealed class WorkspaceEvent {}

class WorkspaceLoaded extends WorkspaceEvent {}

class OrganizationSwitched extends WorkspaceEvent {
  final String organizationId;

  OrganizationSwitched(this.organizationId);
}

/// Records that the user opened a workspace (Project) — drives "Quick access".
class WorkspaceOpened extends WorkspaceEvent {
  final String projectId;

  WorkspaceOpened(this.projectId);
}

/// Merge an org's refreshed member list into state (after an invite succeeds).
class OrgMembersUpdated extends WorkspaceEvent {
  final String organizationId;
  final List<TeamMember> members;

  OrgMembersUpdated(this.organizationId, this.members);
}

class OrganizationCreated extends WorkspaceEvent {
  final String name;
  final OrgType type;
  final Color color;
  final IconData icon;

  OrganizationCreated({
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
  });
}

class TaskCreated extends WorkspaceEvent {
  final String title;
  final String description;
  final String projectId;
  final String? sprintId;
  final TaskStatus status;
  final TaskPriority priority;
  final List<String> assigneeIds;
  final DateTime? dueDate;

  TaskCreated({
    required this.title,
    required this.description,
    required this.projectId,
    required this.sprintId,
    required this.status,
    required this.priority,
    required this.assigneeIds,
    required this.dueDate,
  });
}

class TaskStatusChanged extends WorkspaceEvent {
  final String taskId;
  final TaskStatus status;

  TaskStatusChanged(this.taskId, this.status);
}

class TaskTitleChanged extends WorkspaceEvent {
  final String taskId;
  final String title;

  TaskTitleChanged(this.taskId, this.title);
}

class TaskDescriptionChanged extends WorkspaceEvent {
  final String taskId;
  final String description;

  TaskDescriptionChanged(this.taskId, this.description);
}

class TaskAssigneesChanged extends WorkspaceEvent {
  final String taskId;
  final List<String> assigneeIds;

  TaskAssigneesChanged(this.taskId, this.assigneeIds);
}

class TaskPriorityChanged extends WorkspaceEvent {
  final String taskId;
  final TaskPriority priority;

  TaskPriorityChanged(this.taskId, this.priority);
}

class TaskDueDateChanged extends WorkspaceEvent {
  final String taskId;
  final DateTime? dueDate;

  TaskDueDateChanged(this.taskId, this.dueDate);
}

class CommentAdded extends WorkspaceEvent {
  final String taskId;
  final String text;

  CommentAdded(this.taskId, this.text);
}

class TaskToggledDone extends WorkspaceEvent {
  final String taskId;

  TaskToggledDone(this.taskId);
}

class TaskDeleted extends WorkspaceEvent {
  final String taskId;

  TaskDeleted(this.taskId);
}

class TaskMovedToProject extends WorkspaceEvent {
  final String taskId;
  final String newProjectId;

  TaskMovedToProject(this.taskId, this.newProjectId);
}

class TaskMovedToSprint extends WorkspaceEvent {
  final String taskId;
  final String? sprintId; // null = backlog (no sprint)

  TaskMovedToSprint(this.taskId, this.sprintId);
}

class TaskDuplicated extends WorkspaceEvent {
  final String taskId;

  TaskDuplicated(this.taskId);
}

class SubTaskAdded extends WorkspaceEvent {
  final String taskId;
  final String title;

  /// When set, nest the new subtask under this subtask; else add at top level.
  final String? parentSubTaskId;

  SubTaskAdded(this.taskId, this.title, {this.parentSubTaskId});
}

class SubTaskToggled extends WorkspaceEvent {
  final String taskId;
  final String subTaskId;

  SubTaskToggled(this.taskId, this.subTaskId);
}

class SubTaskStatusChanged extends WorkspaceEvent {
  final String taskId;
  final String subTaskId;
  final TaskStatus status;

  SubTaskStatusChanged(this.taskId, this.subTaskId, this.status);
}

class SubTaskAssigneesChanged extends WorkspaceEvent {
  final String taskId;
  final String subTaskId;
  final List<String> assigneeIds;

  SubTaskAssigneesChanged(this.taskId, this.subTaskId, this.assigneeIds);
}

class SubTaskTitleChanged extends WorkspaceEvent {
  final String taskId;
  final String subTaskId;
  final String title;

  SubTaskTitleChanged(this.taskId, this.subTaskId, this.title);
}

class SubTaskPriorityChanged extends WorkspaceEvent {
  final String taskId;
  final String subTaskId;
  final TaskPriority? priority;

  SubTaskPriorityChanged(this.taskId, this.subTaskId, this.priority);
}

class SubTaskDueDateChanged extends WorkspaceEvent {
  final String taskId;
  final String subTaskId;
  final DateTime? dueDate;

  SubTaskDueDateChanged(this.taskId, this.subTaskId, this.dueDate);
}

class SubTaskDeleted extends WorkspaceEvent {
  final String taskId;
  final String subTaskId;

  SubTaskDeleted(this.taskId, this.subTaskId);
}

class SprintCreated extends WorkspaceEvent {
  final String name;
  final String goal;
  final String projectId;
  final DateTime startDate;
  final DateTime endDate;

  SprintCreated({
    required this.name,
    required this.goal,
    required this.projectId,
    required this.startDate,
    required this.endDate,
  });
}

class ProjectCreated extends WorkspaceEvent {
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final List<String> memberIds;

  ProjectCreated({
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.memberIds,
  });
}
