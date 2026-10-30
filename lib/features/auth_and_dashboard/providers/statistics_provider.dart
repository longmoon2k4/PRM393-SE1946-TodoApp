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

  // Priority Breakdown
  final int urgentCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;

  // Weekly Completed Counts (Thứ 2 -> Chủ Nhật)
  final List<int> weeklyCompletedCounts;

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
  });

  double get completionRate =>
      totalTasks == 0 ? 0.0 : (doneCount / totalTasks).clamp(0.0, 1.0);

  int get productivityScore {
    if (totalTasks == 0) return 100;
    final baseScore = (completionRate * 100).round();
    final overduePenalty = overdueCount * 10;
    return (baseScore - overduePenalty).clamp(0, 100);
  }
}

final statisticsProvider = Provider<TaskStatistics>((ref) {
  final tasks = ref.watch(coreTasksProvider);

  // Lọc chỉ lấy các task chưa bị xóa mềm
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
        // Thống kê ngày hoàn thành trong tuần
        final weekday = task.createdAt.weekday; // 1 = Monday, 7 = Sunday
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
  );
});
