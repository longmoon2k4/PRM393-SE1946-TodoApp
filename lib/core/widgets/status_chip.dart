import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class StatusChip extends StatelessWidget {
  final TaskStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (status) {
      case TaskStatus.todo:
        bgColor = AppColors.statusTodoBg;
        textColor = AppColors.statusTodo;
        label = 'To Do';
        icon = Icons.circle_outlined;
        break;
      case TaskStatus.inProgress:
        bgColor = AppColors.statusInProgressBg;
        textColor = AppColors.statusInProgress;
        label = 'In Progress';
        icon = Icons.timelapse;
        break;
      case TaskStatus.done:
        bgColor = AppColors.statusDoneBg;
        textColor = AppColors.statusDone;
        label = 'Done';
        icon = Icons.check_circle;
        break;
      case TaskStatus.cancelled:
        bgColor = AppColors.background;
        textColor = AppColors.statusCancelled;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSizes.br8,
        border: status == TaskStatus.cancelled ? Border.all(color: AppColors.divider) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: AppSizes.p4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              decoration: status == TaskStatus.cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
