import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// Chip hiển thị mức độ ưu tiên của Task (Low, Medium, High, Urgent)
class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    const Color textColor = Colors.white;
    final String label;

    switch (priority) {
      case TaskPriority.low:
        bgColor = AppColors.priorityLow;
        label = 'Low';
        break;
      case TaskPriority.medium:
        bgColor = AppColors.priorityMedium;
        label = 'Medium';
        break;
      case TaskPriority.high:
        bgColor = AppColors.priorityHigh;
        label = 'High';
        break;
      case TaskPriority.urgent:
        bgColor = AppColors.priorityUrgent;
        label = 'Urgent';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSizes.brMax, // Hình viên thuốc (Pill shape)
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
