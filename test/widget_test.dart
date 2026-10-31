import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/models/task_model.dart';
import 'package:todo_app/core/models/user_model.dart';

void main() {
  group('UserModel and TaskItem Unit Tests', () {
    test('UserModel JSON serialization and copyWith test', () {
      const user = UserModel(
        id: 'u-1',
        name: 'Hà Vũ Long',
        email: 'long@gmail.com',
        avatarUrl: 'https://example.com/avatar.png',
        backlogThreshold: 12,
        notifyOnOverload: true,
        notifyOnDeadline: true,
      );

      final json = user.toJson();
      expect(json['id'], 'u-1');
      expect(json['backlogThreshold'], 12);

      final fromJson = UserModel.fromJson(json);
      expect(fromJson.name, 'Hà Vũ Long');
      expect(fromJson.backlogThreshold, 12);

      final updated = user.copyWith(backlogThreshold: 15);
      expect(updated.backlogThreshold, 15);
      expect(updated.name, 'Hà Vũ Long');
    });

    test('TaskItem deadline and overdue calculations', () {
      final pastTask = TaskItem(
        id: 't-past',
        title: 'Task quá hạn',
        status: TaskStatus.todo,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(pastTask.isOverdue, isTrue);

      final futureTask = TaskItem(
        id: 't-future',
        title: 'Task sắp tới hạn',
        status: TaskStatus.inProgress,
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(const Duration(hours: 4)),
      );

      expect(futureTask.isOverdue, isFalse);
      expect(futureTask.isDueSoon, isTrue);
    });

    test('TaskItem Spring Boot REST API serialization and deserialization', () {
      final task = TaskItem(
        id: '101',
        title: 'Hoàn thiện REST API',
        description: 'Tích hợp MySQL và Spring Boot',
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        createdAt: DateTime(2026, 10, 31, 10, 0),
        deadline: DateTime(2026, 10, 31, 23, 59),
        assigneeId: 'u-101',
        tags: const ['backend', 'spring'],
      );

      // Verify toBackendJson
      final backendJson = task.toBackendJson();
      expect(backendJson['status'], 'in_progress');
      expect(backendJson['priority'], 'urgent');
      expect(backendJson['title'], 'Hoàn thiện REST API');
      expect(backendJson['assigneeId'], 'u-101');

      // Verify fromJson with nested backend object format
      final serverPayload = {
        'id': 101,
        'title': 'Hoàn thiện REST API',
        'description': 'Tích hợp MySQL và Spring Boot',
        'status': 'in_progress',
        'priority': 'urgent',
        'createdAt': '2026-10-31T10:00:00',
        'dueDate': '2026-10-31T23:59:00',
        'assignee': {'id': 'u-101', 'name': 'Hà Vũ Long'},
        'tags': ['backend', 'spring'],
      };

      final parsed = TaskItem.fromJson(serverPayload);
      expect(parsed.id, '101');
      expect(parsed.status, TaskStatus.inProgress);
      expect(parsed.priority, TaskPriority.urgent);
      expect(parsed.assigneeId, 'u-101');
      expect(parsed.tags, contains('backend'));
    });
  });
}
