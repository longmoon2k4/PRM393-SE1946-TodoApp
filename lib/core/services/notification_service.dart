import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const String _overloadChannelId = 'workload_overload_channel';
  static const String _overloadChannelName = 'Cảnh báo quá tải công việc';
  static const String _deadlineChannelId = 'task_deadline_channel';
  static const String _deadlineChannelName = 'Nhắc nhở hạn chót (Deadline)';

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
        },
      );

      // Request Android 13+ permission
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

  /// Bắn thông báo ngay khi số lượng task vượt quá ngưỡng (Overload Mode)
  static Future<void> showOverloadAlert({
    required int taskCount,
    required int threshold,
  }) async {
    if (!_isInitialized) await init();

    const androidDetails = AndroidNotificationDetails(
      _overloadChannelId,
      _overloadChannelName,
      channelDescription: 'Thông báo khi khối lượng công việc vượt ngưỡng',
      importance: Importance.max,
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
        id: 1001,
        title: '⚠️ Cảnh báo quá tải công việc!',
        body:
            'Bạn đang có $taskCount việc cần làm, vượt ngưỡng cho phép ($threshold). Hãy ưu tiên việc quan trọng trước!',
        notificationDetails: notificationDetails,
        payload: 'overload_alert',
      );
    } catch (e) {
      debugPrint('Failed to show overload notification: $e');
    }
  }

  /// Bắn thông báo khi công việc sắp đến deadline
  static Future<void> showDeadlineAlert({
    required String taskTitle,
    required int hoursLeft,
  }) async {
    if (!_isInitialized) await init();

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

    try {
      await _plugin.show(
        id: taskTitle.hashCode,
        title: '⏰ Nhắc nhở hạn chót!',
        body: 'Công việc "$taskTitle" chỉ còn $hoursLeft giờ nữa là đến hạn!',
        notificationDetails: notificationDetails,
        payload: 'deadline_alert',
      );
    } catch (e) {
      debugPrint('Failed to show deadline notification: $e');
    }
  }

  /// Quét danh sách task để bắn thông báo deadline nếu có task sắp hết hạn trong 24h
  static Future<void> checkAndNotifyApproachingDeadlines(
      List<TaskItem> tasks) async {
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.status != TaskStatus.done &&
          task.status != TaskStatus.cancelled &&
          task.deadline != null) {
        final diff = task.deadline!.difference(now);
        if (diff.isNegative) continue; // Đã quá hạn rồi
        if (diff.inHours <= 24) {
          await showDeadlineAlert(
            taskTitle: task.title,
            hoursLeft: diff.inHours == 0 ? 1 : diff.inHours,
          );
          break; // Tránh spam quá nhiều thông báo cùng 1 lúc
        }
      }
    }
  }

  /// Hủy toàn bộ các thông báo đang được hiển thị / lên lịch (Thường dùng khi Đăng xuất)
  static Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}
