import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_tasks_provider.dart';
import '../providers/task_filter_sort_provider.dart';

class CategoryProjectDrawer extends ConsumerWidget {
  const CategoryProjectDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref
        .watch(coreTasksProvider)
        .where((task) => task.deletedAt == null)
        .toList();
    final filters = ref.watch(taskFilterSortProvider);
    final projectIds =
        tasks
            .map((task) => task.projectId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final categoryIds =
        tasks
            .map((task) => task.categoryId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const ListTile(
              leading: Icon(Icons.folder_open),
              title: Text('Lọc theo project/category'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Mọi project/category'),
              selected: filters.projectId == null && filters.categoryId == null,
              onTap: () {
                final notifier = ref.read(taskFilterSortProvider.notifier);
                notifier.setProjectId(null);
                notifier.setCategoryId(null);
                Navigator.pop(context);
              },
            ),
            if (projectIds.isNotEmpty) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('PROJECT'),
              ),
              for (final id in projectIds)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text('Project ${_shortId(id)}'),
                  subtitle: Text(
                    id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: filters.projectId == id,
                  onTap: () {
                    ref.read(taskFilterSortProvider.notifier).setProjectId(id);
                    Navigator.pop(context);
                  },
                ),
            ],
            if (categoryIds.isNotEmpty) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('CATEGORY'),
              ),
              for (final id in categoryIds)
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text('Category ${_shortId(id)}'),
                  subtitle: Text(
                    id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: filters.categoryId == id,
                  onTap: () {
                    ref.read(taskFilterSortProvider.notifier).setCategoryId(id);
                    Navigator.pop(context);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _shortId(String id) => id.length > 12 ? id.substring(0, 12) : id;
}
