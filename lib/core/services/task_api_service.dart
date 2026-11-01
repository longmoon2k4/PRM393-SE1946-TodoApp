import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';

class TaskApiService {
  TaskApiService._();

  static final TaskApiService instance = TaskApiService._();

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
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

  Future<TaskItem?> getTask(String taskId) async {
    final response = await _dio.get('/api/v1/tasks/$taskId');
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return TaskItem.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<TaskItem> createTask(TaskItem task) async {
    final payload = task.toBackendJson();
    final response = await _dio.post('/api/v1/tasks', data: payload);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TaskItem.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Không thể tạo Task trên server: ${response.statusCode}');
  }

  Future<TaskItem> updateTask(TaskItem task) async {
    final payload = task.toBackendJson();
    final response = await _dio.put('/api/v1/tasks/${task.id}', data: payload);
    if (response.statusCode == 200) {
      return TaskItem.fromJson(response.data as Map<String, dynamic>);
    }
    throw Exception('Không thể cập nhật Task trên server: ${response.statusCode}');
  }

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

  Future<void> deleteTask(String taskId) async {
    final response = await _dio.delete('/api/v1/tasks/$taskId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Không thể xóa Task trên server: ${response.statusCode}');
    }
  }

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
          title: 'Xây dựng kế hoạch phát triển sản phẩm Q4',
          description: 'Hoàn thiện tài liệu kiến trúc hệ thống và lộ trình triển khai chi tiết.',
          status: TaskStatus.done,
          priority: TaskPriority.urgent,
          createdAt: now.subtract(const Duration(days: 3)),
          deadline: now.subtract(const Duration(days: 1)),
          tags: const ['Planning', 'Product'],
        ),
        TaskItem(
          id: '',
          title: 'Đánh giá an toàn thông tin và bảo mật tài khoản',
          description: 'Kiểm tra cơ chế xác thực phân quyền và lưu trữ an toàn dữ liệu.',
          status: TaskStatus.done,
          priority: TaskPriority.high,
          createdAt: now.subtract(const Duration(days: 2)),
          deadline: now.subtract(const Duration(hours: 12)),
          tags: const ['Security', 'Audit'],
        ),
        TaskItem(
          id: '',
          title: 'Tối ưu hóa bảng theo dõi hiệu suất công việc',
          description: 'Trực quan hóa chỉ số tiến độ và biểu đồ phân tích xu hướng hoàn thành.',
          status: TaskStatus.done,
          priority: TaskPriority.high,
          createdAt: now.subtract(const Duration(days: 1)),
          deadline: now.add(const Duration(hours: 8)),
          tags: const ['Analytics', 'Dashboard'],
        ),
        TaskItem(
          id: '',
          title: 'Thiết lập thông báo nhắc việc và cảnh báo tiến độ',
          description: 'Tự động gửi thông báo khi phát sinh việc khẩn cấp hoặc sắp đến hạn.',
          status: TaskStatus.inProgress,
          priority: TaskPriority.urgent,
          createdAt: now,
          deadline: now.add(const Duration(hours: 18)),
          tags: const ['Notification', 'Workflow'],
        ),
        TaskItem(
          id: '',
          title: 'Đồng bộ cơ sở dữ liệu và tối ưu hiệu năng',
          description: 'Kiểm định tốc độ phản hồi máy chủ và nâng cấp cấu trúc lưu trữ đám mây.',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          createdAt: now,
          deadline: now.add(const Duration(days: 3)),
          tags: const ['Infrastructure', 'Performance'],
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
