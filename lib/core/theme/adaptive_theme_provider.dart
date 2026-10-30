import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth_and_dashboard/providers/auth_provider.dart';
import '../models/task_model.dart';
import '../providers/core_tasks_provider.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import 'app_theme.dart';

enum AdaptiveMode {
  calm, // Dịu mát (Ít việc)
  focus, // Tập trung (Gần chạm ngưỡng hoặc có việc gấp)
  overload, // Quá tải (Vượt ngưỡng công việc quy định)
}

/// Quản lý chế độ Sáng / Tối (Dark Mode) cho toàn ứng dụng
final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return LocalStorageService.getIsDarkMode() ?? false;
  }

  void toggleTheme() {
    state = !state;
    LocalStorageService.saveIsDarkMode(state);
  }

  void setTheme(bool isDark) {
    state = isDark;
    LocalStorageService.saveIsDarkMode(state);
  }
}

class AdaptiveState {
  final AdaptiveMode mode;
  final int activeTaskCount;
  final int overdueTaskCount;
  final int backlogThreshold;
  final bool isDark;
  final ThemeData theme;

  const AdaptiveState({
    required this.mode,
    required this.activeTaskCount,
    required this.overdueTaskCount,
    required this.backlogThreshold,
    required this.isDark,
    required this.theme,
  });

  double get loadPercentage => backlogThreshold == 0
      ? 0.0
      : (activeTaskCount / backlogThreshold).clamp(0.0, 2.0);

  String get modeName {
    switch (mode) {
      case AdaptiveMode.calm:
        return 'Calm';
      case AdaptiveMode.focus:
        return 'Focus';
      case AdaptiveMode.overload:
        return 'Overload';
    }
  }

  String get modeDescription {
    switch (mode) {
      case AdaptiveMode.calm:
        return 'Khối lượng công việc ổn định.';
      case AdaptiveMode.focus:
        return 'Số lượng công việc đang tăng, hãy tập trung vào các ưu tiên cao.';
      case AdaptiveMode.overload:
        return 'Cảnh báo: Khối lượng công việc vượt ngưỡng quy định.';
    }
  }
}

/// Provider cung cấp trạng thái chi tiết của Adaptive Engine
final adaptiveStateProvider = Provider<AdaptiveState>((ref) {
  final tasks = ref.watch(coreTasksProvider);
  final authState = ref.watch(authProvider);
  final isDark = ref.watch(themeModeProvider);

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

  if (activeCount > threshold) {
    mode = AdaptiveMode.overload;

    // Bắn thông báo cục bộ khi bị quá tải
    if (notifyOnOverload) {
      NotificationService.showOverloadAlert(
        taskCount: activeCount,
        threshold: threshold,
      );
    }
  } else if (activeCount >= (threshold * 0.6).round() || overdueCount > 0) {
    mode = AdaptiveMode.focus;
  } else {
    mode = AdaptiveMode.calm;
  }

  final theme = AppTheme.getAdaptiveTheme(mode: mode, isDark: isDark);

  return AdaptiveState(
    mode: mode,
    activeTaskCount: activeCount,
    overdueTaskCount: overdueCount,
    backlogThreshold: threshold,
    isDark: isDark,
    theme: theme,
  );
});

/// Provider trả về ThemeData chuẩn để MaterialApp.router tự động cập nhật
final adaptiveThemeProvider = Provider<ThemeData>((ref) {
  final state = ref.watch(adaptiveStateProvider);
  return state.theme;
});
