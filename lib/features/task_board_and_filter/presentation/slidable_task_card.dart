import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/task_filter_sort_provider.dart';

class SlidableTaskCard extends StatelessWidget {
  final TaskItem task;
  final int reorderIndex;
  final bool selectionMode;
  final bool selected;
  final bool canReorder;
  final VoidCallback onToggleSelection;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onChoosePriority;
  final VoidCallback onReschedule;
  final VoidCallback onAssign;

  const SlidableTaskCard({
    required this.task,
    required this.reorderIndex,
    required this.selectionMode,
    required this.selected,
    required this.canReorder,
    required this.onToggleSelection,
    required this.onStatusChanged,
    required this.onChoosePriority,
    required this.onReschedule,
    required this.onAssign,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Chỉ hiện dấu chọn khi đang chọn nhiều; bình thường dành chỗ cho nội dung.
    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: selectionMode
            ? Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              )
            : null,
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.status == TaskStatus.done
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: _taskSubtitle(context),
        trailing: canReorder
            ? ReorderableDragStartListener(
                index: reorderIndex,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(IconsaxPlusLinear.menu_1),
                ),
              )
            : null,
        onTap: selectionMode
            ? onToggleSelection
            : () {
                if (task.id.isNotEmpty) {
                  context.push('/task-detail/${task.id}');
                }
              },
        onLongPress: onToggleSelection,
      ),
    );

    // Tắt vuốt trong lúc chọn nhiều để thao tác chạm không bị hiểu thành gesture.
    if (selectionMode) return card;

    // Vuốt đầu thẻ đổi trạng thái; vuốt cuối thẻ mở các thao tác nhanh khác.
    return Slidable(
      key: key,
      startActionPane: ActionPane(
        extentRatio: 0.32,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onStatusChanged(_nextStatus(task.status));
            },
            backgroundColor: AppColors.statusInProgress,
            foregroundColor: Colors.white,
            icon: IconsaxPlusLinear.arrow_swap_horizontal,
            label: taskStatusLabel(_nextStatus(task.status)),
          ),
        ],
      ),
      endActionPane: ActionPane(
        extentRatio: 0.72,
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onChoosePriority();
            },
            backgroundColor: AppColors.priorityHigh,
            foregroundColor: Colors.white,
            icon: IconsaxPlusLinear.flag,
            label: 'Ưu tiên',
          ),
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onReschedule();
            },
            backgroundColor: AppColors.calmPrimary,
            foregroundColor: Colors.white,
            icon: IconsaxPlusLinear.calendar_1,
            label: 'Dời hạn',
          ),
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onAssign();
            },
            backgroundColor: AppColors.statusTodo,
            foregroundColor: Colors.white,
            icon: IconsaxPlusLinear.user_add,
            label: 'Giao việc',
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _taskSubtitle(BuildContext context) {
    // Thông tin phụ trên thẻ được gom thành nhãn trạng thái, ưu tiên, hạn và tag.
    final details = <Widget>[];
    if (task.description.isNotEmpty) {
      details.add(
        Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
      );
    }

    details.add(
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _smallLabel(taskStatusLabel(task.status), _statusColor(task.status)),
          _smallLabel(
            taskPriorityLabel(task.priority),
            _priorityColor(task.priority),
          ),
          if (task.deadline != null)
            _smallLabel(
              DateFormat('dd/MM/yyyy').format(task.deadline!),
              task.isOverdue ? Colors.red : Colors.blueGrey,
            ),
          if (task.subtasks.isNotEmpty)
            _smallLabel(
              'Checklist ${task.subtasks.where((item) => item.isCompleted).length}/${task.subtasks.length}',
              Colors.teal,
            ),
        ],
      ),
    );

    if (task.tags.isNotEmpty) {
      details.add(
        Wrap(
          spacing: 6,
          children: [
            for (final tag in task.tags.take(3))
              _smallLabel(tag, Theme.of(context).colorScheme.primary),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final detail in details) ...[detail, const SizedBox(height: 6)],
        ],
      ),
    );
  }

  Widget _smallLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  TaskStatus _nextStatus(TaskStatus status) {
    // Thứ tự chu kỳ trạng thái dùng bởi nút vuốt bên trái.
    switch (status) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.done;
      case TaskStatus.done:
        return TaskStatus.cancelled;
      case TaskStatus.cancelled:
        return TaskStatus.todo;
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return AppColors.statusTodo;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.done:
        return AppColors.statusDone;
      case TaskStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
    }
  }
}
