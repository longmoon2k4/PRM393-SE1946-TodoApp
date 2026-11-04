import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/models/task_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../task_detail_and_collab/presentation/task_form_bottom_sheet.dart';
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
  final _boardController = PageController();
  int _currentColumn = 0;

  @override
  void initState() {
    super.initState();
    // Mỗi lần vào Board bắt đầu với bộ lọc sạch và không giữ lựa chọn cũ.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(multiSelectProvider.notifier).clear();
      ref.read(taskFilterSortProvider.notifier).clearFilters();
    });
  }

  @override
  void dispose() {
    _boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ghép dữ liệu task với bộ lọc và lựa chọn để quyết định nội dung Board.
    final tasks = ref.watch(coreTasksProvider);
    final filters = ref.watch(taskFilterSortProvider);
    final selectedIds = ref.watch(multiSelectProvider);
    final visibleTasks = filters.filterTasks(tasks);
    final selectionMode = selectedIds.isNotEmpty;
    final canReorder =
        !filters.hasFilters &&
        filters.sortMode == TaskSortMode.manual &&
        !selectionMode;

    // Đồng bộ selection với task còn hiển thị khi danh sách hoặc bộ lọc đổi.
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
      // Khi lọc trạng thái, mở đúng cột chứa kết quả.
      if (previous?.status != next.status &&
          next.status != null &&
          _boardController.hasClients) {
        _boardController.jumpToPage(TaskStatus.values.indexOf(next.status!));
      }
    });

    // Phần khung: drawer, thanh trên cùng, tìm kiếm, số kết quả và các cột Kanban.
    return Scaffold(
      drawer: const CategoryProjectDrawer(),
      floatingActionButton: selectionMode
          ? null
          : Transform.translate(
              offset: const Offset(0, 10),
              child: FloatingActionButton.small(
                tooltip: 'Tạo công việc',
                backgroundColor: AppColors.priorityMedium,
                onPressed: () => TaskFormBottomSheet.show(context),
                child: const Icon(IconsaxPlusLinear.add, color: Colors.white),
              ),
            ),
      appBar: AppBar(
        title: Text(
          selectionMode ? 'Đã chọn ${selectedIds.length}' : 'Task Board',
        ),
        actions: [
          if (selectionMode) ...[
            TextButton(
              onPressed: _cancelSelectedTasks,
              child: const Text('Chuyển Đã hủy'),
            ),
            IconButton(
              tooltip: 'Bỏ chọn',
              onPressed: () => ref.read(multiSelectProvider.notifier).clear(),
              icon: const Icon(IconsaxPlusLinear.close_circle),
            ),
          ] else
            IconButton(
              tooltip: 'Đồng bộ',
              onPressed: _refreshTasks,
              icon: const Icon(IconsaxPlusLinear.refresh),
            ),
          if (!selectionMode)
            IconButton(
              tooltip: 'Trang chủ',
              onPressed: () => context.go('/dashboard'),
              icon: const Icon(IconsaxPlusLinear.home_2),
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
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${visibleTasks.length} công việc',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                // Dấu sáng chỉ vị trí cột đang xem.
                Semantics(
                  label: 'Cột ${_currentColumn + 1} trên ${TaskStatus.values.length}',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final status in TaskStatus.values)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status.index == _currentColumn
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _kanbanBoard(
              visibleTasks,
              selectedIds,
              selectionMode,
              canReorder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kanbanBoard(
    List<TaskItem> tasks,
    Set<String> selectedIds,
    bool selectionMode,
    bool canReorder,
  ) {
    // Mỗi trang là một cột rộng theo màn hình; vuốt ngang để chuyển cột.
    return PageView(
      controller: _boardController,
      onPageChanged: (index) => setState(() => _currentColumn = index),
      children: [
        for (final status in TaskStatus.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _statusColumn(
              status: status,
              tasks: tasks.where((task) => task.status == status).toList(),
              selectedIds: selectedIds,
              selectionMode: selectionMode,
              canReorder: canReorder,
            ),
          ),
      ],
    );
  }

  Widget _statusColumn({
    required TaskStatus status,
    required List<TaskItem> tasks,
    required Set<String> selectedIds,
    required bool selectionMode,
    required bool canReorder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Tiêu đề cho biết trạng thái và số task; danh sách bên dưới cuộn độc lập.
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _statusAccent(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    taskStatusLabel(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${tasks.length}'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTasks,
              child: _statusTaskList(
                status: status,
                tasks: tasks,
                selectedIds: selectedIds,
                selectionMode: selectionMode,
                canReorder: canReorder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTaskList({
    required TaskStatus status,
    required List<TaskItem> tasks,
    required Set<String> selectedIds,
    required bool selectionMode,
    required bool canReorder,
  }) {
    // Cột rỗng vẫn cho kéo xuống đồng bộ; canReorder quyết định có bật kéo sắp xếp.
    if (tasks.isEmpty) {
      return ListView(
        key: PageStorageKey('empty-${status.name}'),
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 160,
            child: Center(child: Text('Không có công việc')),
          ),
        ],
      );
    }

    if (canReorder) {
      return ReorderableListView.builder(
        key: PageStorageKey('tasks-${status.name}'),
        primary: false,
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.only(top: 4, bottom: 72),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tasks.length,
        onReorderItem: (oldIndex, newIndex) {
          unawaited(_reorderColumnTasks(tasks, oldIndex, newIndex));
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
      key: PageStorageKey('tasks-${status.name}'),
      primary: false,
      padding: const EdgeInsets.only(top: 4, bottom: 72),
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
    // Nối thao tác trên thẻ với hàm cập nhật state hoặc mở hộp chọn bên dưới.
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

  Future<void> _cancelSelectedTasks() async {
    // Chuyển các task đang chọn sang Đã hủy rồi thoát chế độ chọn.
    final selectedIds = ref.read(multiSelectProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = ref.read(coreTasksProvider.notifier);
    ref.read(multiSelectProvider.notifier).clear();
    var changedCount = 0;

    for (final id in selectedIds) {
      // Lấy lại task trước mỗi lần lưu để giữ các thay đổi vừa thực hiện.
      final matches = container.read(coreTasksProvider).where(
        (task) => _selectionId(task) == id,
      );
      if (matches.isEmpty) continue;
      final task = matches.first;
      if (task.status != TaskStatus.cancelled && task.deletedAt == null) {
        await notifier.updateTask(task.copyWith(status: TaskStatus.cancelled));
        changedCount++;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã cập nhật $changedCount công việc trên màn hình. '
          'Hãy kiểm tra lại sau khi đồng bộ.',
        ),
      ),
    );
  }

  void _saveTask(TaskItem task) {
    // Mọi thay đổi nhanh trên Board đi qua provider dùng chung của task.
    HapticFeedback.lightImpact();
    unawaited(ref.read(coreTasksProvider.notifier).updateTask(task));
  }

  Future<void> _reorderColumnTasks(
    List<TaskItem> currentTasks,
    int oldIndex,
    int newIndex,
  ) async {
    // Sắp xếp trong cột hiện tại và lưu orderIndex của từng task đã đổi vị trí.
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
    // Ưu tiên, dời hạn và giao việc đều mở UI nhập/chọn rồi lưu lại task.
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

  Color _statusAccent(TaskStatus status) {
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
}
