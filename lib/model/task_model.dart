class TaskModel {
  final String name;
  final DateTime createdAt;

  TaskModel({required this.name, required this.createdAt});

  @override
  String toString() => 'TaskModel(name: $name, createdAt: $createdAt)';
}
