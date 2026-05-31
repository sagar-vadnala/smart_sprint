import 'package:smart_sprint/features/workspace/data/json_mappers.dart';
import 'enums.dart';
import 'subtask.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String projectId;
  final String? sprintId;
  final TaskStatus status;
  final TaskPriority priority;
  final List<String> assigneeIds;
  final DateTime? dueDate;
  final DateTime createdAt;
  final List<SubTask> subtasks;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.projectId,
    required this.sprintId,
    required this.status,
    required this.priority,
    required this.assigneeIds,
    required this.dueDate,
    required this.createdAt,
    this.subtasks = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      projectId: json['projectId'] as String,
      sprintId: json['sprintId'] as String?,
      status: taskStatusFromName(json['status'] as String?),
      priority: taskPriorityFromName(json['priority'] as String?),
      assigneeIds:
          (json['assigneeIds'] as List?)?.map((e) => e as String).toList() ??
          [],
      dueDate: dateFromIso(json['dueDate'] as String?),
      createdAt: dateOrNow(json['createdAt'] as String?),
      subtasks:
          (json['subtasks'] as List?)
              ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get isDone => status == TaskStatus.done;

  bool get hasSubtasks => subtasks.isNotEmpty;

  int get subtaskDoneCount => subtasks.where((s) => s.isDone).length;

  int get subtaskTotal => subtasks.length;

  bool get isOverdue {
    if (dueDate == null || isDone) return false;
    final now = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  Task copyWith({
    String? title,
    String? description,
    String? projectId,
    String? sprintId,
    bool clearSprint = false,
    TaskStatus? status,
    TaskPriority? priority,
    List<String>? assigneeIds,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<SubTask>? subtasks,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      sprintId: clearSprint ? null : (sprintId ?? this.sprintId),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
