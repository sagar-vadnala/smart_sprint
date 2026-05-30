import 'package:flutter/material.dart';
import 'package:smart_sprint/cubit/tasks_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddTodoPage extends StatefulWidget {
  const AddTodoPage({super.key});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final taskTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tasksCubit = context.read<TasksCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Add Todo')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: taskTitleController,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                tasksCubit.addTask(taskTitleController.text);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
