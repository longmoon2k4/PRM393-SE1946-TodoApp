import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../../core/models/task_model.dart';
import '../../../core/providers/core_tasks_provider.dart';
import '../../auth_and_dashboard/providers/auth_provider.dart';

final reminderSyncProvider = Provider<void>((ref) {
  void sync() {
    final auth = ref.read(authProvider);
    final isAuthenticated = auth.status == AuthStatus.authenticated;
    unawaited(
      ReminderNotificationService.syncReminders(
        tasks: ref.read(coreTasksProvider),
        isEnabled: isAuthenticated || kDebugMode,
        includeDeadlines: auth.user?.notifyOnDeadline ?? true,
      ),
    );
  }

  ref.listen(coreTasksProvider, (_, _) => sync());
  ref.listen(authProvider, (previous, next) {
    if (previous?.status != next.status ||
        previous?.user?.notifyOnDeadline != next.user?.notifyOnDeadline) {
      sync();
    }
  });
  Future.microtask(sync);
});

class ScheduledReminder {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final String payload;

  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });
}

/// Danh sách thông báo cần có trong tương lai, tính từ danh sách Task hiện tại.
List<ScheduledReminder> buildReminderPlan({
  required List<TaskItem> tasks,
  required DateTime now,
  bool includeDeadlines = true,
}) {
  final plan = <ScheduledReminder>[];

  for (final task in tasks) {
    final isActive = task.deletedAt == null &&
        task.status != TaskStatus.done &&
        task.status != TaskStatus.cancelled;
    if (!isActive) continue;

    final reminderAt = task.reminderAt;
    if (reminderAt != null && reminderAt.isAfter(now)) {
      plan.add(
        ScheduledReminder(
          id: ReminderNotificationService.notificationId(task.id, 0),
          title: '🔔 Nhắc nhở công việc',
          body: task.title,
          scheduledAt: reminderAt,
          payload:
              '${ReminderNotificationService.payloadPrefix}|${task.id}|${reminderAt.toIso8601String()}',
        ),
      );
    }

    final deadline = task.deadline;
    if (includeDeadlines && deadline != null) {
      final warningAt = deadline.subtract(
        ReminderNotificationService.deadlineLeadTime,
      );
      if (warningAt.isAfter(now)) {
        plan.add(
          ScheduledReminder(
            id: ReminderNotificationService.notificationId(task.id, 1),
            title: '⏰ Sắp đến hạn chót',
            body: '"${task.title}" còn 1 giờ nữa là đến hạn.',
            scheduledAt: warningAt,
            payload:
                '${ReminderNotificationService.payloadPrefix}|${task.id}|${warningAt.toIso8601String()}',
          ),
        );
      }
    }
  }

  return plan;
}

class ReminderNotificationService {
  ReminderNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String payloadPrefix = 'reminder';
  static const Duration deadlineLeadTime = Duration(hours: 1);
  static const String _fallbackTimezone = 'Asia/Ho_Chi_Minh';

  static const String _channelId = 'task_reminder_channel';
  static const String _channelName = 'Nhắc nhở công việc đã hẹn giờ';

  static bool _isTimezoneReady = false;
  static Future<void> _syncQueue = Future.value();

  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Id ổn định giữa các lần chạy app, tránh trùng 1001/2001 của NotificationService.
  /// [kind]: 0 là giờ nhắc, 1 là cảnh báo sắp đến hạn.
  static int notificationId(String taskId, int kind) {
    var hash = 0x811C9DC5;
    for (final unit in taskId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return 10000 + (hash & 0x1FFFFFFF) * 2 + kind;
  }

  static Future<void> init() async {
    if (!_isSupported || _isTimezoneReady) return;

    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (e) {
      debugPrint('Không đọc được múi giờ thiết bị, dùng $_fallbackTimezone: $e');
      tz.setLocalLocation(tz.getLocation(_fallbackTimezone));
    }
    _isTimezoneReady = true;
  }

  /// Gọi trước khi người dùng đặt nhắc nhở. Trả về `false` nếu bị từ chối quyền thông báo.
  static Future<bool> requestPermissions() async {
    if (!_isSupported) return false;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final isGranted = await android?.requestNotificationsPermission() ?? false;
      if (!isGranted) return false;

      final canScheduleExact = await android?.canScheduleExactNotifications() ?? false;
      if (!canScheduleExact) {
        await android?.requestExactAlarmsPermission();
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi xin quyền thông báo: $e');
      return false;
    }
  }

  /// Đối chiếu lịch đang có với danh sách Task nên gọi được nhiều lần.
  static Future<void> syncReminders({
    required List<TaskItem> tasks,
    required bool isEnabled,
    bool includeDeadlines = true,
  }) {
    _syncQueue = _syncQueue.then(
      (_) => _sync(tasks, isEnabled, includeDeadlines),
    );
    return _syncQueue;
  }

  static Future<void> _sync(
    List<TaskItem> tasks,
    bool isEnabled,
    bool includeDeadlines,
  ) async {
    if (!_isSupported) return;

    try {
      await init();

      final plan = isEnabled
          ? buildReminderPlan(
              tasks: tasks,
              now: DateTime.now(),
              includeDeadlines: includeDeadlines,
            )
          : const <ScheduledReminder>[];
      final planById = {for (final item in plan) item.id: item};

      final pending = (await _plugin.pendingNotificationRequests())
          .where((p) => p.payload?.startsWith('$payloadPrefix|') ?? false);
      final upToDateIds = <int>{};

      for (final request in pending) {
        final wanted = planById[request.id];
        if (wanted != null &&
            wanted.payload == request.payload &&
            wanted.body == request.body) {
          upToDateIds.add(request.id);
        } else {
          await _plugin.cancel(id: request.id);
        }
      }

      for (final item in plan) {
        if (!upToDateIds.contains(item.id)) await _schedule(item);
      }
    } catch (e) {
      debugPrint('Lỗi đồng bộ lịch nhắc nhở: $e');
    }
  }

  static Future<void> _schedule(ScheduledReminder item) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Thông báo đúng giờ đã hẹn và khi công việc sắp đến hạn',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canScheduleExact = await android?.canScheduleExactNotifications() ?? true;

    await _plugin.zonedSchedule(
      id: item.id,
      title: item.title,
      body: item.body,
      scheduledDate: tz.TZDateTime.from(item.scheduledAt, tz.local),
      notificationDetails: details,
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: item.payload,
    );
  }
}
