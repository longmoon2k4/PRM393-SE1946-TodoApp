import 'subtask_model.dart';
import 'comment_model.dart';

enum TaskStatus { todo, inProgress, done, cancelled }
enum TaskPriority { low, medium, high, urgent }

class TaskItem {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final String? categoryId;
  final String? projectId;
  final List<String> tags;
  final String? assigneeId;
  final List<SubTask> subtasks;
  final List<TaskComment> comments;

  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    required this.createdAt,
    this.startDate,
    this.deadline,
    this.reminderAt,
    this.categoryId,
    this.projectId,
    this.tags = const [],
    this.assigneeId,
    this.subtasks = const [],
    this.comments = const [],
  });

  bool get isOverdue =>
      deadline != null &&
      status != TaskStatus.done &&
      status != TaskStatus.cancelled &&
      deadline!.isBefore(DateTime.now());

  bool get isDueSoon =>
      deadline != null &&
      !isOverdue &&
      status != TaskStatus.done &&
      deadline!.difference(DateTime.now()).inHours <= 24;

  double get checklistProgress => subtasks.isEmpty
      ? 0.0
      : subtasks.where((s) => s.isCompleted).length / subtasks.length;
}
