import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../models/comment_model.dart';

class MockRepository {
  static final List<TaskItem> mockTasks = [
    TaskItem(
      id: 'task-1',
      title: 'Thiết kế Database MySQL',
      description: 'Hoàn thiện file DATABASE_DESIGN.md và script SQL.',
      status: TaskStatus.done,
      priority: TaskPriority.high,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      deadline: DateTime.now().subtract(const Duration(days: 1)),
      tags: const ['Backend', 'Database'],
      subtasks: const [
        SubTask(id: 'st-1', title: 'Vẽ ERD', isCompleted: true),
        SubTask(id: 'st-2', title: 'Viết mã SQL DDL', isCompleted: true),
      ],
      comments: [
        TaskComment(
          id: 'cmt-1',
          authorId: 'user-2',
          authorName: 'Hoàng Phúc',
          content: 'File ERD nhìn rất rõ ràng, tôi đã nắm được cấu trúc.',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    ),
    TaskItem(
      id: 'task-2',
      title: 'Khởi tạo Flutter Framework',
      description: 'Setup Riverpod, GoRouter và Firebase.',
      status: TaskStatus.inProgress,
      priority: TaskPriority.urgent,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      deadline: DateTime.now().add(const Duration(hours: 5)),
      tags: const ['Frontend', 'Flutter'],
      subtasks: const [
        SubTask(id: 'st-3', title: 'Thêm dependencies', isCompleted: true),
        SubTask(id: 'st-4', title: 'Cấu hình Firebase', isCompleted: true),
        SubTask(id: 'st-5', title: 'Chia thư mục Feature-First', isCompleted: false),
      ],
    ),
    TaskItem(
      id: 'task-3',
      title: 'Thiết kế giao diện Đăng nhập',
      description: 'Code UI cho nút Google Sign-In và GitHub.',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      createdAt: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 5)),
      tags: const ['UI/UX'],
    ),
    TaskItem(
      id: 'task-4',
      title: 'Viết báo cáo môn học (Bản nháp)',
      description: 'Nộp bản nháp lần 1 cho giáo viên hướng dẫn.',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      deadline: DateTime.now().subtract(const Duration(days: 2)),
      tags: const ['Document'],
    ),
    TaskItem(
      id: 'task-5',
      title: 'Fix lỗi Swipe Gesture',
      description: 'Khắc phục tình trạng vuốt bị giật lag trên máy Android cũ.',
      status: TaskStatus.cancelled,
      priority: TaskPriority.low,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      tags: const ['Bug', 'UI/UX'],
    ),
  ];
}
