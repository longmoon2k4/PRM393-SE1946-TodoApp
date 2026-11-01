import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/task_api_service.dart';
import '../../features/auth_and_dashboard/providers/auth_provider.dart';

final coreTasksProvider =
    NotifierProvider<CoreTasksNotifier, List<TaskItem>>(() {
  return CoreTasksNotifier();
});

class CoreTasksNotifier extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() {
    final cachedTasks = LocalStorageService.getCachedTasks();

    Future.microtask(() => syncFromBackend());

    if (cachedTasks != null && cachedTasks.isNotEmpty) {
      return cachedTasks;
    }

    return const [];
  }

  Future<bool> syncFromBackend() async {
    try {
      var serverTasks = await TaskApiService.instance.fetchTasks();

      if (serverTasks.isEmpty) {
        serverTasks = await TaskApiService.instance.seedInitialProductionDataIfEmpty();
      }

      if (serverTasks.isNotEmpty) {
        state = serverTasks;
        await LocalStorageService.saveTasks(serverTasks);
        await LocalStorageService.updateLastSyncTime();

        final auth = ref.read(authProvider);
        final notifyDeadline = auth.user?.notifyOnDeadline ?? true;
        unawaited(NotificationService.checkAndNotifyApproachingDeadlines(
          tasks: serverTasks,
          isEnabled: auth.status == AuthStatus.authenticated && notifyDeadline,
        ));
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('CoreTasksNotifier - Ngoại lệ đồng bộ Backend (Đang dùng Cache Offline): $e');
      final cached = LocalStorageService.getCachedTasks();
      if (cached != null && cached.isNotEmpty && state.isEmpty) {
        state = cached;
      }
      return false;
    }
  }

  Future<void> addTask(TaskItem newTask) async {
    state = [...state, newTask];
    await LocalStorageService.saveTasks(state);

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

  Future<void> updateTask(TaskItem updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task
    ];
    await LocalStorageService.saveTasks(state);

    try {
      await TaskApiService.instance.updateTask(updatedTask);
    } catch (e) {
      debugPrint('Lỗi cập nhật Task lên server (đã lưu offline): $e');
    }
  }

  Future<void> toggleTaskStatus(String taskId) async {
    final index = state.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final currentTask = state[index];
    final nextStatus = currentTask.status == TaskStatus.done
        ? TaskStatus.todo
        : TaskStatus.done;

    final updatedTask = currentTask.copyWith(status: nextStatus);

    state = [
      for (final task in state)
        if (task.id == taskId) updatedTask else task
    ];
    await LocalStorageService.saveTasks(state);

    try {
      await TaskApiService.instance.updateTaskStatus(taskId, nextStatus);
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái lên server (đã lưu offline): $e');
    }
  }

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
}
