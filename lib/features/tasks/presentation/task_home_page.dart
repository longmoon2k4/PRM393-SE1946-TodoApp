import 'package:flutter/material.dart';

import '../data/task_repository.dart';

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({
    super.key,
    required this.repository,
    required this.onLogout,
  });

  final TaskRepository repository;
  final VoidCallback onLogout;

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  late Future<List<TodoTask>> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = widget.repository.list();
  }

  void _reload() {
    setState(() => _tasks = widget.repository.list());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My tasks'),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<TodoTask>>(
          future: _tasks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('Unable to load tasks.'),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Try again'),
                  ),
                ],
              );
            }
            final tasks = snapshot.data ?? const <TodoTask>[];
            if (tasks.isEmpty) {
              return const Center(child: Text('No tasks yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconFor(task.status)),
                  title: Text(task.title),
                  subtitle: Text('${task.status} - ${task.priority}'),
                  trailing: task.deadline == null
                      ? null
                      : Text(_date(task.deadline!)),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _iconFor(String status) {
    return switch (status) {
      'DONE' => Icons.check_circle,
      'IN_PROGRESS' => Icons.pending,
      'CANCELLED' => Icons.cancel_outlined,
      _ => Icons.radio_button_unchecked,
    };
  }

  String _date(DateTime value) => '${value.day}/${value.month}/${value.year}';
}
