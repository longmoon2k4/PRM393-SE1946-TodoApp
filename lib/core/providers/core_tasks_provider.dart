import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_repository.dart';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

/// Provider lưu trữ State của toàn bộ danh sách Task.
/// Mọi phân hệ (Board, Detail, Analytics) đều phải .watch() provider này 
/// để UI tự động cập nhật khi có bất kỳ thay đổi nào (Thêm/Sửa/Xóa).
final coreTasksProvider =
    NotifierProvider<CoreTasksNotifier, List<TaskItem>>(() {
  return CoreTasksNotifier();
});

class CoreTasksNotifier extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() {
    // 1. Nạp dữ liệu từ bộ nhớ đệm ngoại tuyến (Offline Local Storage) trước
    final cachedTasks = LocalStorageService.getCachedTasks();
    if (cachedTasks != null && cachedTasks.isNotEmpty) {
      // Quét thông báo deadline ngầm
      NotificationService.checkAndNotifyApproachingDeadlines(cachedTasks);
      return cachedTasks;
    }

    // 2. Nếu lần đầu mở app chưa có cache, nạp Mock Data và lưu ngay vào cache
    final defaultTasks = MockRepository.mockTasks;
    LocalStorageService.saveTasks(defaultTasks);
    NotificationService.checkAndNotifyApproachingDeadlines(defaultTasks);
    return defaultTasks;
  }

  /// Thêm một Task mới
  void addTask(TaskItem newTask) {
    state = [...state, newTask];
    LocalStorageService.saveTasks(state);
    NotificationService.checkAndNotifyApproachingDeadlines(state);
  }

  /// Cập nhật thông tin của một Task đã tồn tại (VD: Đổi tên, đổi trạng thái)
  void updateTask(TaskItem updatedTask) {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
    LocalStorageService.saveTasks(state);
  }

  /// Xóa mềm một Task (Chuyển vào thùng rác)
  void deleteTask(String taskId) {
    state = [
      for (final task in state)
        if (task.id == taskId)
          task.copyWith(deletedAt: DateTime.now())
        else
          task
    ];
    LocalStorageService.saveTasks(state);
  }

  /// Đặt lại dữ liệu mẫu (Reset to mock data)
  void resetToMock() {
    state = MockRepository.mockTasks;
    LocalStorageService.saveTasks(state);
  }
}
