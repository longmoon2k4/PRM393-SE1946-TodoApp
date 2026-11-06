import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/comment_model.dart';
import '../../../core/models/subtask_model.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../../../core/services/task_api_service.dart';
import '../../auth_and_dashboard/providers/auth_provider.dart';
import 'comment_author_provider.dart';
import 'task_option_provider.dart';

/// Chỉ dùng khi chạy debug: xem màn hình như một thành viên khác mà không cần
/// đăng nhập tài khoản của họ. `null` là dùng tài khoản đang đăng nhập.
class DebugViewAs extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  void viewAs(UserModel? user) => state = user;
}

final debugViewAsProvider = NotifierProvider<DebugViewAs, UserModel?>(
  DebugViewAs.new,
);

final currentUserProvider = Provider<UserModel?>((ref) {
  if (kDebugMode) {
    final viewAs = ref.watch(debugViewAsProvider);
    if (viewAs != null) return viewAs;
  }
  return ref.watch(authProvider).user;
});

final taskByIdProvider = Provider.family<TaskItem?, String>((ref, taskId) {
  final tasks = ref.watch(coreTasksProvider);
  return tasks.where((t) => t.id == taskId && t.deletedAt == null).firstOrNull;
});

final projectOptionsProvider = FutureProvider<List<NamedOption>>((ref) {
  return TaskApiService.instance.fetchProjects();
});

final categoryOptionsProvider = FutureProvider<List<NamedOption>>((ref) {
  return TaskApiService.instance.fetchCategories();
});

final taskCrudProvider = Provider<TaskCrudController>((ref) {
  return TaskCrudController(ref);
});

class TaskCrudController {
  final Ref _ref;

  TaskCrudController(this._ref);

  static const String _localIdPrefix = 'local_';

  CoreTasksNotifier get _core => _ref.read(coreTasksProvider.notifier);

  TaskItem? _findTask(String taskId) {
    return _ref
        .read(coreTasksProvider)
        .where((t) => t.id == taskId)
        .firstOrNull;
  }

  String _newLocalId() =>
      '$_localIdPrefix${DateTime.now().microsecondsSinceEpoch}';

  bool _isLocalId(String id) => id.startsWith(_localIdPrefix);

  /// Trả về task đã lưu. Task giữ id `local_...` nếu server không phản hồi.
  Future<TaskItem> createTask({
    required String title,
    required TaskPriority priority,
    DateTime? deadline,
    DateTime? reminderAt,
    List<String> checklistTitles = const [],
  }) async {
    final draft = TaskItem(
      id: _newLocalId(),
      title: title,
      priority: priority,
      deadline: deadline,
      reminderAt: reminderAt,
      createdAt: DateTime.now(),
      subtasks: [
        for (var i = 0; i < checklistTitles.length; i++)
          SubTask(
            id: '${_newLocalId()}_$i',
            title: checklistTitles[i],
            orderIndex: i.toDouble(),
          ),
      ],
    );

    final saved = await _core.addTask(draft);
    if (_isLocalId(saved.id) || draft.subtasks.isEmpty) return saved;

    final createdSubtasks = <SubTask>[];
    for (final subtask in draft.subtasks) {
      try {
        createdSubtasks.add(
          await TaskApiService.instance.addSubtask(
            saved.id,
            title: subtask.title,
            orderIndex: subtask.orderIndex,
          ),
        );
      } catch (e) {
        debugPrint('Lỗi tạo mục con khi tạo Task: $e');
        createdSubtasks.add(subtask);
      }
    }

    final withSubtasks = saved.copyWith(subtasks: createdSubtasks);
    await _core.upsertLocalTask(withSubtasks);
    return withSubtasks;
  }

  Future<void> updateTask(TaskItem task) => _core.updateTask(task);

  Future<void> deleteTask(String taskId) => _core.deleteTask(taskId);

  Future<void> upsertLocalTask(TaskItem task) => _core.upsertLocalTask(task);

  /// Các hàm checklist trả về `false` khi thay đổi mới chỉ được lưu trên máy.
  Future<bool> addSubtask(String taskId, String title) async {
    final task = _findTask(taskId);
    if (task == null) return false;

    final maxOrder = task.subtasks.fold<double>(
      -1,
      (max, s) => s.orderIndex > max ? s.orderIndex : max,
    );
    final draft = SubTask(
      id: _newLocalId(),
      title: title,
      orderIndex: maxOrder + 1,
    );
    await _core.upsertLocalTask(
      task.copyWith(subtasks: [...task.subtasks, draft]),
    );

    try {
      final saved = await TaskApiService.instance.addSubtask(
        taskId,
        title: title,
        orderIndex: draft.orderIndex,
      );
      await _replaceSubtask(taskId, draft.id, saved);
      return true;
    } catch (e) {
      debugPrint('Lỗi thêm mục con lên server (đã lưu offline): $e');
      return false;
    }
  }

  Future<bool> toggleSubtask(String taskId, String subtaskId) async {
    final task = _findTask(taskId);
    if (task == null) return false;

    await _core.upsertLocalTask(
      task.copyWith(
        subtasks: [
          for (final s in task.subtasks)
            if (s.id == subtaskId)
              s.copyWith(isCompleted: !s.isCompleted)
            else
              s,
        ],
      ),
    );

    if (_isLocalId(subtaskId)) return false;
    try {
      final saved = await TaskApiService.instance.toggleSubtask(subtaskId);
      await _replaceSubtask(taskId, subtaskId, saved);
      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật mục con lên server (đã lưu offline): $e');
      return false;
    }
  }

  Future<bool> deleteSubtask(String taskId, String subtaskId) async {
    final task = _findTask(taskId);
    if (task == null) return false;

    await _core.upsertLocalTask(
      task.copyWith(
        subtasks: task.subtasks.where((s) => s.id != subtaskId).toList(),
      ),
    );

    if (_isLocalId(subtaskId)) return true;
    try {
      await TaskApiService.instance.deleteSubtask(subtaskId);
      return true;
    } catch (e) {
      debugPrint('Lỗi xóa mục con trên server (đã lưu offline): $e');
      return false;
    }
  }

  /// [ordered] là danh sách mục con theo thứ tự mới sau khi kéo thả.
  Future<bool> reorderSubtasks(String taskId, List<SubTask> ordered) async {
    final task = _findTask(taskId);
    if (task == null) return false;

    final oldOrder = {for (final s in task.subtasks) s.id: s.orderIndex};
    final renumbered = [
      for (var i = 0; i < ordered.length; i++)
        ordered[i].copyWith(orderIndex: i.toDouble()),
    ];
    await _core.upsertLocalTask(task.copyWith(subtasks: renumbered));

    final changed = renumbered.where(
      (s) => oldOrder[s.id] != s.orderIndex && !_isLocalId(s.id),
    );
    try {
      await Future.wait([
        for (final s in changed)
          TaskApiService.instance.updateSubtaskOrder(s.id, s.orderIndex),
      ]);
      return renumbered.every((s) => !_isLocalId(s.id));
    } catch (e) {
      debugPrint('Lỗi đổi thứ tự mục con trên server (đã lưu offline): $e');
      return false;
    }
  }

  /// Bình luận đang được gửi, để lần thử lại không gửi trùng.
  final Set<String> _sendingComments = {};

  /// Các id mà [author] có thể mang trên bình luận: id trên máy và id backend.
  Set<String> _authorIds(UserModel author) => {
    author.id,
    ?_ref.read(commentAuthorIdsProvider)[author.id],
  };

  /// Trả về `false` khi bình luận mới chỉ được lưu trên máy.
  Future<bool> addComment(
    String taskId, {
    required UserModel author,
    required String content,
  }) async {
    final task = _findTask(taskId);
    if (task == null) return false;

    final draft = TaskComment(
      id: _newLocalId(),
      authorId: _ref.read(commentAuthorIdsProvider)[author.id] ?? author.id,
      authorName: author.name,
      content: content,
      createdAt: DateTime.now(),
    );
    await _core.upsertLocalTask(
      task.copyWith(comments: [...task.comments, draft]),
    );

    if (_isLocalId(taskId)) return false;
    return _sendComment(taskId, draft, author);
  }

  Future<bool> _sendComment(
    String taskId,
    TaskComment draft,
    UserModel author,
  ) async {
    if (!_sendingComments.add(draft.id)) return false;

    try {
      final saved = await TaskApiService.instance.addComment(
        taskId,
        authorId: await _backendUserId(author),
        content: draft.content,
      );
      final latest = _findTask(taskId);
      if (latest != null) {
        await _core.upsertLocalTask(
          latest.copyWith(
            comments: [
              for (final c in latest.comments)
                if (c.id != draft.id && c.id != saved.id) c,
              saved,
            ],
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi gửi bình luận lên server (đã lưu offline): $e');
      return false;
    } finally {
      _sendingComments.remove(draft.id);
    }
  }

  /// Đồng bộ [user] với backend rồi trả về id backend đang dùng. Backend từ chối
  /// bình luận và bỏ qua việc giao cho user chưa có trong bảng `users`.
  Future<String> _backendUserId(UserModel user) async {
    final known = _ref.read(commentAuthorIdsProvider)[user.id];
    if (known != null) return known;

    try {
      final backendId = await _ref.read(commentAuthorSyncProvider)(user);
      _ref.read(commentAuthorIdsProvider.notifier).remember(user.id, backendId);
      return backendId;
    } catch (e) {
      debugPrint('Không đồng bộ được người dùng, dùng id hiện tại: $e');
      return user.id;
    }
  }

  /// Tạo dự án [name] rồi đưa [taskId] vào đó; `false` khi server không phản hồi.
  Future<bool> createProjectFor(String taskId, String name) => _createOptionFor(
    name,
    create: _ref.read(createProjectProvider),
    options: projectOptionsProvider,
    apply: (task, id) => task.copyWith(projectId: id),
    taskId: taskId,
  );

  /// Tạo danh mục [name] rồi gán cho [taskId]; `false` khi server không phản hồi.
  Future<bool> createCategoryFor(String taskId, String name) =>
      _createOptionFor(
        name,
        create: _ref.read(createCategoryProvider),
        options: categoryOptionsProvider,
        apply: (task, id) => task.copyWith(categoryId: id),
        taskId: taskId,
      );

  Future<bool> _createOptionFor(
    String name, {
    required CreateNamedOption create,
    required FutureProvider<List<NamedOption>> options,
    required TaskItem Function(TaskItem task, String id) apply,
    required String taskId,
  }) async {
    final NamedOption created;
    try {
      created = await create(name);
    } catch (e) {
      debugPrint('Lỗi tạo dự án/danh mục trên server: $e');
      return false;
    }
    _ref.invalidate(options);

    final task = _findTask(taskId);
    if (task != null) await _core.updateTask(apply(task, created.id));
    return true;
  }

  /// Giao [taskId] cho [assignee]. Trả về `false` khi mới chỉ lưu trên máy.
  Future<bool> assignTask(String taskId, UserModel assignee) async {
    final task = _findTask(taskId);
    if (task == null) return false;

    final updated = task.copyWith(assigneeId: await _backendUserId(assignee));
    await _core.upsertLocalTask(updated);
    if (_isLocalId(taskId)) return false;

    try {
      final saved = await TaskApiService.instance.updateTask(updated);
      // Backend bỏ qua người được giao không tồn tại thay vì báo lỗi.
      return saved.assigneeId == updated.assigneeId;
    } catch (e) {
      debugPrint('Lỗi giao việc lên server (đã lưu offline): $e');
      return false;
    }
  }

  /// Chỉ tải lại bình luận để không ghi đè các thay đổi checklist đang gửi.
  /// Khi có [author], gửi lại các bình luận của người đó còn nằm trên máy.
  Future<void> refreshComments(String taskId, {UserModel? author}) async {
    if (_isLocalId(taskId)) return;

    try {
      final fetched = await TaskApiService.instance.getTask(taskId);
      final latest = _findTask(taskId);
      if (fetched == null || latest == null) return;

      final merged = _mergeComments(fetched.comments, latest.comments);
      final hasChanged =
          merged.length != latest.comments.length ||
          !merged.every((c) => latest.comments.any((old) => old.id == c.id));
      if (hasChanged) {
        await _core.upsertLocalTask(latest.copyWith(comments: merged));
      }

      if (author != null) await _resendPendingComments(taskId, author);
    } catch (e) {
      debugPrint('Không tải lại được bình luận: $e');
    }
  }

  Future<void> _resendPendingComments(String taskId, UserModel author) async {
    final ids = _authorIds(author);
    final pending =
        (_findTask(taskId)?.comments ?? const <TaskComment>[])
            .where((c) => _isLocalId(c.id) && ids.contains(c.authorId))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final draft in pending) {
      if (!await _sendComment(taskId, draft, author)) return;
    }
  }

  /// Kéo để làm mới: lấy toàn bộ Task mới nhất từ server.
  Future<void> refreshTask(String taskId) async {
    if (_isLocalId(taskId)) return;

    try {
      final fetched = await TaskApiService.instance.getTask(taskId);
      final latest = _findTask(taskId);
      if (fetched == null || latest == null) return;

      await _core.upsertLocalTask(
        fetched.copyWith(
          comments: _mergeComments(fetched.comments, latest.comments),
        ),
      );
    } catch (e) {
      debugPrint('Không tải lại được Task: $e');
    }
  }

  List<TaskComment> _mergeComments(
    List<TaskComment> fromServer,
    List<TaskComment> local,
  ) {
    return [...fromServer, ...local.where((c) => _isLocalId(c.id))];
  }

  Future<void> _replaceSubtask(
    String taskId,
    String subtaskId,
    SubTask saved,
  ) async {
    final task = _findTask(taskId);
    if (task == null) return;

    await _core.upsertLocalTask(
      task.copyWith(
        subtasks: [
          for (final s in task.subtasks)
            if (s.id == subtaskId) saved else s,
        ],
      ),
    );
  }
}
