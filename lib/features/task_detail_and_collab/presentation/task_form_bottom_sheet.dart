import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../providers/reminder_notification_service.dart';
import '../providers/task_crud_provider.dart';

/// Trả về nội dung lỗi, hoặc `null` nếu các mốc thời gian hợp lệ.
/// Giá trị không đổi so với [original] không bị bắt lỗi quá khứ, để Task đã
/// quá hạn vẫn sửa được các trường khác.
String? validateTaskDates({
  required DateTime now,
  DateTime? startDate,
  DateTime? deadline,
  DateTime? reminderAt,
  TaskItem? original,
}) {
  if (deadline != null &&
      deadline != original?.deadline &&
      !deadline.isAfter(now)) {
    return 'Deadline không được ở trong quá khứ';
  }
  if (reminderAt != null &&
      reminderAt != original?.reminderAt &&
      !reminderAt.isAfter(now)) {
    return 'Giờ nhắc phải ở trong tương lai';
  }
  if (deadline != null && reminderAt != null && reminderAt.isAfter(deadline)) {
    return 'Giờ nhắc phải trước deadline';
  }
  if (deadline != null && startDate != null && startDate.isAfter(deadline)) {
    return 'Ngày bắt đầu phải trước deadline';
  }
  return null;
}

class TaskFormBottomSheet extends ConsumerStatefulWidget {
  /// `null` để tạo Task mới, truyền Task để chỉnh sửa.
  final TaskItem? task;

  const TaskFormBottomSheet({super.key, this.task});

  static Future<void> show(BuildContext context, {TaskItem? task}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppSizes.radius24),
      ),
      builder: (_) => TaskFormBottomSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskFormBottomSheet> createState() =>
      _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends ConsumerState<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _checklistController = TextEditingController();
  final List<String> _checklistTitles = [];
  late TaskPriority _priority;
  DateTime? _startDate;
  DateTime? _deadline;
  DateTime? _reminderAt;
  String? _dateError;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _startDate = widget.task?.startDate;
    _deadline = widget.task?.deadline;
    _reminderAt = widget.task?.reminderAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? current, {bool allowPast = false}) async {
    final now = DateTime.now();
    final initial = current != null && (allowPast || current.isAfter(now))
        ? current
        : now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: allowPast ? DateTime(now.year - 5) : DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDateTime(_startDate, allowPast: true);
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickDeadline() async {
    final picked = await _pickDateTime(_deadline);
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _pickReminder() async {
    final picked = await _pickDateTime(_reminderAt);
    if (picked == null || !mounted) return;
    setState(() => _reminderAt = picked);

    final messenger = ScaffoldMessenger.of(context);
    final isGranted = await ReminderNotificationService.requestPermissions();
    if (!isGranted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Chưa có quyền thông báo nên nhắc nhở sẽ không hiện trên thiết bị này.'),
        ),
      );
    }
  }

  void _addChecklistItem() {
    final title = _checklistController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _checklistTitles.add(title);
      _checklistController.clear();
    });
  }

  void _submit() {
    final isTitleValid = _formKey.currentState!.validate();
    final dateError = validateTaskDates(
      now: DateTime.now(),
      startDate: _startDate,
      deadline: _deadline,
      reminderAt: _reminderAt,
      original: widget.task,
    );
    setState(() => _dateError = dateError);
    if (!isTitleValid || dateError != null) return;

    _addChecklistItem();
    final crud = ref.read(taskCrudProvider);
    final title = _titleController.text.trim();

    if (_isEditing) {
      crud.updateTask(
        widget.task!.copyWith(
          title: title,
          priority: _priority,
          startDate: _startDate,
          deadline: _deadline,
          reminderAt: _reminderAt,
        ),
      );
    } else {
      crud.createTask(
        title: title,
        priority: _priority,
        deadline: _deadline,
        reminderAt: _reminderAt,
        checklistTitles: _checklistTitles,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.p20,
        right: AppSizes.p20,
        top: AppSizes.p20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.p20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Chỉnh sửa công việc' : 'Tạo công việc mới',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Tiêu đề không được để trống'
                    : null,
              ),
              const SizedBox(height: AppSizes.p16),
              Wrap(
                spacing: AppSizes.p8,
                children: [
                  for (final priority in TaskPriority.values)
                    ChoiceChip(
                      label: Text(_priorityLabel(priority)),
                      selected: _priority == priority,
                      onSelected: (_) => setState(() => _priority = priority),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.p8),
              if (_isEditing)
                _DateTimeRow(
                  icon: IconsaxPlusLinear.play,
                  emptyLabel: 'Chọn ngày bắt đầu',
                  value: _startDate,
                  canClear: widget.task?.startDate == null,
                  onPick: _pickStartDate,
                  onClear: () => setState(() => _startDate = null),
                ),
              _DateTimeRow(
                icon: IconsaxPlusLinear.calendar_1,
                emptyLabel: 'Chọn deadline',
                value: _deadline,
                canClear: widget.task?.deadline == null,
                onPick: _pickDeadline,
                onClear: () => setState(() => _deadline = null),
              ),
              _DateTimeRow(
                icon: IconsaxPlusLinear.notification,
                emptyLabel: 'Đặt giờ nhắc',
                value: _reminderAt,
                canClear: widget.task?.reminderAt == null,
                onPick: _pickReminder,
                onClear: () => setState(() => _reminderAt = null),
              ),
              if (_dateError != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.p12),
                  child: Text(
                    _dateError!,
                    style: const TextStyle(
                      color: AppColors.priorityUrgent,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (!_isEditing) ...[
                const SizedBox(height: AppSizes.p8),
                for (var i = 0; i < _checklistTitles.length; i++)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_box_outline_blank, size: 20),
                    title: Text(_checklistTitles[i]),
                    trailing: IconButton(
                      tooltip: 'Xóa mục con',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () =>
                          setState(() => _checklistTitles.removeAt(i)),
                    ),
                  ),
                TextField(
                  controller: _checklistController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addChecklistItem(),
                  decoration: InputDecoration(
                    hintText: 'Thêm mục checklist (không bắt buộc)',
                    isDense: true,
                    suffixIcon: IconButton(
                      tooltip: 'Thêm mục con',
                      icon: Icon(IconsaxPlusLinear.add, color: primary),
                      onPressed: _addChecklistItem,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.p20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(_isEditing ? 'Lưu thay đổi' : 'Tạo công việc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Thấp';
      case TaskPriority.medium:
        return 'Vừa';
      case TaskPriority.high:
        return 'Cao';
      case TaskPriority.urgent:
        return 'Khẩn cấp';
    }
  }
}

class _DateTimeRow extends StatelessWidget {
  final IconData icon;
  final String emptyLabel;
  final DateTime? value;

  /// Backend chưa hỗ trợ xóa mốc thời gian của Task đã lưu.
  final bool canClear;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateTimeRow({
    required this.icon,
    required this.emptyLabel,
    required this.value,
    required this.canClear,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            onPressed: onPick,
            icon: Icon(icon),
            label: Text(
              value == null
                  ? emptyLabel
                  : DateFormat('HH:mm, dd/MM/yyyy').format(value!),
            ),
          ),
        ),
        if (value != null && canClear)
          IconButton(
            tooltip: 'Bỏ chọn',
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
          ),
      ],
    );
  }
}
