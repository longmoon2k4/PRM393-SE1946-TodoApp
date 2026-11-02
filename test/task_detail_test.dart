import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/models/comment_model.dart';
import 'package:todo_app/core/models/subtask_model.dart';
import 'package:todo_app/core/models/task_model.dart';
import 'package:todo_app/core/providers/core_tasks_provider.dart';
import 'package:todo_app/core/services/local_storage_service.dart';
import 'package:todo_app/features/task_detail_and_collab/presentation/task_detail_screen.dart';
import 'package:todo_app/features/task_detail_and_collab/presentation/task_form_bottom_sheet.dart';
import 'package:todo_app/features/task_detail_and_collab/providers/task_crud_provider.dart';

void main() {
  group('TaskComment.fromJson', () {
    test('đọc được dạng lưu trong cache', () {
      final comment = TaskComment.fromJson({
        'id': 'c1',
        'authorId': 'u1',
        'authorName': 'Đăng',
        'content': 'ok',
      });
      expect(comment.authorId, 'u1');
      expect(comment.authorName, 'Đăng');
    });

    test('đọc được dạng backend trả về', () {
      final comment = TaskComment.fromJson({
        'id': 'c1',
        'author': {'id': 'u2', 'name': 'Phúc'},
        'content': 'ok',
      });
      expect(comment.authorId, 'u2');
      expect(comment.authorName, 'Phúc');
    });
  });

  group('TaskCrudController (backend không phản hồi)', () {
    late ProviderContainer container;
    late TaskCrudController crud;

    final seed = TaskItem(
      id: 'task-1',
      title: 'Task',
      createdAt: DateTime(2026),
      subtasks: const [
        SubTask(id: 'a', title: 'A', orderIndex: 0),
        SubTask(id: 'b', title: 'B', orderIndex: 1),
      ],
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      container = ProviderContainer();
      crud = container.read(taskCrudProvider);
      await crud.upsertLocalTask(seed);
    });

    tearDown(() => container.dispose());

    TaskItem current() => container.read(taskByIdProvider('task-1'))!;

    test('tick mục con cập nhật % và báo chưa đồng bộ', () async {
      final isSynced = await crud.toggleSubtask('task-1', 'a');
      expect(isSynced, isFalse);
      expect(current().checklistProgress, 0.5);
    });

    test('thêm mục con nối vào cuối danh sách', () async {
      await crud.addSubtask('task-1', 'C');
      expect(current().subtasks.last.title, 'C');
      expect(current().subtasks.last.orderIndex, 2);
    });

    test('xóa mục con', () async {
      await crud.deleteSubtask('task-1', 'a');
      expect(current().subtasks.map((s) => s.id), ['b']);
    });

    test('kéo thả đánh số lại thứ tự', () async {
      await crud.reorderSubtasks('task-1', seed.subtasks.reversed.toList());
      final subtasks = current().subtasks;
      expect(subtasks.map((s) => s.id), ['b', 'a']);
      expect(subtasks.map((s) => s.orderIndex), [0, 1]);
    });

    test('tạo task kèm checklist vẫn giữ lại khi offline', () async {
      final task = await crud.createTask(
        title: 'Mới',
        priority: TaskPriority.high,
        checklistTitles: const ['X', 'Y'],
      );
      expect(task.id, startsWith('local_'));
      expect(task.subtasks.map((s) => s.title), ['X', 'Y']);
      expect(container.read(coreTasksProvider).any((t) => t.id == task.id), isTrue);
    });
  });

  group('TaskDetailScreen', () {
    testWidgets('mở task mock và tick mục con cập nhật %', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      tester.view.physicalSize = const Size(1080, 3000);
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(null)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TaskDetailScreen(taskId: 'task-2')),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Khởi tạo Flutter Framework'), findsOneWidget);
      expect(find.text('2/3 · 67%'), findsOneWidget);

      await tester.tap(find.text('Chia thư mục Feature-First'));
      await tester.pump();

      expect(find.text('3/3 · 100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox(),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('báo không tìm thấy khi id không tồn tại', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();

      final container = ProviderContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TaskDetailScreen(taskId: 'khong-co')),
        ),
      );
      await tester.pump();

      expect(find.text('Không tìm thấy công việc này.'), findsOneWidget);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox(),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('validateTaskDates', () {
    final now = DateTime(2026, 11, 2, 12);
    final past = now.subtract(const Duration(hours: 1));
    final future = now.add(const Duration(hours: 1));
    final later = now.add(const Duration(hours: 5));

    test('hợp lệ khi không có mốc nào hoặc mốc ở tương lai', () {
      expect(validateTaskDates(now: now), isNull);
      expect(validateTaskDates(now: now, deadline: later), isNull);
    });

    test('chặn deadline trong quá khứ', () {
      expect(
        validateTaskDates(now: now, deadline: past),
        'Deadline không được ở trong quá khứ',
      );
    });

    test('task đã quá hạn vẫn lưu được nếu không đổi deadline', () {
      final overdue = TaskItem(
        id: 't',
        title: 'Task',
        createdAt: past,
        deadline: past,
      );

      expect(validateTaskDates(now: now, deadline: past, original: overdue), isNull);
    });

    test('ngày bắt đầu phải trước deadline', () {
      expect(
        validateTaskDates(now: now, deadline: future, startDate: later),
        'Ngày bắt đầu phải trước deadline',
      );
    });
  });

  group('TaskFormBottomSheet', () {
    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TaskFormBottomSheet())),
        ),
      );
    }

    testWidgets('không cho tạo khi tiêu đề trống', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo công việc'));
      await tester.pump();

      expect(find.text('Tiêu đề không được để trống'), findsOneWidget);
    });
  });
}
