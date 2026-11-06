import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/task_api_service.dart';
import 'task_crud_provider.dart';

/// Tài khoản bình luận khi chạy debug mà chưa đăng nhập.
const debugCommentAuthor = UserModel(
  id: 'debug-user',
  name: 'Người dùng thử',
  email: 'debug-user@todoapp.local',
);

/// Người đang bình luận; `null` khi chưa đăng nhập ở bản release.
final commentAuthorProvider = Provider<UserModel?>((ref) {
  return ref.watch(currentUserProvider) ??
      (kDebugMode ? debugCommentAuthor : null);
});

/// Backend chỉ lưu bình luận của user có trong bảng `users`, mà id ở đó có thể
/// khác Firebase UID. Hàm này đồng bộ user rồi trả về id backend đang dùng.
typedef CommentAuthorSync = Future<String> Function(UserModel user);

final commentAuthorSyncProvider = Provider<CommentAuthorSync>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: TaskApiService.defaultBaseUrl,
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  return (user) async {
    final response = await dio.post(
      '/api/v1/users/sync',
      data: {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
      },
    );
    final id = (response.data as Map<String, dynamic>?)?['id'] as String?;
    if (id == null || id.isEmpty) {
      throw Exception('Backend không trả về id người dùng');
    }
    return id;
  };
});

/// Ghi nhớ id backend theo id trên máy của từng người bình luận.
class CommentAuthorIds extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void remember(String localId, String backendId) {
    if (state[localId] == backendId) return;
    state = {...state, localId: backendId};
  }
}

final commentAuthorIdsProvider =
    NotifierProvider<CommentAuthorIds, Map<String, String>>(
      CommentAuthorIds.new,
    );
