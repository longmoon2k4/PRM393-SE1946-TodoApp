import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/core_tasks_provider.dart';

class TaskStatistics {
  final int totalTasks;
  final int todoCount;
  final int inProgressCount;
  final int doneCount;
  final int cancelledCount;
  final int overdueCount;
  final int dueSoonCount;

  final int urgentCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;

  final List<int> weeklyCompletedCounts;

  final List<TaskItem> topActionableTasks;

  const TaskStatistics({
    required this.totalTasks,
    required this.todoCount,
    required this.inProgressCount,
    required this.doneCount,
    required this.cancelledCount,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.urgentCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.weeklyCompletedCounts,
    required this.topActionableTasks,
  });

  double get completionRate =>
      totalTasks == 0 ? 0.0 : (doneCount / totalTasks).clamp(0.0, 1.0);

  int get productivityScore {
    if (totalTasks == 0) return 100;
    final baseScore = (completionRate * 100).round();
    final overduePenalty = overdueCount * 12;
    return (baseScore - overduePenalty).clamp(0, 100);
  }

  String get productivityLabel {
    if (productivityScore >= 85) return 'Năng suất Xuất sắc 🚀';
    if (productivityScore >= 70) return 'Tiến độ Ổn định 👍';
    if (productivityScore >= 50) return 'Cần tập trung ⚠️';
    return 'Cảnh báo quá tải 🚨';
  }

  String get productivityAdvice {
    if (overdueCount > 0) {
      return 'Có $overdueCount công việc quá hạn cần ưu tiên giải quyết ngay hôm nay.';
    }
    if (productivityScore >= 85) {
      return 'Tiến độ rất xuất sắc! Tỷ lệ hoàn thành công việc đang đạt mức tối ưu.';
    }
    if (inProgressCount > 4) {
      return 'Đang có nhiều việc thực hiện cùng lúc, nên tập trung hoàn tất dứt điểm.';
    }
    return 'Duy trì đều đặn phân bổ công việc để giữ điểm số năng suất cao.';
  }
}

final statisticsProvider = Provider<TaskStatistics>((ref) {
  final tasks = ref.watch(coreTasksProvider);

  final validTasks = tasks.where((t) => t.deletedAt == null).toList();

  int todo = 0;
  int inProgress = 0;
  int done = 0;
  int cancelled = 0;
  int overdue = 0;
  int dueSoon = 0;

  int urgent = 0;
  int high = 0;
  int medium = 0;
  int low = 0;

  final weeklyCompleted = List<int>.filled(7, 0);

  for (final task in validTasks) {
    switch (task.status) {
      case TaskStatus.todo:
        todo++;
        break;
      case TaskStatus.inProgress:
        inProgress++;
        break;
      case TaskStatus.done:
        done++;
        final weekday = task.createdAt.weekday;
        weeklyCompleted[(weekday - 1) % 7]++;
        break;
      case TaskStatus.cancelled:
        cancelled++;
        break;
    }

    if (task.isOverdue) overdue++;
    if (task.isDueSoon) dueSoon++;

    switch (task.priority) {
      case TaskPriority.urgent:
        urgent++;
        break;
      case TaskPriority.high:
        high++;
        break;
      case TaskPriority.medium:
        medium++;
        break;
      case TaskPriority.low:
        low++;
        break;
    }
  }

  final actionable = validTasks.where((t) =>
      t.status != TaskStatus.done &&
      t.status != TaskStatus.cancelled &&
      (t.isOverdue ||
          t.priority == TaskPriority.urgent ||
          t.priority == TaskPriority.high)).toList();

  actionable.sort((a, b) {
    if (a.isOverdue && !b.isOverdue) return -1;
    if (!a.isOverdue && b.isOverdue) return 1;
    return b.priority.index.compareTo(a.priority.index);
  });

  return TaskStatistics(
    totalTasks: validTasks.length,
    todoCount: todo,
    inProgressCount: inProgress,
    doneCount: done,
    cancelledCount: cancelled,
    overdueCount: overdue,
    dueSoonCount: dueSoon,
    urgentCount: urgent,
    highCount: high,
    mediumCount: medium,
    lowCount: low,
    weeklyCompletedCounts: weeklyCompleted,
    topActionableTasks: actionable.take(3).toList(),
  );
});
