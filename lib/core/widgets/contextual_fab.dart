import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';

/// Nút hành động nổi biến thiên theo ngữ cảnh.
/// Tùy thuộc vào [contextType] mà nút sẽ hiển thị Icon/Text và hành động khác nhau.
enum FabContextType { 
  board,      // Đứng ở màn hình danh sách (Nút dấu +)
  multiSelect,// Khi đang chọn nhiều task (Thanh công cụ)
  taskDetail  // Đứng ở chi tiết Task (Trạng thái thay đổi)
}

class ContextualFab extends ConsumerWidget {
  final FabContextType contextType;
  final TaskItem? currentTask; // Chỉ truyền vào nếu đang ở màn hình TaskDetail
  final VoidCallback onPressed; // Hành động mặc định (vd: Mở BottomSheet khi ở board)

  const ContextualFab({
    super.key,
    required this.contextType,
    required this.onPressed,
    this.currentTask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (contextType) {
      case FabContextType.board:
        return FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: AppColors.priorityMedium, // Royal Blue
          child: const Icon(LucideIcons.plus, color: Colors.white),
        );

      case FabContextType.multiSelect:
        // Vẽ nút dạng thanh ngang (Extended) cho chế độ chọn nhiều
        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: AppColors.priorityHigh, // Amber (Cảnh báo nhẹ)
          icon: const Icon(LucideIcons.listChecks, color: Colors.white),
          label: const Text('Thao tác hàng loạt', style: TextStyle(color: Colors.white)),
        );

      case FabContextType.taskDetail:
        // Đảm bảo phải truyền currentTask nếu dùng type taskDetail
        if (currentTask == null) return const SizedBox();

        String label;
        IconData icon;
        Color bgColor;

        // Thay đổi giao diện dựa trên trạng thái của Task hiện tại
        switch (currentTask!.status) {
          case TaskStatus.todo:
            label = 'Bắt đầu làm';
            icon = LucideIcons.play;
            bgColor = AppColors.statusInProgress;
            break;
          case TaskStatus.inProgress:
            label = 'Hoàn thành';
            icon = LucideIcons.check;
            bgColor = AppColors.statusDone;
            break;
          case TaskStatus.done:
          case TaskStatus.cancelled:
            label = 'Khôi phục';
            icon = LucideIcons.rotateCcw;
            bgColor = AppColors.priorityLow;
            break;
        }

        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: bgColor,
          icon: Icon(icon, color: Colors.white),
          label: Text(label, style: const TextStyle(color: Colors.white)),
        );
    }
  }
}
