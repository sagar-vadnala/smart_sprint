import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_sprint/model/task_model.dart';

class TasksCubit extends Cubit<List<TaskModel>> {
  TasksCubit() : super([]);

  void addTask(String title) {
    final task = TaskModel(name: title, createdAt: DateTime.now());

    emit([...state, task]);
  }

  @override
  void onChange(Change<List<TaskModel>> change) {
    // TODO: implement onChange
    super.onChange(change);
    print("TasksCubit state changed: ${change}");
  }
}
