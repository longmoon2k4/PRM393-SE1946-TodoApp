import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_repository.dart';
import '../models/task_model.dart';

/// Provider lưu trữ State của toàn bộ danh sách Task.
/// Mọi phân hệ (Board, Detail, Analytics) đều phải .watch() provider này 
/// để UI tự động cập nhật khi có bất kỳ thay đổi nào (Thêm/Sửa/Xóa).
final coreTasksProvider = NotifierProvider<CoreTasksNotifier, List<TaskItem>>(() {
  return CoreTasksNotifier();
});

class CoreTasksNotifier extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() {
    // Khi khởi tạo, nạp Dữ liệu giả (Mock Data) vào ngay lập tức
    return MockRepository.mockTasks;
  }

  /// Thêm một Task mới
  void addTask(TaskItem newTask) {
    state = [...state, newTask];
  }

  /// Cập nhật thông tin của một Task đã tồn tại (VD: Đổi tên, đổi trạng thái)
  void updateTask(TaskItem updatedTask) {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
  }

  /// Xóa mềm một Task (Chuyển vào thùng rác)
  void deleteTask(String taskId) {
    state = [
      for (final task in state)
        if (task.id == taskId)
          TaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            status: task.status,
            priority: task.priority,
            orderIndex: task.orderIndex,
            createdAt: task.createdAt,
            startDate: task.startDate,
            deadline: task.deadline,
            reminderAt: task.reminderAt,
            deletedAt: DateTime.now(), // <-- Đánh dấu đã xóa mềm
            categoryId: task.categoryId,
            projectId: task.projectId,
            tags: task.tags,
            assigneeId: task.assigneeId,
            subtasks: task.subtasks,
            comments: task.comments,
          )
        else
          task
    ];
  }
}
