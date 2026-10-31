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
  final double orderIndex;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final DateTime? deletedAt;
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

  Map<String, dynamic> toBackendJson() {
    String statusStr;
    switch (status) {
      case TaskStatus.todo:
        statusStr = 'todo';
        break;
      case TaskStatus.inProgress:
        statusStr = 'in_progress';
        break;
      case TaskStatus.done:
        statusStr = 'done';
        break;
      case TaskStatus.cancelled:
        statusStr = 'cancelled';
        break;
    }

    return {
      'title': title,
      'description': description,
      'status': statusStr,
      'priority': priority.name,
      'orderIndex': orderIndex,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      if (reminderAt != null) 'reminderAt': reminderAt!.toIso8601String(),
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (projectId != null) 'projectId': projectId,
      if (categoryId != null) 'categoryId': categoryId,
      'tags': tags,
    };
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    TaskStatus parseStatus(String? val) {
      if (val == null) return TaskStatus.todo;
      final cleaned = val.toLowerCase().replaceAll('_', '');
      if (cleaned == 'todo') return TaskStatus.todo;
      if (cleaned == 'inprogress') return TaskStatus.inProgress;
      if (cleaned == 'done') return TaskStatus.done;
      if (cleaned == 'cancelled' || cleaned == 'canceled') {
        return TaskStatus.cancelled;
      }
      return TaskStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == cleaned,
        orElse: () => TaskStatus.todo,
      );
    }

    TaskPriority parsePriority(String? val) {
      if (val == null) return TaskPriority.medium;
      final cleaned = val.toLowerCase();
      if (cleaned == 'low') return TaskPriority.low;
      if (cleaned == 'medium') return TaskPriority.medium;
      if (cleaned == 'high') return TaskPriority.high;
      if (cleaned == 'urgent') return TaskPriority.urgent;
      return TaskPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == cleaned,
        orElse: () => TaskPriority.medium,
      );
    }

    String? extractId(dynamic field) {
      if (field == null) return null;
      if (field is Map<String, dynamic>) {
        return field['id']?.toString();
      }
      return field.toString();
    }

    List<String> extractTags(dynamic tagsJson) {
      if (tagsJson is! List) return const [];
      return tagsJson
          .map((e) {
            if (e is Map<String, dynamic>) {
              return e['name']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final rawDeadline = json['deadline'] ?? json['dueDate'];
    final rawCreatedAt = json['createdAt'];
    final rawStartDate = json['startDate'];
    final rawReminderAt = json['reminderAt'];
    final rawDeletedAt = json['deletedAt'];

    return TaskItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: parseStatus(json['status']?.toString()),
      priority: parsePriority(json['priority']?.toString()),
      orderIndex: (json['orderIndex'] as num?)?.toDouble() ?? 0.0,
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now()
          : DateTime.now(),
      startDate: rawStartDate != null
          ? DateTime.tryParse(rawStartDate.toString())
          : null,
      deadline: rawDeadline != null
          ? DateTime.tryParse(rawDeadline.toString())
          : null,
      reminderAt: rawReminderAt != null
          ? DateTime.tryParse(rawReminderAt.toString())
          : null,
      deletedAt: rawDeletedAt != null
          ? DateTime.tryParse(rawDeletedAt.toString())
          : null,
      categoryId: extractId(json['category'] ?? json['categoryId']),
      projectId: extractId(json['project'] ?? json['projectId']),
      tags: extractTags(json['tags']),
      assigneeId: extractId(json['assignee'] ?? json['assigneeId']),
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
