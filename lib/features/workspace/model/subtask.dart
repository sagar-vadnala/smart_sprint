import 'package:smart_sprint/features/workspace/data/json_mappers.dart';
import 'enums.dart';

/// A subtask behaves like a mini task: it has a status, can be assigned, and
/// can itself contain nested subtasks (arbitrary depth). Priority and due date
/// are optional.
class SubTask {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final List<String> assigneeIds;
  final TaskPriority? priority;
  final DateTime? dueDate;
  final List<SubTask> subtasks;

  const SubTask({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.assigneeIds = const [],
    this.priority,
    this.dueDate,
    this.subtasks = const [],
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: taskStatusFromName(json['status'] as String?),
      assigneeIds:
          (json['assigneeIds'] as List?)?.map((e) => e as String).toList() ??
          [],
      priority: taskPriorityFromNameOrNull(json['priority'] as String?),
      dueDate: dateFromIso(json['dueDate'] as String?),
      subtasks:
          (json['subtasks'] as List?)
              ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get isDone => status == TaskStatus.done;

  bool get hasSubtasks => subtasks.isNotEmpty;

  int get doneCount => subtasks.where((s) => s.isDone).length;

  int get total => subtasks.length;

  bool get isOverdue {
    if (dueDate == null || isDone) return false;
    final now = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }

  SubTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    List<String>? assigneeIds,
    TaskPriority? priority,
    bool clearPriority = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<SubTask>? subtasks,
  }) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      priority: clearPriority ? null : (priority ?? this.priority),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
