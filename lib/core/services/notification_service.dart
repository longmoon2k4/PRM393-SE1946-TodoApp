import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';
import '../router/app_router.dart';
import 'local_storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const int overloadNotificationId = 1001;
  static const int deadlineNotificationId = 2001;

  static const String _overloadChannelId = 'workload_overload_channel';
  static const String _overloadChannelName = 'Cảnh báo quá tải công việc';
  static const String _deadlineChannelId = 'task_deadline_channel';
  static const String _deadlineChannelName = 'Nhắc nhở hạn chót công việc';

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
          final payload = response.payload;
          if (payload == 'overload_alert' || payload == 'approaching_list') {
            appRouter.go('/dashboard');
          } else if (payload != null && payload.startsWith('task_')) {
            appRouter.go('/dashboard');
          }
        },
      );

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (platform may not support): $e');
    }
  }

  static Future<void> checkAndNotifyOverload({
    required int taskCount,
    required int threshold,
    required bool isEnabled,
  }) async {
    if (!_isInitialized) await init();

    if (!isEnabled || taskCount <= threshold) {
      if (taskCount <= threshold) {
        await cancelOverloadAlert();
      }
      return;
    }

    final lastAlertTime = LocalStorageService.getLastOverloadAlertTime();
    final lastCount = LocalStorageService.getLastOverloadNotifiedCount();
    final now = DateTime.now();

    final bool isFirstTime = lastAlertTime == null;
    final bool isCooldownElapsed = lastAlertTime != null &&
        now.difference(lastAlertTime).inHours >= 2;
    final bool isSurge = taskCount >= lastCount + 2;

    if (isFirstTime || isCooldownElapsed || isSurge) {
      const androidDetails = AndroidNotificationDetails(
        _overloadChannelId,
        _overloadChannelName,
        channelDescription: 'Thông báo cảnh báo khi khối lượng công việc vượt quá ngưỡng an toàn',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        await _plugin.show(
          id: overloadNotificationId,
          title: '⚠️ Cảnh báo: Khối lượng công việc vượt ngưỡng!',
          body: 'Bạn đang có $taskCount việc dở dang (ngưỡng an toàn: $threshold việc). Hãy ưu tiên dứt điểm việc gấp trước.',
          notificationDetails: notificationDetails,
          payload: 'overload_alert',
        );

        await LocalStorageService.setLastOverloadAlertTime(now, taskCount);
      } catch (e) {
        debugPrint('Failed to show overload notification: $e');
      }
    }
  }

  static Future<void> cancelOverloadAlert() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancel(id: overloadNotificationId);
    } catch (e) {
      debugPrint('Failed to cancel overload alert: $e');
    }
  }

  static Future<void> cancelDeadlineAlert() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancel(id: deadlineNotificationId);
    } catch (e) {
      debugPrint('Failed to cancel deadline alert: $e');
    }
  }

  static Future<void> checkAndNotifyApproachingDeadlines({
    required List<TaskItem> tasks,
    required bool isEnabled,
  }) async {
    if (!_isInitialized) await init();
    if (!isEnabled || tasks.isEmpty) return;

    final now = DateTime.now();
    final notifiedMap = LocalStorageService.getNotifiedDeadlines();

    final pendingTasks = tasks.where((t) =>
        t.deletedAt == null &&
        t.status != TaskStatus.done &&
        t.status != TaskStatus.cancelled &&
        t.deadline != null).toList();

    if (pendingTasks.isEmpty) return;

    pendingTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

    TaskItem? urgentTask;
    final List<TaskItem> approachingTasks = [];

    for (final task in pendingTasks) {
      final diff = task.deadline!.difference(now);
      if (diff.isNegative) continue;

      final hoursLeft = diff.inHours;

      if (hoursLeft <= 3) {
        final lastMilestone = notifiedMap[task.id];
        if (lastMilestone != 'urgent_3h') {
          urgentTask = task;
          break;
        }
      }
      else if (hoursLeft <= 24) {
        final lastMilestone = notifiedMap[task.id];
        if (lastMilestone == null) {
          approachingTasks.add(task);
        }
      }
    }

    const androidDetails = AndroidNotificationDetails(
      _deadlineChannelId,
      _deadlineChannelName,
      channelDescription: 'Thông báo nhắc nhở hạn chót công việc',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    if (urgentTask != null) {
      final diff = urgentTask.deadline!.difference(now);
      final timeStr = diff.inHours <= 0
          ? '${diff.inMinutes.clamp(1, 60)} phút'
          : '${diff.inHours} giờ';

      try {
        await _plugin.show(
          id: deadlineNotificationId,
          title: '⏰ Công việc sắp đến hạn chót!',
          body: 'Công việc "${urgentTask.title}" chỉ còn $timeStr là hết hạn. Hãy tập trung xử lý!',
          notificationDetails: notificationDetails,
          payload: 'task_${urgentTask.id}',
        );

        await LocalStorageService.saveNotifiedDeadline(urgentTask.id, 'urgent_3h');
      } catch (e) {
        debugPrint('Failed to show urgent deadline notification: $e');
      }
      return;
    }

    if (approachingTasks.isNotEmpty) {
      for (final t in approachingTasks) {
        await LocalStorageService.saveNotifiedDeadline(t.id, 'approaching_24h');
      }

      try {
        if (approachingTasks.length == 1) {
          final t = approachingTasks.first;
          final hours = t.deadline!.difference(now).inHours;
          final timeStr = hours <= 0 ? 'hôm nay' : 'trong $hours giờ tới';

          await _plugin.show(
            id: deadlineNotificationId,
            title: '⏰ Nhắc nhở hạn chót hôm nay',
            body: 'Công việc "${t.title}" cần được hoàn tất $timeStr.',
            notificationDetails: notificationDetails,
            payload: 'task_${t.id}',
          );
        } else {
          final firstTitle = approachingTasks.first.title;
          await _plugin.show(
            id: deadlineNotificationId,
            title: '⏰ Bạn có ${approachingTasks.length} công việc sắp đến hạn',
            body: 'Ưu tiên: "$firstTitle" cùng ${approachingTasks.length - 1} công việc khác cần hoàn tất trong 24 giờ tới.',
            notificationDetails: notificationDetails,
            payload: 'approaching_list',
          );
        }
      } catch (e) {
        debugPrint('Failed to show approaching deadline notification: $e');
      }
    }
  }

  static Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancelAll();
      await LocalStorageService.clearOverloadAlertHistory();
      await LocalStorageService.clearNotifiedDeadlines();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}
