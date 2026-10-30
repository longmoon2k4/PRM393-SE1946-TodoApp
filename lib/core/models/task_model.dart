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
  final double orderIndex; // Phục vụ tính năng kéo thả sắp xếp
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final DateTime? deletedAt; // Phục vụ tính năng Xóa mềm (Soft Delete) / Thùng rác
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
    this.orderIndex = 0.0,
    required this.createdAt,
    this.startDate,
    this.deadline,
    this.reminderAt,
    this.deletedAt,
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

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    double? orderIndex,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? deadline,
    DateTime? reminderAt,
    DateTime? deletedAt,
    String? categoryId,
    String? projectId,
    List<String>? tags,
    String? assigneeId,
    List<SubTask>? subtasks,
    List<TaskComment>? comments,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      reminderAt: reminderAt ?? this.reminderAt,
      deletedAt: deletedAt ?? this.deletedAt,
      categoryId: categoryId ?? this.categoryId,
      projectId: projectId ?? this.projectId,
      tags: tags ?? this.tags,
      assigneeId: assigneeId ?? this.assigneeId,
      subtasks: subtasks ?? this.subtasks,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'categoryId': categoryId,
      'projectId': projectId,
      'tags': tags,
      'assigneeId': assigneeId,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    TaskStatus parseStatus(String? val) {
      return TaskStatus.values.firstWhere(
        (e) => e.name == val,
        orElse: () => TaskStatus.todo,
      );
    }

    TaskPriority parsePriority(String? val) {
      return TaskPriority.values.firstWhere(
        (e) => e.name == val,
        orElse: () => TaskPriority.medium,
      );
    }

    return TaskItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      priority: parsePriority(json['priority'] as String?),
      orderIndex: (json['orderIndex'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      reminderAt: json['reminderAt'] != null
          ? DateTime.tryParse(json['reminderAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
      categoryId: json['categoryId'] as String?,
      projectId: json['projectId'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      assigneeId: json['assigneeId'] as String?,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => TaskComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
