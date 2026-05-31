import 'package:smart_sprint/features/workspace/data/json_mappers.dart';
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

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      kind: activityKindFromName(json['kind'] as String?),
      actorId: json['actorId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      taskTitle: json['taskTitle'] as String?,
      projectId: json['projectId'] as String?,
      taskId: json['taskId'] as String?,
      body: json['body'] as String?,
      timestamp: dateOrNow(json['timestamp'] as String?),
    );
  }
}
