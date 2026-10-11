import '../../../core/network/api_client.dart';

class TodoTask {
  const TodoTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.deadline,
  });

  final int id;
  final String title;
  final String status;
  final String priority;
  final DateTime? deadline;

  factory TodoTask.fromJson(Map<String, dynamic> json) => TodoTask(
    id: json['id'] as int,
    title: json['title'] as String,
    status: json['status'] as String,
    priority: json['priority'] as String,
    deadline: json['deadline'] == null
        ? null
        : DateTime.parse(json['deadline'] as String),
  );
}

class TaskRepository {
  const TaskRepository(this._client);

  final ApiClient _client;

  Future<List<TodoTask>> list() async {
    final json = await _client.get('/todo/tasks') as List<dynamic>;
    return json
        .map((item) => TodoTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
