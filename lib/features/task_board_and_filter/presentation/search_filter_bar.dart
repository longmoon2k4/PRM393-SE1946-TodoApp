import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/task_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../providers/task_filter_sort_provider.dart';

class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  late final TextEditingController _controller;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(taskFilterSortProvider).query,
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(taskFilterSortProvider);
    ref.listen<TaskFilterSortState>(taskFilterSortProvider, (previous, next) {
      if (previous?.query != next.query) {
        _searchTimer?.cancel();
        _controller.value = TextEditingValue(
          text: next.query,
          selection: TextSelection.collapsed(offset: next.query.length),
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Tìm công việc...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _controller.clear();
                          _searchTimer?.cancel();
                          ref
                              .read(taskFilterSortProvider.notifier)
                              .setQuery('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) {
                setState(() {});
                _searchTimer?.cancel();
                _searchTimer = Timer(const Duration(milliseconds: 300), () {
                  ref.read(taskFilterSortProvider.notifier).setQuery(value);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Bộ lọc và sắp xếp',
            onPressed: () {
              _searchTimer?.cancel();
              final currentQuery = ref.read(taskFilterSortProvider).query;
              if (currentQuery != _controller.text) {
                ref
                    .read(taskFilterSortProvider.notifier)
                    .setQuery(_controller.text);
              }
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _TaskFilterSheet(),
              );
            },
            icon: Badge(
              isLabelVisible: filters.hasFilters,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskFilterSheet extends ConsumerWidget {
  const _TaskFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(taskFilterSortProvider);
    final tasks = ref
        .watch(coreTasksProvider)
        .where((task) => task.deletedAt == null);
    final tags = tasks.expand((task) => task.tags).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final notifier = ref.read(taskFilterSortProvider.notifier);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bộ lọc công việc',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Trạng thái'),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(
                    label: 'Tất cả',
                    selected: filters.status == null,
                    onSelected: () => notifier.setStatus(null),
                  ),
                  for (final status in TaskStatus.values)
                    _filterChip(
                      label: taskStatusLabel(status),
                      selected: filters.status == status,
                      onSelected: () => notifier.setStatus(status),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Độ ưu tiên'),
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(
                    label: 'Tất cả',
                    selected: filters.priority == null,
                    onSelected: () => notifier.setPriority(null),
                  ),
                  for (final priority in TaskPriority.values)
                    _filterChip(
                      label: taskPriorityLabel(priority),
                      selected: filters.priority == priority,
                      onSelected: () => notifier.setPriority(priority),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Thời hạn'),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in const [
                    (TaskDueFilter.any, 'Tất cả'),
                    (TaskDueFilter.today, 'Hôm nay'),
                    (TaskDueFilter.thisWeek, '7 ngày tới'),
                    (TaskDueFilter.overdue, 'Quá hạn'),
                  ])
                    _filterChip(
                      label: entry.$2,
                      selected: filters.dueFilter == entry.$1,
                      onSelected: () => notifier.setDueFilter(entry.$1),
                    ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Nhãn'),
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip(
                      label: 'Tất cả',
                      selected: filters.tag == null,
                      onSelected: () => notifier.setTag(null),
                    ),
                    for (final tag in tags)
                      _filterChip(
                        label: tag,
                        selected: filters.tag == tag,
                        onSelected: () =>
                            notifier.setTag(filters.tag == tag ? null : tag),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _sectionTitle(context, 'Sắp xếp'),
              DropdownButtonFormField<TaskSortMode>(
                initialValue: filters.sortMode,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.sort),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TaskSortMode.manual,
                    child: Text('Thứ tự thủ công'),
                  ),
                  DropdownMenuItem(
                    value: TaskSortMode.deadline,
                    child: Text('Hạn gần nhất'),
                  ),
                  DropdownMenuItem(
                    value: TaskSortMode.priority,
                    child: Text('Ưu tiên cao trước'),
                  ),
                  DropdownMenuItem(
                    value: TaskSortMode.newest,
                    child: Text('Mới tạo trước'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) notifier.setSortMode(value);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    notifier.clearFilters();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Xóa toàn bộ bộ lọc'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
