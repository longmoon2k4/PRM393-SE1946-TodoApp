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
  });
}
