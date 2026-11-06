import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/task_api_service.dart';

/// Tạo một dự án hoặc danh mục trên backend và trả về mục vừa tạo.
typedef CreateNamedOption = Future<NamedOption> Function(String name);

/// Màu mặc định cho danh mục mới, vì backend có cột màu nhưng app chưa cho chọn.
const defaultCategoryColorHex = '#4F6BED';

Dio _backendDio() => Dio(
  BaseOptions(
    baseUrl: TaskApiService.defaultBaseUrl,
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
    headers: {'Content-Type': 'application/json'},
  ),
);

CreateNamedOption _createAt(String path, Map<String, dynamic> extra) {
  final dio = _backendDio();
  return (name) async {
    final response = await dio.post(path, data: {'name': name, ...extra});
    final created = NamedOption.fromJson(response.data as Map<String, dynamic>);
    if (created.id.isEmpty) {
      throw Exception('Backend không trả về id của mục vừa tạo');
    }
    return created;
  };
}

final createProjectProvider = Provider<CreateNamedOption>((ref) {
  return _createAt('/api/v1/projects', const {});
});

final createCategoryProvider = Provider<CreateNamedOption>((ref) {
  return _createAt('/api/v1/categories', const {
    'colorHex': defaultCategoryColorHex,
  });
});
