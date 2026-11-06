import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/data/mock_repository.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../../../core/services/task_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/widgets/contextual_fab.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/comment_author_provider.dart';
import '../providers/task_crud_provider.dart';
import '../providers/task_permission_provider.dart';
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
  static const Duration _commentPollInterval = Duration(seconds: 15);

  Timer? _commentPollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshComments);
    _commentPollTimer = Timer.periodic(
      _commentPollInterval,
      (_) => _refreshComments(),
    );
  }

  @override
  void dispose() {
    _commentPollTimer?.cancel();
    super.dispose();
  }

  void _refreshComments() {
    if (!mounted) return;
    // Bình luận chờ gửi chỉ có khi Task đã nằm trên máy.
    final hasTask = ref.read(taskByIdProvider(widget.taskId)) != null;
    ref
        .read(taskCrudProvider)
        .refreshComments(
          widget.taskId,
          author: hasTask ? ref.read(commentAuthorProvider) : null,
        );
  }

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
      final existsLocally = ref
          .read(coreTasksProvider)
          .any((t) => t.id == taskId);
      final mockTask = kDebugMode && !existsLocally
          ? MockRepository.mockTasks.where((t) => t.id == taskId).firstOrNull
          : null;
      if (mockTask != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(taskCrudProvider).upsertLocalTask(mockTask);
        });
      }
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => _close(context))),
        body: Center(
          child: mockTask != null
              ? const CircularProgressIndicator()
              : const Text('Không tìm thấy công việc này.'),
        ),
      );
    }

    final commentAuthor = ref.watch(commentAuthorProvider);
    final backendAuthorId = commentAuthor == null
        ? null
        : ref.watch(commentAuthorIdsProvider)[commentAuthor.id];
    final permissions = ref.watch(taskPermissionsProvider(taskId));
    final dateFormat = DateFormat('HH:mm, dd/MM/yyyy');
    // Khi bàn phím mở, FAB nổi lên và che nút gửi bình luận.
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

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
          if (kDebugMode) const _ViewAsButton(),
          if (permissions.canManage) ...[
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
                    value: () => ref
                        .read(taskCrudProvider)
                        .updateTask(
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
        ],
      ),
      floatingActionButton: permissions.canProgress && !isKeyboardOpen
          ? ContextualFab(
              contextType: FabContextType.taskDetail,
              currentTask: task,
              onPressed: () => ref
                  .read(taskCrudProvider)
                  .updateTask(task.copyWith(status: _nextStatus(task.status))),
            )
          : null,
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
            if (kDebugMode && ref.watch(debugViewAsProvider) != null) ...[
              const SizedBox(height: AppSizes.p12),
              _ViewAsBanner(user: ref.watch(debugViewAsProvider)!),
            ],
            if (!permissions.canManage) ...[
              const SizedBox(height: AppSizes.p12),
              _RoleNotice(canWork: permissions.canWork),
            ],
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
            _InfoRow(
              icon: IconsaxPlusLinear.notification,
              label: task.reminderAt == null
                  ? 'Chưa đặt giờ nhắc'
                  : 'Nhắc lúc ${dateFormat.format(task.reminderAt!)}',
            ),
            _AssigneeRow(task: task, canAssign: permissions.canManage),
            _OptionRow(
              icon: IconsaxPlusLinear.folder,
              emptyLabel: 'Chưa thuộc dự án',
              dialogTitle: 'Chọn dự án',
              options: ref.watch(projectOptionsProvider),
              selectedId: task.projectId,
              onSelected: permissions.canManage
                  ? (id) => ref
                        .read(taskCrudProvider)
                        .updateTask(task.copyWith(projectId: id))
                  : null,
              itemName: 'dự án',
              onCreate: permissions.canManage
                  ? (name) => ref
                        .read(taskCrudProvider)
                        .createProjectFor(task.id, name)
                  : null,
            ),
            _OptionRow(
              icon: IconsaxPlusLinear.category,
              emptyLabel: 'Chưa có danh mục',
              dialogTitle: 'Chọn danh mục',
              options: ref.watch(categoryOptionsProvider),
              selectedId: task.categoryId,
              onSelected: permissions.canManage
                  ? (id) => ref
                        .read(taskCrudProvider)
                        .updateTask(task.copyWith(categoryId: id))
                  : null,
              itemName: 'danh mục',
              onCreate: permissions.canManage
                  ? (name) => ref
                        .read(taskCrudProvider)
                        .createCategoryFor(task.id, name)
                  : null,
            ),
            const SizedBox(height: AppSizes.p16),
            _DescriptionSection(task: task, canEdit: permissions.canManage),
            const SizedBox(height: AppSizes.p24),
            _TagsSection(task: task, canEdit: permissions.canManage),
            const SizedBox(height: AppSizes.p24),
            ChecklistSectionWidget(
              subtasks: task.subtasks,
              progress: task.checklistProgress,
              canManage: permissions.canManage,
              canToggle: permissions.canWork,
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
            const SizedBox(height: AppSizes.p8),
            CommentTimelineWidget(
              comments: task.comments,
              currentUserId: backendAuthorId ?? commentAuthor?.id,
              otherOwnIds: {if (commentAuthor != null) commentAuthor.id},
              onSend: (content) => _notifyIfNotSynced(
                ref
                    .read(taskCrudProvider)
                    .addComment(
                      task.id,
                      author: commentAuthor!,
                      content: content,
                    ),
              ),
            ),
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
          content: Text(
            'Chưa đồng bộ được với máy chủ. Thay đổi chỉ lưu trên máy này.',
          ),
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

/// Chỉ có ở bản debug: đổi người đang xem để thử quyền của từng thành viên.
class _ViewAsButton extends ConsumerWidget {
  const _ViewAsButton();

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final current = ref.read(debugViewAsProvider);
    final options = <({UserModel? user, String label})>[
      (user: null, label: 'Tài khoản đang đăng nhập'),
      for (final member in TeamRoster.members)
        (user: member.toUser(), label: member.name),
    ];

    final picked = await showDialog<({UserModel? user})>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Xem với vai trò'),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () =>
                  Navigator.of(dialogContext).pop((user: option.user)),
              child: Row(
                children: [
                  Expanded(child: Text(option.label)),
                  if (option.user?.id == current?.id)
                    const Icon(Icons.check, size: AppSizes.iconNormal),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    ref.read(debugViewAsProvider.notifier).viewAs(picked.user);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Xem với vai trò',
      icon: const Icon(IconsaxPlusLinear.profile_2user),
      onPressed: () => _pick(context, ref),
    );
  }
}

class _ViewAsBanner extends ConsumerWidget {
  final UserModel user;

  const _ViewAsBanner({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p12,
        AppSizes.p4,
        AppSizes.p4,
        AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: AppColors.priorityHigh.withAlpha(25),
        borderRadius: const BorderRadius.all(AppSizes.radius12),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.eye,
            size: AppSizes.iconNormal,
            color: AppColors.priorityHigh,
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: Text(
              'Đang xem với vai trò ${user.name} (chỉ bản debug)',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(debugViewAsProvider.notifier).viewAs(null),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
}

class _RoleNotice extends StatelessWidget {
  final bool canWork;

  const _RoleNotice({required this.canWork});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.statusTodo.withAlpha(20),
        borderRadius: const BorderRadius.all(AppSizes.radius12),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.lock,
            size: AppSizes.iconNormal,
            color: AppColors.statusTodo,
          ),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: Text(
              canWork
                  ? 'Leader giao việc này cho bạn. Bạn được cập nhật checklist, trạng thái và bình luận.'
                  : 'Chỉ leader và người được giao mới thay đổi được công việc này.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssigneeRow extends ConsumerWidget {
  final TaskItem task;

  /// Chỉ leader được giao việc.
  final bool canAssign;

  const _AssigneeRow({required this.task, required this.canAssign});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final me = ref.read(commentAuthorProvider);
    final backendIds = ref.read(commentAuthorIdsProvider);
    final options = <({UserModel user, String label})>[
      if (me != null) (user: me, label: '${me.name} (tôi)'),
      for (final member in TeamRoster.members)
        if (member.id != me?.id) (user: member.toUser(), label: member.name),
    ];
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có thành viên nào trong danh sách nhóm.'),
        ),
      );
      return;
    }

    bool isAssigned(UserModel user) =>
        task.assigneeId != null &&
        (task.assigneeId == user.id || task.assigneeId == backendIds[user.id]);

    final picked = await showDialog<UserModel>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Giao việc cho'),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(option.user),
              child: Row(
                children: [
                  Expanded(child: Text(option.label)),
                  if (isAssigned(option.user))
                    const Icon(Icons.check, size: AppSizes.iconNormal),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || isAssigned(picked) || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final isSynced = await ref
        .read(taskCrudProvider)
        .assignTask(task.id, picked);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isSynced
              ? 'Đã giao việc cho ${picked.name}.'
              : 'Đã giao cho ${picked.name} trên máy, chưa lưu lên server.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myIds = ref.watch(currentUserIdsProvider);
    final assigneeId = task.assigneeId;

    final String label;
    if (assigneeId == null) {
      label = 'Chưa giao cho ai';
    } else if (myIds.contains(assigneeId)) {
      label = 'Đã giao cho bạn';
    } else {
      final member = TeamRoster.findMember(
        assigneeId,
        backendIds: ref.watch(commentAuthorIdsProvider),
      );
      label = member == null
          ? 'Đã giao cho thành viên khác'
          : 'Đã giao cho ${member.name}';
    }

    return _InfoRow(
      icon: IconsaxPlusLinear.user,
      label: label,
      onTap: canAssign ? () => _pick(context, ref) : null,
      trailing: canAssign
          ? TextButton(
              onPressed: () => _pick(context, ref),
              child: const Text('Giao việc'),
            )
          : null,
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String emptyLabel;
  final String dialogTitle;
  final AsyncValue<List<NamedOption>> options;
  final String? selectedId;

  /// `null` khi không có quyền đổi.
  final ValueChanged<String>? onSelected;

  /// Tên mục mới, ví dụ "dự án"; dùng cho nút tạo và ô nhập tên.
  final String itemName;

  /// Tạo mục mới rồi gán cho task; trả về `false` khi server không phản hồi.
  final Future<bool> Function(String name)? onCreate;

  const _OptionRow({
    required this.icon,
    required this.emptyLabel,
    required this.dialogTitle,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    required this.itemName,
    this.onCreate,
  });

  static const _createValue = '\u0000create';

  Future<void> _pick(BuildContext context, List<NamedOption> items) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(dialogTitle),
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p24,
                vertical: AppSizes.p8,
              ),
              child: Text(
                'Chưa có $itemName nào.',
                style: const TextStyle(color: AppColors.statusCancelled),
              ),
            ),
          for (final item in items)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(item.id),
              child: Row(
                children: [
                  Expanded(child: Text(item.name)),
                  if (item.id == selectedId)
                    const Icon(Icons.check, size: AppSizes.iconNormal),
                ],
              ),
            ),
          if (onCreate != null)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(_createValue),
              child: Row(
                children: [
                  const Icon(IconsaxPlusLinear.add, size: AppSizes.iconNormal),
                  const SizedBox(width: AppSizes.p8),
                  Text('Tạo $itemName mới'),
                ],
              ),
            ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    if (picked == _createValue) return _create(context);
    if (picked != selectedId) onSelected?.call(picked);
  }

  Future<void> _create(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _TextInputDialog(title: 'Tên $itemName mới'),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final isCreated = await onCreate!(trimmed);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isCreated
              ? 'Đã tạo $itemName "$trimmed".'
              : 'Không tạo được $itemName: server chưa phản hồi.',
        ),
      ),
    );
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

    final canPick =
        onSelected != null && (items.isNotEmpty || onCreate != null);
    return _InfoRow(
      icon: icon,
      label: label,
      onTap: canPick ? () => _pick(context, items) : null,
      trailing: canPick ? const Icon(Icons.chevron_right) : null,
    );
  }
}

class _DescriptionSection extends ConsumerWidget {
  final TaskItem task;
  final bool canEdit;

  const _DescriptionSection({required this.task, required this.canEdit});

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
            if (canEdit)
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
  final bool canEdit;

  const _TagsSection({required this.task, required this.canEdit});

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
                onDeleted: canEdit
                    ? () => ref
                          .read(taskCrudProvider)
                          .updateTask(
                            task.copyWith(
                              tags: task.tags.where((t) => t != tag).toList(),
                            ),
                          )
                    : null,
              ),
            if (canEdit)
              ActionChip(
                avatar: const Icon(
                  IconsaxPlusLinear.add,
                  size: AppSizes.iconSmall,
                ),
                label: const Text('Thêm nhãn'),
                onPressed: () => _add(context, ref),
              ),
            if (!canEdit && task.tags.isEmpty) const Text('Chưa có nhãn.'),
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
