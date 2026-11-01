import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/task_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../providers/multi_select_provider.dart';
import '../providers/task_filter_sort_provider.dart';
import 'category_project_drawer.dart';
import 'search_filter_bar.dart';
import 'slidable_task_card.dart';

class TaskBoardScreen extends ConsumerStatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(multiSelectProvider.notifier).clear();
    ref.read(taskFilterSortProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(coreTasksProvider);
    final filters = ref.watch(taskFilterSortProvider);
    final selectedIds = ref.watch(multiSelectProvider);
    final visibleTasks = filters.filterTasks(tasks);
    final selectionMode = selectedIds.isNotEmpty;
    final canReorder =
        !filters.hasFilters &&
        filters.sortMode == TaskSortMode.manual &&
        !selectionMode;

    ref.listen<List<TaskItem>>(coreTasksProvider, (previous, next) {
      final currentFilters = ref.read(taskFilterSortProvider);
      final validIds = currentFilters
          .filterTasks(next)
          .map(_selectionId)
          .toSet();
      ref.read(multiSelectProvider.notifier).keepOnly(validIds);
    });
    ref.listen<TaskFilterSortState>(taskFilterSortProvider, (previous, next) {
      if (previous != null && _filtersChanged(previous, next)) {
        ref.read(multiSelectProvider.notifier).clear();
      }
    });

    return Scaffold(
      drawer: const CategoryProjectDrawer(),
      appBar: AppBar(
        title: Text(
          selectionMode ? 'Đã chọn ${selectedIds.length}' : 'Task Board',
        ),
        actions: [
          if (selectionMode) ...[
            IconButton(
              tooltip: 'Đánh dấu hoàn thành',
              onPressed: _completeSelectedTasks,
              icon: const Icon(Icons.done_all),
            ),
            IconButton(
              tooltip: 'Bỏ chọn',
              onPressed: () => ref.read(multiSelectProvider.notifier).clear(),
              icon: const Icon(Icons.close),
            ),
          ] else
            IconButton(
              tooltip: 'Đồng bộ',
              onPressed: _refreshTasks,
              icon: const Icon(Icons.sync),
            ),
        ],
      ),
      body: Column(
        children: [
          const SearchFilterBar(),
          if (filters.projectId != null || filters.categoryId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_activeScopeLabel(filters))),
                  TextButton(
                    onPressed: () {
                      final notifier = ref.read(
                        taskFilterSortProvider.notifier,
                      );
                      notifier.setProjectId(null);
                      notifier.setCategoryId(null);
                    },
                    child: const Text('Xóa'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${visibleTasks.length} công việc',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTasks,
              child: _taskList(
                visibleTasks,
                selectedIds,
                selectionMode,
                canReorder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskList(
    List<TaskItem> tasks,
    Set<String> selectedIds,
    bool selectionMode,
    bool canReorder,
  ) {
    if (tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 280,
            child: Center(child: Text('Không tìm thấy công việc')),
          ),
        ],
      );
    }

    if (canReorder) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tasks.length,
        onReorderItem: (oldIndex, newIndex) {
          unawaited(_reorderTasks(tasks, oldIndex, newIndex));
        },
        itemBuilder: (context, index) => _taskCard(
          tasks[index],
          index,
          selectedIds,
          selectionMode,
          canReorder,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _taskCard(
        tasks[index],
        index,
        selectedIds,
        selectionMode,
        canReorder,
      ),
    );
  }

  Widget _taskCard(
    TaskItem task,
    int index,
    Set<String> selectedIds,
    bool selectionMode,
    bool canReorder,
  ) {
    return SlidableTaskCard(
      key: ValueKey(
        task.id.isEmpty
            ? task.title + task.createdAt.toIso8601String()
            : task.id,
      ),
      task: task,
      reorderIndex: index,
      selectionMode: selectionMode,
      selected: selectedIds.contains(_selectionId(task)),
      canReorder: canReorder,
      onToggleSelection: () => _toggleSelection(task),
      onToggleDone: () => _saveTask(
        task.copyWith(
          status: task.status == TaskStatus.done
              ? TaskStatus.todo
              : TaskStatus.done,
        ),
      ),
      onStatusChanged: (status) => _saveTask(task.copyWith(status: status)),
      onChoosePriority: () => _choosePriority(task),
      onReschedule: () => _rescheduleTask(task),
      onAssign: () => _assignTask(task),
    );
  }

  void _toggleSelection(TaskItem task) {
    final added = ref
        .read(multiSelectProvider.notifier)
        .toggle(_selectionId(task));
    if (!added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ chọn tối đa 5 công việc.')),
      );
    }
  }

  Future<void> _completeSelectedTasks() async {
    final selectedIds = ref.read(multiSelectProvider);
    final tasks = ref.read(coreTasksProvider);
    final notifier = ref.read(coreTasksProvider.notifier);

    for (final task in tasks) {
      if (selectedIds.contains(_selectionId(task)) &&
          task.status != TaskStatus.done &&
          task.deletedAt == null) {
        await notifier.updateTask(task.copyWith(status: TaskStatus.done));
      }
    }

    if (!mounted) return;
    ref.read(multiSelectProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã hoàn thành ${selectedIds.length} công việc.')),
    );
  }

  void _saveTask(TaskItem task) {
    HapticFeedback.lightImpact();
    unawaited(ref.read(coreTasksProvider.notifier).updateTask(task));
  }

  Future<void> _reorderTasks(
    List<TaskItem> currentTasks,
    int oldIndex,
    int newIndex,
  ) async {
    final reordered = List<TaskItem>.from(currentTasks);
    if (oldIndex == newIndex) return;

    final movedTask = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, movedTask);

    unawaited(HapticFeedback.mediumImpact());
    final notifier = ref.read(coreTasksProvider.notifier);
    for (var index = 0; index < reordered.length; index++) {
      final reorderedTask = reordered[index];
      final taskId = _selectionId(reorderedTask);
      final task = ref
          .read(coreTasksProvider)
          .firstWhere(
            (currentTask) => _selectionId(currentTask) == taskId,
            orElse: () => reorderedTask,
          );
      final newOrder = index.toDouble();
      if (task.orderIndex != newOrder) {
        await notifier.updateTask(task.copyWith(orderIndex: newOrder));
      }
    }
  }

  Future<void> _choosePriority(TaskItem task) async {
    final priority = await showModalBottomSheet<TaskPriority>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in TaskPriority.values)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(taskPriorityLabel(item)),
                trailing: item == task.priority
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (!mounted || priority == null) return;
    _saveTask(task.copyWith(priority: priority));
  }

  Future<void> _rescheduleTask(TaskItem task) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentDeadline = task.deadline;
    final initialDate =
        currentDeadline != null && !currentDeadline.isBefore(today)
        ? currentDeadline
        : today;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (!mounted || date == null) return;

    final deadline = DateTime(
      date.year,
      date.month,
      date.day,
      currentDeadline?.hour ?? 9,
      currentDeadline?.minute ?? 0,
    );
    _saveTask(task.copyWith(deadline: deadline));
  }

  Future<void> _assignTask(TaskItem task) async {
    final controller = TextEditingController(text: task.assigneeId ?? '');
    final assigneeId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Giao công việc'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ID thành viên',
            hintText: 'Nhập ID thành viên trong project',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || assigneeId == null || assigneeId.isEmpty) return;
    _saveTask(task.copyWith(assigneeId: assigneeId));
  }

  Future<void> _refreshTasks() async {
    final success = await ref
        .read(coreTasksProvider.notifier)
        .syncFromBackend();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã đồng bộ công việc.' : 'Không kết nối được máy chủ.',
        ),
      ),
    );
  }

  String _selectionId(TaskItem task) {
    if (task.id.isNotEmpty) return task.id;
    return task.title + task.createdAt.toIso8601String();
  }

  bool _filtersChanged(TaskFilterSortState previous, TaskFilterSortState next) {
    return previous.query != next.query ||
        previous.status != next.status ||
        previous.priority != next.priority ||
        previous.tag != next.tag ||
        previous.dueFilter != next.dueFilter ||
        previous.sortMode != next.sortMode ||
        previous.projectId != next.projectId ||
        previous.categoryId != next.categoryId;
  }

  String _activeScopeLabel(TaskFilterSortState filters) {
    final labels = <String>[];
    if (filters.projectId != null) {
      labels.add('Project ${_shortId(filters.projectId!)}');
    }
    if (filters.categoryId != null) {
      labels.add('Category ${_shortId(filters.categoryId!)}');
    }
    return labels.join(' • ');
  }

  String _shortId(String id) => id.length > 12 ? id.substring(0, 12) : id;
}
