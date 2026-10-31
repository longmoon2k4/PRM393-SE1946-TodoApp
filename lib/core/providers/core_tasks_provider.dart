import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/task_api_service.dart';

/// Provider lưu trữ State của toàn bộ danh sách Task.
/// Áp dụng mô hình Production-Ready Offline-First & Live Cloud Sync:
/// - Mở app: Nạp tức thời từ Local Cache để hiển thị 0-delay.
/// - Ngay sau đó: Tự động đồng bộ ngầm dữ liệu thực tế từ Spring Boot REST API & MySQL.
/// - Các thao tác (Thêm, Sửa, Đổi trạng thái, Xóa): Cập nhật giao diện tức thì (Optimistic UI)
///   và gửi lệnh lưu vĩnh viễn vào Database MySQL trên Server.
final coreTasksProvider =
    NotifierProvider<CoreTasksNotifier, List<TaskItem>>(() {
  return CoreTasksNotifier();
});

class CoreTasksNotifier extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() {
    // 1. Nạp tức thì từ bộ nhớ đệm ngoại tuyến (Offline Storage)
    final cachedTasks = LocalStorageService.getCachedTasks();

    // 2. Kích hoạt đồng bộ thời gian thực từ Spring Boot Backend
    Future.microtask(() => syncFromBackend());

    if (cachedTasks != null && cachedTasks.isNotEmpty) {
      unawaited(NotificationService.checkAndNotifyApproachingDeadlines(cachedTasks));
      return cachedTasks;
    }

    return const [];
  }

  /// Đồng bộ dữ liệu thực tế từ Backend Server & Database MySQL
  Future<bool> syncFromBackend() async {
    try {
      var serverTasks = await TaskApiService.instance.fetchTasks();

      // Nếu database trên server chưa có đủ dữ liệu, khởi tạo dữ liệu thực tế ban đầu
      if (serverTasks.isEmpty) {
        serverTasks = await TaskApiService.instance.seedInitialProductionDataIfEmpty();
      }

      if (serverTasks.isNotEmpty) {
        state = serverTasks;
        await LocalStorageService.saveTasks(serverTasks);
        await LocalStorageService.updateLastSyncTime();
        unawaited(NotificationService.checkAndNotifyApproachingDeadlines(serverTasks));
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('CoreTasksNotifier - Ngoại lệ đồng bộ Backend (Đang dùng Cache Offline): $e');
      // Nếu server không phản hồi, đảm bảo nạp dữ liệu từ cache nếu có
      final cached = LocalStorageService.getCachedTasks();
      if (cached != null && cached.isNotEmpty && state.isEmpty) {
        state = cached;
      }
      return false;
    }
  }

  /// Thêm một Task mới (Ghi vào MySQL và cập nhật UI)
  Future<void> addTask(TaskItem newTask) async {
    // 1. Cập nhật Optimistic UI
    state = [...state, newTask];
    await LocalStorageService.saveTasks(state);
    unawaited(NotificationService.checkAndNotifyApproachingDeadlines(state));

    // 2. Đồng bộ lên Server Backend
    try {
      final savedTask = await TaskApiService.instance.createTask(newTask);
      state = [
        for (final t in state)
          if (t.id == newTask.id || (t.title == newTask.title && t.id.isEmpty))
            savedTask
          else
            t
      ];
      await LocalStorageService.saveTasks(state);
    } catch (e) {
      debugPrint('Lỗi ghi Task lên server (đã lưu offline): $e');
    }
  }

  /// Cập nhật thông tin của một Task đã tồn tại
  Future<void> updateTask(TaskItem updatedTask) async {
    // 1. Cập nhật Optimistic UI
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
    await LocalStorageService.saveTasks(state);
    unawaited(NotificationService.checkAndNotifyApproachingDeadlines(state));

    // 2. Đồng bộ lên Server Backend
    try {
      await TaskApiService.instance.updateTask(updatedTask);
    } catch (e) {
      debugPrint('Lỗi cập nhật Task lên server (đã lưu offline): $e');
    }
  }

  /// Đổi nhanh trạng thái Task (khi tick checkbox hoặc vuốt thẻ)
  Future<void> toggleTaskStatus(String taskId) async {
    final index = state.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final currentTask = state[index];
    final nextStatus = currentTask.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;

    final updatedTask = currentTask.copyWith(status: nextStatus);

    // 1. Cập nhật Optimistic UI
    state = [
      for (final task in state)
        if (task.id == taskId) updatedTask else task
    ];
    await LocalStorageService.saveTasks(state);
    unawaited(NotificationService.checkAndNotifyApproachingDeadlines(state));

    // 2. Đồng bộ lên Server Backend
    try {
      await TaskApiService.instance.updateTaskStatus(taskId, nextStatus);
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái lên server (đã lưu offline): $e');
    }
  }

  /// Xóa mềm một Task (Chuyển vào thùng rác trên Database)
  Future<void> deleteTask(String taskId) async {
    state = [
      for (final task in state)
        if (task.id == taskId)
          task.copyWith(deletedAt: DateTime.now())
        else
          task
    ];
    await LocalStorageService.saveTasks(state);

    try {
      await TaskApiService.instance.deleteTask(taskId);
    } catch (e) {
      debugPrint('Lỗi xóa Task trên server: $e');
    }
  }

  /// Đặt lại và đồng bộ tươi dữ liệu từ Backend
  Future<bool> resetToMock() async {
    return await syncFromBackend();
  }
}
