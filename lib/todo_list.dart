import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_sprint/cubit/tasks_cubit.dart';
import 'package:smart_sprint/model/task_model.dart';

class TodoList extends StatelessWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: BlocBuilder<TasksCubit, List<TaskModel>>(
        builder: (context, tasks) {
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(title: Text(task.name));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-todo');
        },
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
