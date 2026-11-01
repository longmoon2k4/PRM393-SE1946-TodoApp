import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/task_model.dart';

// Tập giá trị dùng trong phần lọc hạn và cách sắp xếp danh sách task.
enum TaskDueFilter { any, today, thisWeek, overdue }

enum TaskSortMode { manual, deadline, priority, newest }

// Giữ các điều kiện tìm/lọc/sắp xếp trong một state để Board cùng đọc.
class TaskFilterSortState {
  final String query;
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? tag;
  final TaskDueFilter dueFilter;
  final TaskSortMode sortMode;
  final String? projectId;
  final String? categoryId;

  const TaskFilterSortState({
    this.query = '',
    this.status,
    this.priority,
    this.tag,
    this.dueFilter = TaskDueFilter.any,
    this.sortMode = TaskSortMode.manual,
    this.projectId,
    this.categoryId,
  });

  // Dùng để hiện dấu hiệu trên nút lọc khi đang có điều kiện lọc.
  bool get hasFilters =>
      query.trim().isNotEmpty ||
      status != null ||
      priority != null ||
      tag != null ||
      dueFilter != TaskDueFilter.any ||
      projectId != null ||
      categoryId != null;

  // Các cờ clear* cho phép xóa riêng giá trị nullable như status hoặc tag.
  TaskFilterSortState copyWith({
    String? query,
    TaskStatus? status,
    bool clearStatus = false,
    TaskPriority? priority,
    bool clearPriority = false,
    String? tag,
    bool clearTag = false,
    TaskDueFilter? dueFilter,
    TaskSortMode? sortMode,
    String? projectId,
    bool clearProject = false,
    String? categoryId,
    bool clearCategory = false,
  }) {
    return TaskFilterSortState(
      query: query ?? this.query,
      status: clearStatus ? null : status ?? this.status,
      priority: clearPriority ? null : priority ?? this.priority,
      tag: clearTag ? null : tag ?? this.tag,
      dueFilter: dueFilter ?? this.dueFilter,
      sortMode: sortMode ?? this.sortMode,
      projectId: clearProject ? null : projectId ?? this.projectId,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    );
  }

  // Lọc task trước, sau đó sắp xếp kết quả theo chế độ người dùng chọn.
  List<TaskItem> filterTasks(List<TaskItem> tasks) {
    final search = query.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = tasks.where((task) {
      if (task.deletedAt != null) return false;
      if (search.isNotEmpty &&
          !task.title.toLowerCase().contains(search) &&
          !task.description.toLowerCase().contains(search)) {
        return false;
      }
      if (status != null && task.status != status) return false;
      if (priority != null && task.priority != priority) return false;
      if (tag != null &&
          !task.tags.any((item) => item.toLowerCase() == tag!.toLowerCase())) {
        return false;
      }
      if (projectId != null && task.projectId != projectId) return false;
      if (categoryId != null && task.categoryId != categoryId) return false;

      final deadline = task.deadline;
      switch (dueFilter) {
        case TaskDueFilter.any:
          break;
        case TaskDueFilter.today:
          if (deadline == null ||
              deadline.isBefore(today) ||
              !deadline.isBefore(today.add(const Duration(days: 1)))) {
            return false;
          }
          break;
        case TaskDueFilter.thisWeek:
          if (deadline == null ||
              deadline.isBefore(today) ||
              !deadline.isBefore(today.add(const Duration(days: 7)))) {
            return false;
          }
          break;
        case TaskDueFilter.overdue:
          if (!task.isOverdue) return false;
      }
      return true;
    }).toList();

    result.sort((a, b) {
      switch (sortMode) {
        case TaskSortMode.manual:
          final order = a.orderIndex.compareTo(b.orderIndex);
          return order != 0 ? order : a.createdAt.compareTo(b.createdAt);
        case TaskSortMode.deadline:
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        case TaskSortMode.priority:
          return _priorityRank(b.priority).compareTo(_priorityRank(a.priority));
        case TaskSortMode.newest:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return result;
  }

  int _priorityRank(TaskPriority value) {
    switch (value) {
      case TaskPriority.low:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.high:
        return 2;
      case TaskPriority.urgent:
        return 3;
    }
  }
}

// Notifier tạo state mới mỗi khi người dùng đổi một tiêu chí lọc.
final taskFilterSortProvider =
    NotifierProvider<TaskFilterSortNotifier, TaskFilterSortState>(
      TaskFilterSortNotifier.new,
    );

class TaskFilterSortNotifier extends Notifier<TaskFilterSortState> {
  @override
  TaskFilterSortState build() => const TaskFilterSortState();

  void setQuery(String value) => state = state.copyWith(query: value);

  void setStatus(TaskStatus? value) {
    state = state.copyWith(status: value, clearStatus: value == null);
  }

  void setPriority(TaskPriority? value) {
    state = state.copyWith(priority: value, clearPriority: value == null);
  }

  void setTag(String? value) {
    state = state.copyWith(tag: value, clearTag: value == null);
  }

  void setDueFilter(TaskDueFilter value) {
    state = state.copyWith(dueFilter: value);
  }

  void setSortMode(TaskSortMode value) {
    state = state.copyWith(sortMode: value);
  }

  void setProjectId(String? value) {
    state = state.copyWith(projectId: value, clearProject: value == null);
  }

  void setCategoryId(String? value) {
    state = state.copyWith(categoryId: value, clearCategory: value == null);
  }

  void clearFilters() => state = const TaskFilterSortState();
}

String taskStatusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return 'Chưa làm';
    case TaskStatus.inProgress:
      return 'Đang làm';
    case TaskStatus.done:
      return 'Hoàn thành';
    case TaskStatus.cancelled:
      return 'Đã hủy';
  }
}

String taskPriorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return 'Thấp';
    case TaskPriority.medium:
      return 'Trung bình';
    case TaskPriority.high:
      return 'Cao';
    case TaskPriority.urgent:
      return 'Khẩn cấp';
  }
}
