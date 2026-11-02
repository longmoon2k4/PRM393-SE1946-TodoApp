import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/models/subtask_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

class ChecklistSectionWidget extends StatefulWidget {
  final List<SubTask> subtasks;
  final double progress;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onDelete;
  final ValueChanged<List<SubTask>> onReorder;

  const ChecklistSectionWidget({
    super.key,
    required this.subtasks,
    required this.progress,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  State<ChecklistSectionWidget> createState() => _ChecklistSectionWidgetState();
}

class _ChecklistSectionWidgetState extends State<ChecklistSectionWidget> {
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  List<SubTask> get _sorted {
    final items = [...widget.subtasks];
    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  void _submit() {
    final title = _addController.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(title);
    _addController.clear();
  }

  void _handleReorder(int oldIndex, int newIndex) {
    final items = _sorted;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    widget.onReorder(items);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final items = _sorted;
    final doneCount = items.where((s) => s.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Checklist',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '$doneCount/${items.length} · ${(widget.progress * 100).round()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 8,
          percent: widget.progress.clamp(0.0, 1.0),
          barRadius: AppSizes.radiusMax,
          progressColor: primary,
          backgroundColor: primary.withAlpha(30),
          animation: true,
          animateFromLastPercent: true,
        ),
        const SizedBox(height: AppSizes.p8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: items.length,
          onReorderItem: _handleReorder,
          itemBuilder: (context, index) {
            final subtask = items[index];
            return _ChecklistRow(
              key: ValueKey(subtask.id),
              index: index,
              subtask: subtask,
              onToggle: () => widget.onToggle(subtask.id),
              onDelete: () => widget.onDelete(subtask.id),
            );
          },
        ),
        TextField(
          controller: _addController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Thêm mục con...',
            isDense: true,
            prefixIcon: const Icon(IconsaxPlusLinear.add, size: AppSizes.iconNormal),
            suffixIcon: IconButton(
              tooltip: 'Thêm mục con',
              icon: Icon(IconsaxPlusLinear.tick_circle, color: primary),
              onPressed: _submit,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final int index;
  final SubTask subtask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ChecklistRow({
    super.key,
    required this.index,
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(AppSizes.p8),
            child: Icon(
              Icons.drag_indicator,
              size: AppSizes.iconNormal,
              color: AppColors.statusCancelled,
            ),
          ),
        ),
        Checkbox(
          value: subtask.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
              child: Text(
                subtask.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: subtask.isCompleted ? AppColors.statusCancelled : null,
                  decoration:
                      subtask.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Xóa mục con',
          icon: const Icon(
            IconsaxPlusLinear.trash,
            size: 18,
            color: AppColors.statusCancelled,
          ),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
