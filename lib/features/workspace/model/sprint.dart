import 'enums.dart';

class Sprint {
  final String id;
  final String name;
  final String goal;
  final String projectId;
  final DateTime startDate;
  final DateTime endDate;
  final SprintStatus status;

  const Sprint({
    required this.id,
    required this.name,
    required this.goal,
    required this.projectId,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  int get totalDays => endDate.difference(startDate).inDays.clamp(1, 9999);

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    if (now.isBefore(startDate)) return totalDays;
    return endDate.difference(now).inDays;
  }

  double get timeProgress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return 1;
    final elapsed = now.difference(startDate).inMinutes;
    final total = endDate.difference(startDate).inMinutes;
    if (total <= 0) return 1;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Sprint copyWith({
    String? name,
    String? goal,
    DateTime? startDate,
    DateTime? endDate,
    SprintStatus? status,
  }) {
    return Sprint(
      id: id,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      projectId: projectId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }
}
