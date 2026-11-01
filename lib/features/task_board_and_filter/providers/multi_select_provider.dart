import 'package:flutter_riverpod/flutter_riverpod.dart';

const int maxSelectedTasks = 5;

final multiSelectProvider = NotifierProvider<MultiSelectNotifier, Set<String>>(
  MultiSelectNotifier.new,
);

class MultiSelectNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

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

  void keepOnly(Set<String> taskIds) {
    final next = state.intersection(taskIds);
    if (next.length != state.length) state = next;
  }

  void clear() => state = <String>{};
}
