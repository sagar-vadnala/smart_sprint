import 'enums.dart';

class Activity {
  final String id;
  final ActivityKind kind;
  final String actorId;
  final String text;
  final String? taskTitle;
  final String? projectId;
  final String? taskId;
  final String? body; // comment text, when kind == comment
  final DateTime timestamp;

  const Activity({
    required this.id,
    required this.kind,
    required this.actorId,
    required this.text,
    required this.taskTitle,
    required this.projectId,
    this.taskId,
    this.body,
    required this.timestamp,
  });
}
