import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';

enum FabContextType {
  board,
  multiSelect,
  taskDetail
}

class ContextualFab extends ConsumerWidget {
  final FabContextType contextType;
  final TaskItem? currentTask;
  final VoidCallback onPressed;

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
          backgroundColor: AppColors.priorityMedium,
          child: const Icon(IconsaxPlusLinear.add, color: Colors.white),
        );

      case FabContextType.multiSelect:
        return FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: AppColors.priorityHigh,
          icon: const Icon(IconsaxPlusLinear.task_square, color: Colors.white),
          label: const Text('Thao tác hàng loạt', style: TextStyle(color: Colors.white)),
        );

      case FabContextType.taskDetail:
        if (currentTask == null) return const SizedBox();

        String label;
        IconData icon;
        Color bgColor;

        switch (currentTask!.status) {
          case TaskStatus.todo:
            label = 'Bắt đầu làm';
            icon = IconsaxPlusLinear.play;
            bgColor = AppColors.statusInProgress;
            break;
          case TaskStatus.inProgress:
            label = 'Hoàn thành';
            icon = IconsaxPlusLinear.tick_circle;
            bgColor = AppColors.statusDone;
            break;
          case TaskStatus.done:
          case TaskStatus.cancelled:
            label = 'Khôi phục';
            icon = IconsaxPlusLinear.refresh;
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
