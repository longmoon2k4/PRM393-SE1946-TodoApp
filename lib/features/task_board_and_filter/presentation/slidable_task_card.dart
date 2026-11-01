import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/models/task_model.dart';
import '../providers/task_filter_sort_provider.dart';

class SlidableTaskCard extends StatelessWidget {
  final TaskItem task;
  final int reorderIndex;
  final bool selectionMode;
  final bool selected;
  final bool canReorder;
  final VoidCallback onToggleSelection;
  final VoidCallback onToggleDone;
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
    required this.onToggleDone,
    required this.onStatusChanged,
    required this.onChoosePriority,
    required this.onReschedule,
    required this.onAssign,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: selectionMode
            ? Checkbox(value: selected, onChanged: (_) => onToggleSelection())
            : Checkbox(
                value: task.status == TaskStatus.done,
                onChanged: (_) => onToggleDone(),
              ),
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
                  child: Icon(Icons.drag_handle),
                ),
              )
            : null,
        onTap: selectionMode ? onToggleSelection : null,
        onLongPress: onToggleSelection,
      ),
    );

    if (selectionMode) return card;

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
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            icon: Icons.swap_horiz,
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
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            icon: Icons.flag_outlined,
            label: 'Ưu tiên',
          ),
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onReschedule();
            },
            backgroundColor: const Color(0xFF0891B2),
            foregroundColor: Colors.white,
            icon: Icons.calendar_month_outlined,
            label: 'Dời hạn',
          ),
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.lightImpact();
              onAssign();
            },
            backgroundColor: const Color(0xFF475569),
            foregroundColor: Colors.white,
            icon: Icons.person_add_alt_1,
            label: 'Giao việc',
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _taskSubtitle(BuildContext context) {
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
    switch (status) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.done;
      case TaskStatus.done:
      case TaskStatus.cancelled:
        return TaskStatus.todo;
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blueGrey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blueGrey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }
}
