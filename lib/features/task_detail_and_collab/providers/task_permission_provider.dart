import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/task_model.dart';
import '../../../core/models/user_model.dart';
import 'comment_author_provider.dart';
import 'task_crud_provider.dart';

class TeamMember {
  /// Firebase UID của thành viên, cũng là `users.id` khi đồng bộ lên backend.
  final String id;
  final String name;
  final String email;

  const TeamMember({required this.id, required this.name, required this.email});

  UserModel toUser() => UserModel(id: id, name: name, email: email);
}

/// Backend chưa trả về vai trò hay danh sách thành viên dự án, nên nhóm khai báo
/// leader và thành viên tại đây. Email so sánh không phân biệt hoa thường.
class TeamRoster {
  TeamRoster._();

  static const Set<String> leaderEmails = {
    'dangteo362004@gmail.com',
    'longmoon2004@gmail.com',
    'vuphuc2057@gmail.com',
  };

  /// Những người leader có thể giao việc, ngoài chính leader.
  ///
  /// Đây là thành viên ảo để thử giao việc trên mọi máy: khi được giao việc,
  /// họ được tự thêm vào bảng `users` của backend đang chạy. Khi có tài khoản
  /// thật, thay bằng Firebase UID, tên và email của từng người.
  static const List<TeamMember> members = [
    TeamMember(
      id: 'demo-member-1',
      name: 'Trần Minh Anh',
      email: 'minhanh.demo@todoapp.local',
    ),
    TeamMember(
      id: 'demo-member-2',
      name: 'Lê Quốc Bảo',
      email: 'quocbao.demo@todoapp.local',
    ),
    TeamMember(
      id: 'demo-member-3',
      name: 'Phạm Thu Hà',
      email: 'thuha.demo@todoapp.local',
    ),
    TeamMember(
      id: 'demo-member-4',
      name: 'Võ Gia Huy',
      email: 'giahuy.demo@todoapp.local',
    ),
  ];

  static bool isLeaderEmail(String email) =>
      leaderEmails.contains(email.trim().toLowerCase());

  /// [backendIds] ánh xạ id trên máy sang id backend, vì backend có thể lưu
  /// cùng một người dưới id khác.
  static TeamMember? findMember(
    String? id, {
    Map<String, String> backendIds = const {},
  }) {
    if (id == null) return null;
    return members
        .where((m) => m.id == id || backendIds[m.id] == id)
        .firstOrNull;
  }
}

class TaskPermissions {
  /// Sửa thông tin, giao việc, quản lý checklist, hủy hoặc xóa task.
  final bool canManage;

  /// Tick checklist của task.
  final bool canWork;

  /// Đẩy trạng thái tiến lên (Bắt đầu làm, Hoàn thành, Khôi phục). Chỉ người
  /// đang được giao việc làm điều này, kể cả leader.
  final bool canProgress;

  const TaskPermissions({
    required this.canManage,
    required this.canWork,
    required this.canProgress,
  });

  static const none = TaskPermissions(
    canManage: false,
    canWork: false,
    canProgress: false,
  );
}

/// Leader quản lý mọi task; thành viên chỉ làm task được giao cho mình.
/// [otherOwnIds] là các id khác của người dùng, ví dụ id phía backend.
TaskPermissions resolveTaskPermissions({
  required TaskItem task,
  required String? currentUserId,
  required bool isLeader,
  Set<String> otherOwnIds = const {},
}) {
  final assigneeId = task.assigneeId;
  final isAssignee =
      assigneeId != null &&
      (assigneeId == currentUserId || otherOwnIds.contains(assigneeId));
  return TaskPermissions(
    canManage: isLeader,
    canWork: isLeader || isAssignee,
    canProgress: isAssignee,
  );
}

bool isLeaderUser(UserModel? user) {
  // Chạy debug chưa đăng nhập vẫn có toàn quyền để thử màn hình.
  if (user == null) return kDebugMode;
  return TeamRoster.isLeaderEmail(user.email);
}

final isLeaderProvider = Provider<bool>((ref) {
  return isLeaderUser(ref.watch(currentUserProvider));
});

/// Mọi id mà người dùng hiện tại có thể mang: id trên máy và id backend.
final currentUserIdsProvider = Provider<Set<String>>((ref) {
  final user = ref.watch(commentAuthorProvider);
  if (user == null) return const {};
  return {user.id, ?ref.watch(commentAuthorIdsProvider)[user.id]};
});

final taskPermissionsProvider = Provider.family<TaskPermissions, String>((
  ref,
  taskId,
) {
  final task = ref.watch(taskByIdProvider(taskId));
  if (task == null) return TaskPermissions.none;
  return resolveTaskPermissions(
    task: task,
    currentUserId: ref.watch(currentUserProvider)?.id,
    isLeader: ref.watch(isLeaderProvider),
    otherOwnIds: ref.watch(currentUserIdsProvider),
  );
});
