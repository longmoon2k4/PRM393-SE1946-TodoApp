import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth_and_dashboard/providers/auth_provider.dart';
import '../models/task_model.dart';
import '../providers/core_tasks_provider.dart';
import '../services/notification_service.dart';
import 'app_theme.dart';

enum AdaptiveMode {
  calm, // Dịu mát (Ít việc)
  focus, // Tập trung (Gần chạm ngưỡng hoặc có việc gấp)
  overload, // Quá tải (Vượt ngưỡng công việc quy định)
}

class AdaptiveState {
  final AdaptiveMode mode;
  final int activeTaskCount;
  final int overdueTaskCount;
  final int backlogThreshold;
  final ThemeData theme;

  const AdaptiveState({
    required this.mode,
    required this.activeTaskCount,
    required this.overdueTaskCount,
    required this.backlogThreshold,
    required this.theme,
  });

  double get loadPercentage => backlogThreshold == 0
      ? 0.0
      : (activeTaskCount / backlogThreshold).clamp(0.0, 2.0);

  String get modeName {
    switch (mode) {
      case AdaptiveMode.calm:
        return 'Calm Mode';
      case AdaptiveMode.focus:
        return 'Focus Mode';
      case AdaptiveMode.overload:
        return 'Overload Mode';
    }
  }

  String get modeDescription {
    switch (mode) {
      case AdaptiveMode.calm:
        return 'Khối lượng công việc nhẹ nhàng. Tiếp tục duy trì phong độ!';
      case AdaptiveMode.focus:
        return 'Số lượng công việc đang tăng. Hãy tập trung giải quyết việc ưu tiên cao!';
      case AdaptiveMode.overload:
        return 'Cảnh báo quá tải! Bạn có quá nhiều việc chưa hoàn thành. Cần phân bổ lại ngay.';
    }
  }
}

/// Provider cung cấp trạng thái chi tiết của Adaptive Engine
final adaptiveStateProvider = Provider<AdaptiveState>((ref) {
  final tasks = ref.watch(coreTasksProvider);
  final authState = ref.watch(authProvider);

  final threshold = authState.user?.backlogThreshold ?? 10;
  final notifyOnOverload = authState.user?.notifyOnOverload ?? true;

  // Lọc các task đang hoạt động (chưa xóa mềm)
  final activeTasks = tasks.where((t) =>
      t.deletedAt == null &&
      (t.status == TaskStatus.todo ||
          t.status == TaskStatus.inProgress ||
          t.isOverdue));

  final activeCount = activeTasks.length;
  final overdueCount = tasks.where((t) => t.isOverdue && t.deletedAt == null).length;

  AdaptiveMode mode;
  ThemeData theme;

  if (activeCount > threshold) {
    mode = AdaptiveMode.overload;
    theme = AppTheme.overloadTheme;

    // Bắn thông báo cục bộ khi bị quá tải
    if (notifyOnOverload) {
      NotificationService.showOverloadAlert(
        taskCount: activeCount,
        threshold: threshold,
      );
    }
  } else if (activeCount >= (threshold * 0.6).round() || overdueCount > 0) {
    mode = AdaptiveMode.focus;
    theme = AppTheme.focusTheme;
  } else {
    mode = AdaptiveMode.calm;
    theme = AppTheme.calmTheme;
  }

  return AdaptiveState(
    mode: mode,
    activeTaskCount: activeCount,
    overdueTaskCount: overdueCount,
    backlogThreshold: threshold,
    theme: theme,
  );
});

/// Provider trả về ThemeData chuẩn để MaterialApp.router tự động cập nhật
final adaptiveThemeProvider = Provider<ThemeData>((ref) {
  final state = ref.watch(adaptiveStateProvider);
  return state.theme;
});
