import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/models/comment_model.dart';
import 'package:todo_app/core/models/subtask_model.dart';
import 'package:todo_app/core/models/task_model.dart';
import 'package:todo_app/core/models/user_model.dart';
import 'package:todo_app/core/providers/core_tasks_provider.dart';
import 'package:todo_app/core/services/local_storage_service.dart';
import 'package:todo_app/core/services/task_api_service.dart';
import 'package:todo_app/core/widgets/contextual_fab.dart';
import 'package:todo_app/features/task_detail_and_collab/presentation/comment_timeline_widget.dart';
import 'package:todo_app/features/task_detail_and_collab/presentation/task_detail_screen.dart';
import 'package:todo_app/features/task_detail_and_collab/presentation/task_form_bottom_sheet.dart';
import 'package:todo_app/features/task_detail_and_collab/providers/comment_author_provider.dart';
import 'package:todo_app/features/task_detail_and_collab/providers/reminder_notification_service.dart';
import 'package:todo_app/features/task_detail_and_collab/providers/task_crud_provider.dart';
import 'package:todo_app/features/task_detail_and_collab/providers/task_option_provider.dart';
import 'package:todo_app/features/task_detail_and_collab/providers/task_permission_provider.dart';

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
      expect(
        container.read(coreTasksProvider).any((t) => t.id == task.id),
        isTrue,
      );
    });
  });

  group('Gửi bình luận lên backend', () {
    final seed = TaskItem(
      id: 'task-1',
      title: 'Task',
      createdAt: DateTime(2026),
    );

    Future<ProviderContainer> setUpWith(CommentAuthorSync sync) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      final container = ProviderContainer(
        overrides: [commentAuthorSyncProvider.overrideWithValue(sync)],
      );
      addTearDown(container.dispose);
      await container.read(taskCrudProvider).upsertLocalTask(seed);
      return container;
    }

    test('đồng bộ người bình luận và nhớ id backend', () async {
      final synced = <UserModel>[];
      final container = await setUpWith((user) async {
        synced.add(user);
        return 'backend-id';
      });

      final isSynced = await container
          .read(taskCrudProvider)
          .addComment('task-1', author: _member, content: 'Xin chào');

      expect(synced.single.id, _member.id);
      expect(container.read(commentAuthorIdsProvider), {
        _member.id: 'backend-id',
      });
      // Server task không phản hồi nên bình luận vẫn chờ trên máy.
      expect(isSynced, isFalse);
      final comment = container
          .read(taskByIdProvider('task-1'))!
          .comments
          .single;
      expect(comment.id, startsWith('local_'));
      expect(comment.content, 'Xin chào');
    });

    test('lỗi đồng bộ người bình luận vẫn giữ bình luận trên máy', () async {
      final container = await setUpWith(
        (_) async => throw Exception('offline'),
      );

      await container
          .read(taskCrudProvider)
          .addComment('task-1', author: _member, content: 'Offline');

      expect(container.read(commentAuthorIdsProvider), isEmpty);
      final comment = container
          .read(taskByIdProvider('task-1'))!
          .comments
          .single;
      expect(comment.authorId, _member.id);
      expect(comment.authorName, _member.name);
    });

    test('tải lại khi server tắt không làm mất bình luận đang chờ', () async {
      final container = await setUpWith((_) async => 'backend-id');
      final crud = container.read(taskCrudProvider);
      await crud.addComment('task-1', author: _member, content: 'Chờ gửi');

      await crud.refreshComments('task-1', author: _member);

      final comments = container.read(taskByIdProvider('task-1'))!.comments;
      expect(comments.map((c) => c.content), ['Chờ gửi']);
    });

    test('giao việc đưa thành viên lên backend và dùng id backend', () async {
      final synced = <UserModel>[];
      final container = await setUpWith((user) async {
        synced.add(user);
        return 'backend-${user.id}';
      });
      final member = TeamRoster.members.first;

      final isSynced = await container
          .read(taskCrudProvider)
          .assignTask('task-1', member.toUser());

      expect(synced.single.email, member.email);
      expect(
        container.read(taskByIdProvider('task-1'))!.assigneeId,
        'backend-${member.id}',
      );
      // Server task không phản hồi nên việc giao mới lưu trên máy.
      expect(isSynced, isFalse);
    });
  });

  group('Tạo dự án và danh mục', () {
    final seed = TaskItem(
      id: 'task-1',
      title: 'Task',
      createdAt: DateTime(2026),
    );

    Future<ProviderContainer> setUpWith({
      CreateNamedOption? project,
      CreateNamedOption? category,
    }) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      final container = ProviderContainer(
        overrides: [
          if (project != null) createProjectProvider.overrideWithValue(project),
          if (category != null)
            createCategoryProvider.overrideWithValue(category),
        ],
      );
      // Chờ lần đồng bộ nền của danh sách task xong rồi mới hủy container.
      addTearDown(() async {
        await container.read(coreTasksProvider.notifier).syncFromBackend();
        container.dispose();
      });
      await container.read(taskCrudProvider).upsertLocalTask(seed);
      return container;
    }

    test('tạo dự án mới rồi đưa task vào dự án đó', () async {
      final container = await setUpWith(
        project: (name) async => NamedOption(id: 'p-1', name: name),
      );

      final isCreated = await container
          .read(taskCrudProvider)
          .createProjectFor('task-1', 'Đồ án PRM');

      expect(isCreated, isTrue);
      expect(container.read(taskByIdProvider('task-1'))!.projectId, 'p-1');
    });

    test('tạo danh mục mới rồi gán cho task', () async {
      final container = await setUpWith(
        category: (name) async => NamedOption(id: 'c-1', name: name),
      );

      await container
          .read(taskCrudProvider)
          .createCategoryFor('task-1', 'Backend');

      expect(container.read(taskByIdProvider('task-1'))!.categoryId, 'c-1');
    });

    test('server lỗi thì báo thất bại và giữ nguyên task', () async {
      final container = await setUpWith(
        project: (_) async => throw Exception('offline'),
      );

      final isCreated = await container
          .read(taskCrudProvider)
          .createProjectFor('task-1', 'Dự án');

      expect(isCreated, isFalse);
      expect(container.read(taskByIdProvider('task-1'))!.projectId, isNull);
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

    testWidgets('ẩn nút trạng thái khi bàn phím mở để không che ô bình luận', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      tester.view.physicalSize = const Size(1080, 3000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);

      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(null)],
      );
      // Nút trạng thái chỉ hiện với người được giao việc.
      await container
          .read(taskCrudProvider)
          .upsertLocalTask(
            TaskItem(
              id: 'kb-task',
              title: 'Việc của tôi',
              createdAt: DateTime(2026),
              assigneeId: debugCommentAuthor.id,
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TaskDetailScreen(taskId: 'kb-task')),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(ContextualFab), findsOneWidget);

      // Chờ hiệu ứng ẩn/hiện FAB của Scaffold chạy xong.
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ContextualFab), findsNothing);

      tester.view.resetViewInsets();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ContextualFab), findsOneWidget);

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

  group('formatCommentTime', () {
    final now = DateTime(2026, 11, 2, 12);

    test('hiển thị đúng từng mốc', () {
      String format(Duration ago) =>
          formatCommentTime(now.subtract(ago), now: now);

      expect(format(const Duration(seconds: 20)), 'Vừa xong');
      expect(format(const Duration(minutes: 5)), '5 phút trước');
      expect(format(const Duration(hours: 2)), '2 giờ trước');
      expect(format(const Duration(days: 3)), '3 ngày trước');
      expect(format(const Duration(days: 30)), '03/10/2026');
    });

    test('giờ máy chủ lệch nhẹ về tương lai vẫn là Vừa xong', () {
      expect(
        formatCommentTime(now.add(const Duration(minutes: 1)), now: now),
        'Vừa xong',
      );
    });
  });

  group('CommentTimelineWidget', () {
    final comments = [
      TaskComment(
        id: 'c2',
        authorId: 'me',
        authorName: 'Đăng',
        content: 'Của mình',
        createdAt: DateTime.now(),
      ),
      TaskComment(
        id: 'c1',
        authorId: 'other',
        authorName: 'Phúc',
        content: 'Của người khác',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    Future<List<String>> pump(
      WidgetTester tester, {
      String? userId = 'me',
    }) async {
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTimelineWidget(
              comments: comments,
              currentUserId: userId,
              onSend: sent.add,
            ),
          ),
        ),
      );
      return sent;
    }

    testWidgets('của mình bên phải, người khác bên trái, cũ ở trên', (
      tester,
    ) async {
      await pump(tester);

      final mine = tester.getCenter(find.text('Của mình'));
      final other = tester.getCenter(find.text('Của người khác'));
      final center = tester.getCenter(find.byType(Scaffold));

      expect(mine.dx, greaterThan(center.dx));
      expect(other.dx, lessThan(center.dx));
      expect(other.dy, lessThan(mine.dy));
      expect(find.text('2 giờ trước'), findsOneWidget);
      expect(find.text('Phúc'), findsOneWidget);
      expect(find.text('Bạn'), findsOneWidget);
      expect(find.text('Đăng'), findsNothing);
    });

    testWidgets('bình luận thiếu tên vẫn hiện người viết', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTimelineWidget(
              comments: [
                TaskComment(
                  id: 'c3',
                  authorId: 'other',
                  authorName: '  ',
                  content: 'Không rõ tên',
                  createdAt: DateTime.now(),
                ),
              ],
              currentUserId: 'me',
              onSend: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Người dùng'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
    });

    testWidgets('gửi bình luận đã bỏ khoảng trắng và xóa ô nhập', (
      tester,
    ) async {
      final sent = await pump(tester);

      await tester.enterText(find.byType(TextField), '  Xin chào  ');
      await tester.tap(find.byTooltip('Gửi bình luận'));
      await tester.pump();

      expect(sent, ['Xin chào']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('chưa đăng nhập thì không gửi được', (tester) async {
      await pump(tester, userId: null);

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(find.text('Đăng nhập để bình luận'), findsOneWidget);
    });
  });

  group('buildReminderPlan', () {
    final now = DateTime(2026, 11, 2, 12);

    TaskItem task({
      String id = 't1',
      TaskStatus status = TaskStatus.todo,
      DateTime? reminderAt,
      DateTime? deadline,
      DateTime? deletedAt,
    }) {
      return TaskItem(
        id: id,
        title: 'Task',
        status: status,
        createdAt: now,
        reminderAt: reminderAt,
        deadline: deadline,
        deletedAt: deletedAt,
      );
    }

    List<ScheduledReminder> plan(TaskItem item) =>
        buildReminderPlan(tasks: [item], now: now);

    test('đặt lịch cho giờ nhắc và 1 giờ trước deadline', () {
      final items = plan(
        task(
          reminderAt: now.add(const Duration(hours: 1)),
          deadline: now.add(const Duration(hours: 5)),
        ),
      );

      expect(items.map((r) => r.scheduledAt), [
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 4)),
      ]);
      expect(items.map((r) => r.id).toSet().length, 2);
    });

    test('bỏ qua mốc đã qua', () {
      expect(
        plan(
          task(
            reminderAt: now.subtract(const Duration(minutes: 1)),
            deadline: now.add(const Duration(minutes: 30)),
          ),
        ),
        isEmpty,
      );
    });

    test('bỏ qua task đã xong, đã hủy hoặc đã xóa', () {
      final reminderAt = now.add(const Duration(hours: 1));

      expect(
        plan(task(status: TaskStatus.done, reminderAt: reminderAt)),
        isEmpty,
      );
      expect(
        plan(task(status: TaskStatus.cancelled, reminderAt: reminderAt)),
        isEmpty,
      );
      expect(plan(task(deletedAt: now, reminderAt: reminderAt)), isEmpty);
    });

    test('tắt nhắc deadline vẫn giữ giờ nhắc', () {
      final items = buildReminderPlan(
        tasks: [
          task(
            reminderAt: now.add(const Duration(hours: 1)),
            deadline: now.add(const Duration(hours: 5)),
          ),
        ],
        now: now,
        includeDeadlines: false,
      );

      expect(items.map((r) => r.scheduledAt), [
        now.add(const Duration(hours: 1)),
      ]);
    });

    test('id thông báo ổn định, dương và không trùng id có sẵn', () {
      final id = ReminderNotificationService.notificationId('task-1', 0);

      expect(ReminderNotificationService.notificationId('task-1', 0), id);
      expect(ReminderNotificationService.notificationId('task-1', 1), id + 1);
      expect(id, greaterThan(2001));
      expect(id, lessThan(1 << 31));
    });
  });

  group('validateTaskDates', () {
    final now = DateTime(2026, 11, 2, 12);
    final past = now.subtract(const Duration(hours: 1));
    final future = now.add(const Duration(hours: 1));
    final later = now.add(const Duration(hours: 5));

    test('hợp lệ khi không có mốc nào hoặc mốc ở tương lai', () {
      expect(validateTaskDates(now: now), isNull);
      expect(
        validateTaskDates(now: now, deadline: later, reminderAt: future),
        isNull,
      );
    });

    test('chặn deadline và giờ nhắc trong quá khứ', () {
      expect(
        validateTaskDates(now: now, deadline: past),
        'Deadline không được ở trong quá khứ',
      );
      expect(
        validateTaskDates(now: now, reminderAt: past),
        'Giờ nhắc phải ở trong tương lai',
      );
    });

    test('task đã quá hạn vẫn lưu được nếu không đổi deadline', () {
      final overdue = TaskItem(
        id: 't',
        title: 'Task',
        createdAt: past,
        deadline: past,
      );

      expect(
        validateTaskDates(now: now, deadline: past, original: overdue),
        isNull,
      );
    });

    test('giờ nhắc và ngày bắt đầu phải trước deadline', () {
      expect(
        validateTaskDates(now: now, deadline: future, reminderAt: later),
        'Giờ nhắc phải trước deadline',
      );
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

    testWidgets('thành viên không mở được form', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(_member)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => TaskFormBottomSheet.show(context),
                  child: const Text('Mở form'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở form'));
      await tester.pump();

      expect(find.byType(TaskFormBottomSheet), findsNothing);
      expect(
        find.text('Chỉ leader mới được tạo hoặc sửa công việc.'),
        findsOneWidget,
      );
    });
  });

  group('Phân quyền leader', () {
    final task = TaskItem(
      id: 't',
      title: 'Task',
      createdAt: DateTime(2026),
      assigneeId: 'u-member',
    );

    test('leader quản lý nhưng không đẩy trạng thái việc của người khác', () {
      final p = resolveTaskPermissions(
        task: task,
        currentUserId: 'u-leader',
        isLeader: true,
      );
      expect(p.canManage, isTrue);
      expect(p.canWork, isTrue);
      expect(p.canProgress, isFalse);
    });

    test('xem với vai trò thành viên đổi người dùng và quyền', () async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      final container = ProviderContainer();
      addTearDown(() async {
        await container.read(coreTasksProvider.notifier).syncFromBackend();
        container.dispose();
      });
      final member = TeamRoster.members.first;
      await container
          .read(taskCrudProvider)
          .upsertLocalTask(
            TaskItem(
              id: 'va-task',
              title: 'Việc',
              createdAt: DateTime(2026),
              assigneeId: member.id,
            ),
          );

      container.read(debugViewAsProvider.notifier).viewAs(member.toUser());

      expect(container.read(currentUserProvider)?.id, member.id);
      expect(container.read(isLeaderProvider), isFalse);
      final p = container.read(taskPermissionsProvider('va-task'));
      expect(p.canManage, isFalse);
      expect(p.canProgress, isTrue);
    });

    test('leader tự giao việc cho mình thì được đẩy trạng thái', () {
      final p = resolveTaskPermissions(
        task: task,
        currentUserId: 'u-member',
        isLeader: true,
      );
      expect(p.canProgress, isTrue);
    });

    test('thành viên chỉ làm task được giao cho mình', () {
      final assigned = resolveTaskPermissions(
        task: task,
        currentUserId: 'u-member',
        isLeader: false,
      );
      expect(assigned.canManage, isFalse);
      expect(assigned.canWork, isTrue);
      expect(assigned.canProgress, isTrue);

      final other = resolveTaskPermissions(
        task: task,
        currentUserId: 'u-other',
        isLeader: false,
      );
      expect(other.canManage, isFalse);
      expect(other.canWork, isFalse);
      expect(other.canProgress, isFalse);
    });

    test('thành viên nhận việc khi backend lưu mình dưới id khác', () {
      final p = resolveTaskPermissions(
        task: task,
        currentUserId: 'firebase-uid',
        isLeader: false,
        otherOwnIds: {'u-member'},
      );
      expect(p.canWork, isTrue);
    });

    test('tìm thành viên theo id trên máy hoặc id backend', () {
      final first = TeamRoster.members.first;
      expect(TeamRoster.findMember(first.id), first);
      expect(
        TeamRoster.findMember('backend-x', backendIds: {first.id: 'backend-x'}),
        first,
      );
      expect(TeamRoster.findMember('khong-co'), isNull);
    });

    test('nhận leader theo email, không phân biệt hoa thường', () {
      final leaderEmail = TeamRoster.leaderEmails.first;
      expect(
        isLeaderUser(
          UserModel(
            id: 'x',
            name: 'L',
            email: ' ${leaderEmail.toUpperCase()} ',
          ),
        ),
        isTrue,
      );
      expect(isLeaderUser(_member), isFalse);
    });

    Future<ProviderContainer> pumpDetail(
      WidgetTester tester, {
      required String? assigneeId,
    }) async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
      tester.view.physicalSize = const Size(1080, 3000);
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [currentUserProvider.overrideWithValue(_member)],
      );
      await container
          .read(taskCrudProvider)
          .upsertLocalTask(
            TaskItem(
              id: 'perm-task',
              title: 'Việc được giao',
              createdAt: DateTime(2026),
              assigneeId: assigneeId,
              subtasks: const [SubTask(id: 's', title: 'Mục A', orderIndex: 0)],
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: TaskDetailScreen(taskId: 'perm-task')),
        ),
      );
      await tester.pump();
      return container;
    }

    Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const SizedBox()),
      );
      await tester.pump(const Duration(seconds: 5));
    }

    testWidgets('thành viên được giao: tick được nhưng không sửa được', (
      tester,
    ) async {
      final container = await pumpDetail(tester, assigneeId: _member.id);

      expect(find.byTooltip('Chỉnh sửa'), findsNothing);
      expect(find.byTooltip('Xóa mục con'), findsNothing);
      expect(find.text('Thêm mục con...'), findsNothing);
      expect(find.text('Giao việc'), findsNothing);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).onChanged,
        isNotNull,
      );

      await unmount(tester, container);
    });

    testWidgets('thành viên không được giao: chỉ xem', (tester) async {
      final container = await pumpDetail(tester, assigneeId: 'u-other');

      expect(find.byTooltip('Chỉnh sửa'), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(
        find.text(
          'Chỉ leader và người được giao mới thay đổi được công việc này.',
        ),
        findsOneWidget,
      );

      await unmount(tester, container);
    });
  });
}

const _member = UserModel(
  id: 'u-member',
  name: 'Thành viên',
  email: 'member@example.com',
);
