import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/data/mock_repository.dart';
import '../../../core/models/task_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../../../core/services/task_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/contextual_fab.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/task_crud_provider.dart';
import 'checklist_section_widget.dart';
import 'comment_timeline_widget.dart';
import 'task_form_bottom_sheet.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/board');
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskId = widget.taskId;
    final task = ref.watch(taskByIdProvider(taskId));

    if (task == null) {
      // Chỉ dùng khi chạy debug để mở màn hình mà chưa có Backend.
      final existsLocally =
          ref.read(coreTasksProvider).any((t) => t.id == taskId);
      final mockTask = kDebugMode && !existsLocally
          ? MockRepository.mockTasks.where((t) => t.id == taskId).firstOrNull
          : null;
      if (mockTask != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(taskCrudProvider).upsertLocalTask(mockTask);
        });
      }
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => _close(context)),
        ),
        body: Center(
          child: mockTask != null
              ? const CircularProgressIndicator()
              : const Text('Không tìm thấy công việc này.'),
        ),
      );
    }

    final dateFormat = DateFormat('HH:mm, dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(onPressed: () => _close(context)),
        title: Text(
          'Chi tiết công việc',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            icon: const Icon(IconsaxPlusLinear.edit_2),
            onPressed: () => TaskFormBottomSheet.show(context, task: task),
          ),
          PopupMenuButton<VoidCallback>(
            tooltip: 'Thao tác khác',
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              if (task.status != TaskStatus.cancelled)
                PopupMenuItem(
                  value: () => ref.read(taskCrudProvider).updateTask(
                        task.copyWith(status: TaskStatus.cancelled),
                      ),
                  child: const Text('Hủy công việc'),
                ),
              PopupMenuItem(
                value: () => _confirmDelete(context, task),
                child: const Text('Xóa công việc'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: ContextualFab(
        contextType: FabContextType.taskDetail,
        currentTask: task,
        onPressed: () => ref
            .read(taskCrudProvider)
            .updateTask(task.copyWith(status: _nextStatus(task.status))),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(taskCrudProvider).refreshTask(taskId),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16,
            AppSizes.p16,
            AppSizes.p16,
            AppSizes.p64 + AppSizes.p32,
          ),
          children: [
            Text(
              task.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Wrap(
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(status: task.status),
                PriorityBadge(priority: task.priority),
              ],
            ),
            const SizedBox(height: AppSizes.p16),
            if (task.startDate != null)
              _InfoRow(
                icon: IconsaxPlusLinear.play,
                label: 'Bắt đầu: ${dateFormat.format(task.startDate!)}',
              ),
            _InfoRow(
              icon: IconsaxPlusLinear.calendar_1,
              label: task.deadline == null
                  ? 'Chưa đặt deadline'
                  : dateFormat.format(task.deadline!),
              subtitle: task.isOverdue ? 'Đã quá hạn' : null,
              color: task.isOverdue ? AppColors.priorityUrgent : null,
            ),
            _AssigneeRow(task: task),
            _OptionRow(
              icon: IconsaxPlusLinear.folder,
              emptyLabel: 'Chưa thuộc dự án',
              dialogTitle: 'Chọn dự án',
              options: ref.watch(projectOptionsProvider),
              selectedId: task.projectId,
              onSelected: (id) => ref
                  .read(taskCrudProvider)
                  .updateTask(task.copyWith(projectId: id)),
            ),
            _OptionRow(
              icon: IconsaxPlusLinear.category,
              emptyLabel: 'Chưa có danh mục',
              dialogTitle: 'Chọn danh mục',
              options: ref.watch(categoryOptionsProvider),
              selectedId: task.categoryId,
              onSelected: (id) => ref
                  .read(taskCrudProvider)
                  .updateTask(task.copyWith(categoryId: id)),
            ),
            const SizedBox(height: AppSizes.p16),
            _DescriptionSection(task: task),
            const SizedBox(height: AppSizes.p24),
            _TagsSection(task: task),
            const SizedBox(height: AppSizes.p24),
            ChecklistSectionWidget(
              subtasks: task.subtasks,
              progress: task.checklistProgress,
              onAdd: (title) => _notifyIfNotSynced(
                ref.read(taskCrudProvider).addSubtask(task.id, title),
              ),
              onToggle: (subtaskId) => _notifyIfNotSynced(
                ref.read(taskCrudProvider).toggleSubtask(task.id, subtaskId),
              ),
              onDelete: (subtaskId) => _notifyIfNotSynced(
                ref.read(taskCrudProvider).deleteSubtask(task.id, subtaskId),
              ),
              onReorder: (ordered) => _notifyIfNotSynced(
                ref.read(taskCrudProvider).reorderSubtasks(task.id, ordered),
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            Text(
              'Bình luận (${task.comments.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const CommentTimelineWidget(),
          ],
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

  Future<void> _notifyIfNotSynced(Future<bool> action) async {
    final messenger = ScaffoldMessenger.of(context);
    final isSynced = await action;
    if (!isSynced && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Chưa đồng bộ được với máy chủ. Thay đổi chỉ lưu trên máy này.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: Text('Công việc "${task.title}" sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.priorityUrgent,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final crud = ref.read(taskCrudProvider);
    _close(context);
    await crud.deleteTask(task.id);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor = color ?? AppColors.statusTodo;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      leading: Icon(icon, color: rowColor),
      title: Text(
        label,
        style: TextStyle(color: rowColor, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing,
    );
  }
}

class _AssigneeRow extends ConsumerWidget {
  final TaskItem task;

  const _AssigneeRow({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isMine = currentUser != null && task.assigneeId == currentUser.id;

    final String label;
    if (task.assigneeId == null) {
      label = 'Chưa giao cho ai';
    } else if (isMine) {
      label = 'Đã giao cho bạn';
    } else {
      label = 'Đã giao cho thành viên khác';
    }

    return _InfoRow(
      icon: IconsaxPlusLinear.user,
      label: label,
      trailing: currentUser == null || isMine
          ? null
          : TextButton(
              onPressed: () => ref
                  .read(taskCrudProvider)
                  .updateTask(task.copyWith(assigneeId: currentUser.id)),
              child: const Text('Giao cho tôi'),
            ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String emptyLabel;
  final String dialogTitle;
  final AsyncValue<List<NamedOption>> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const _OptionRow({
    required this.icon,
    required this.emptyLabel,
    required this.dialogTitle,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  Future<void> _pick(BuildContext context, List<NamedOption> items) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(dialogTitle),
        children: [
          for (final item in items)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(item.id),
              child: Text(item.name),
            ),
        ],
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final items = options.value ?? const <NamedOption>[];
    final selected = items.where((o) => o.id == selectedId).firstOrNull;

    final String label;
    if (selected != null) {
      label = selected.name;
    } else if (selectedId != null) {
      label = 'Đã chọn (chưa tải được tên)';
    } else {
      label = emptyLabel;
    }

    return _InfoRow(
      icon: icon,
      label: label,
      onTap: items.isEmpty ? null : () => _pick(context, items),
      trailing: items.isEmpty ? null : const Icon(Icons.chevron_right),
    );
  }
}

class _DescriptionSection extends ConsumerWidget {
  final TaskItem task;

  const _DescriptionSection({required this.task});

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final description = await showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(
        title: 'Mô tả công việc',
        initialValue: task.description,
        maxLines: 6,
      ),
    );
    if (description == null) return;
    await ref
        .read(taskCrudProvider)
        .updateTask(task.copyWith(description: description.trim()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mô tả',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Sửa mô tả',
              icon: const Icon(IconsaxPlusLinear.edit_2, size: 18),
              onPressed: () => _edit(context, ref),
            ),
          ],
        ),
        Text(
          task.description.isEmpty ? 'Chưa có mô tả.' : task.description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: task.description.isEmpty ? AppColors.statusCancelled : null,
          ),
        ),
      ],
    );
  }
}

class _TagsSection extends ConsumerWidget {
  final TaskItem task;

  const _TagsSection({required this.task});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => const _TextInputDialog(title: 'Thêm nhãn'),
    );
    final name = tag?.trim() ?? '';
    if (name.isEmpty || task.tags.contains(name)) return;
    await ref
        .read(taskCrudProvider)
        .updateTask(task.copyWith(tags: [...task.tags, name]));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhãn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p4,
          children: [
            for (final tag in task.tags)
              InputChip(
                label: Text(tag),
                onDeleted: () => ref.read(taskCrudProvider).updateTask(
                      task.copyWith(
                        tags: task.tags.where((t) => t != tag).toList(),
                      ),
                    ),
              ),
            ActionChip(
              avatar: const Icon(IconsaxPlusLinear.add, size: AppSizes.iconSmall),
              label: const Text('Thêm nhãn'),
              onPressed: () => _add(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final int maxLines;

  const _TextInputDialog({
    required this.title,
    this.initialValue = '',
    this.maxLines = 1,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
