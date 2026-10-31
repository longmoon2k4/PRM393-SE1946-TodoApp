import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

/// Dịch vụ kết nối RESTful API với Spring Boot Backend (Chuẩn Production).
/// Xử lý tự động Token Firebase, Timeout, và chuyển đổi mô hình dữ liệu.
class TaskApiService {
  TaskApiService._();

  static final TaskApiService instance = TaskApiService._();

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator ánh xạ localhost của máy host qua địa chỉ 10.0.2.2
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: defaultBaseUrl,
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Tự động đính kèm Firebase ID Token nếu người dùng đã xác thực
          try {
            final fbUser = FirebaseAuth.instance.currentUser;
            if (fbUser != null) {
              final token = await fbUser.getIdToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (e) {
            debugPrint('Lỗi lấy Firebase Token đính kèm: $e');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint('TaskApiService Error [${e.requestOptions.path}]: ${e.message}');
          return handler.next(e);
        },
      ),
    );

  /// Lấy toàn bộ danh sách Task từ MySQL thông qua Spring Boot API
  Future<List<TaskItem>> fetchTasks({
    String? status,
    String? priority,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get(
      '/api/v1/tasks',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data is List) {
      final list = response.data as List;
      return list
          .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
          .where((t) => t.deletedAt == null)
          .toList();
    }
    return [];
  }

  /// Lấy chi tiết một Task kèm Checklist và Bình luận
  Future<TaskItem?> getTask(String taskId) async {
    final response = await _dio.get('/api/v1/tasks/$taskId');
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return TaskItem.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  /// Tạo mới Task lên Backend Database
  Future<TaskItem> createTask(TaskItem task) async {
    final payload = task.toBackendJson();
    final response = await _dio.post('/api/v1/tasks', data: payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TaskItem.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Không thể tạo Task trên server: ${response.statusCode}');
  }

  /// Cập nhật thông tin toàn diện của Task
  Future<TaskItem> updateTask(TaskItem task) async {
    final payload = task.toBackendJson();
    final response = await _dio.put('/api/v1/tasks/${task.id}', data: payload);
    if (response.statusCode == 200) {
      return TaskItem.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Không thể cập nhật Task trên server: ${response.statusCode}');
  }

  /// Cập nhật trạng thái Task nhanh (khi tick chọn hoặc vuốt thẻ)
  Future<TaskItem> updateTaskStatus(String taskId, TaskStatus status) async {
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

    final response = await _dio.patch(
      '/api/v1/tasks/$taskId/status',
      data: {'status': statusStr},
    );

    if (response.statusCode == 200) {
      return TaskItem.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Không thể đổi trạng thái trên server: ${response.statusCode}');
  }

  /// Xóa mềm Task (Soft delete đưa vào thùng rác trên Database)
  Future<void> deleteTask(String taskId) async {
    final response = await _dio.delete('/api/v1/tasks/$taskId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Không thể xóa Task trên server: ${response.statusCode}');
    }
  }

  /// Kiểm tra trạng thái trực tuyến của Backend server
  Future<bool> isServerAvailable() async {
    try {
      final res = await _dio.get(
        '/api/v1/tasks',
        options: Options(
          sendTimeout: const Duration(milliseconds: 1500),
          receiveTimeout: const Duration(milliseconds: 1500),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Khởi tạo dữ liệu thực tế lên Database MySQL nếu Database đang trống
  Future<List<TaskItem>> seedInitialProductionDataIfEmpty() async {
    try {
      final currentTasks = await fetchTasks();
      if (currentTasks.length >= 3) {
        return currentTasks;
      }

      final now = DateTime.now();
      final initialTasks = [
        TaskItem(
          id: '',
          title: 'Triển khai kiến trúc Adaptive UI Engine',
          description: 'Xây dựng thuật toán tính tải công việc và chuyển đổi theme mượt mà.',
          status: TaskStatus.done,
          priority: TaskPriority.urgent,
          createdAt: now.subtract(const Duration(days: 3)),
          deadline: now.subtract(const Duration(days: 1)),
          tags: const ['Frontend', 'AdaptiveUI'],
        ),
        TaskItem(
          id: '',
          title: 'Tích hợp Firebase Auth & Google OAuth 2.0',
          description: 'Cấu hình bảo mật và đồng bộ người dùng với Spring Boot API.',
          status: TaskStatus.done,
          priority: TaskPriority.high,
          createdAt: now.subtract(const Duration(days: 2)),
          deadline: now.subtract(const Duration(hours: 12)),
          tags: const ['Security', 'OAuth2'],
        ),
        TaskItem(
          id: '',
          title: 'Tối ưu hóa Bảng Thống kê Analytics Dashboard',
          description: 'Thiết kế trực quan đạt chuẩn Enterprise SaaS, tích hợp fl_chart.',
          status: TaskStatus.done,
          priority: TaskPriority.high,
          createdAt: now.subtract(const Duration(days: 1)),
          deadline: now.add(const Duration(hours: 8)),
          tags: const ['UI/UX', 'Analytics'],
        ),
        TaskItem(
          id: '',
          title: 'Hoàn thiện hệ thống Thông báo Đẩy Local Notification',
          description: 'Cảnh báo tự động khi quá tải hoặc sắp đến hạn chót công việc.',
          status: TaskStatus.inProgress,
          priority: TaskPriority.urgent,
          createdAt: now,
          deadline: now.add(const Duration(hours: 18)), // Sắp đến hạn
          tags: const ['Notification', 'Service'],
        ),
        TaskItem(
          id: '',
          title: 'Kết nối Spring Boot REST API & MySQL Database',
          description: 'Chuyển đổi toàn diện dữ liệu thực tế và cơ chế bộ nhớ đệm ngoại tuyến.',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          createdAt: now,
          deadline: now.add(const Duration(days: 3)),
          tags: const ['Backend', 'Database'],
        ),
      ];

      for (final t in initialTasks) {
        await createTask(t);
      }

      return await fetchTasks();
    } catch (e) {
      debugPrint('Lỗi seed dữ liệu ban đầu lên server: $e');
      return [];
    }
  }
}
