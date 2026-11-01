import 'package:flutter_riverpod/flutter_riverpod.dart';

// Giới hạn thao tác hàng loạt để tránh chọn quá nhiều task cùng lúc.
const int maxSelectedTasks = 5;

final multiSelectProvider = NotifierProvider<MultiSelectNotifier, Set<String>>(
  MultiSelectNotifier.new,
);

class MultiSelectNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  // Thêm/bỏ ID khỏi tập đang chọn; trả false nếu đã chạm giới hạn chọn.
  bool toggle(String taskId) {
    if (state.contains(taskId)) {
      final next = Set<String>.from(state)..remove(taskId);
      state = next;
      return true;
    }
    if (state.length >= maxSelectedTasks) return false;

    state = {...state, taskId};
    return true;
  }

  // Bỏ lựa chọn của các task không còn xuất hiện sau khi lọc/đồng bộ.
  void keepOnly(Set<String> taskIds) {
    final next = state.intersection(taskIds);
    if (next.length != state.length) state = next;
  }

  void clear() => state = <String>{};
}
