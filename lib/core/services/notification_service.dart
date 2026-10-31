import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';
import '../router/app_router.dart';
import 'local_storage_service.dart';

/// Dịch vụ quản lý thông báo cục bộ thông minh theo chuẩn Enterprise:
/// - Chống spam (Anti-Spam Throttling): Giới hạn tần suất và chỉ gửi khi chuyển trạng thái hoặc có biến động lớn.
/// - Phân cấp hạn chót (Milestone Deadlines): Phân biệt mốc 24h và mốc khẩn cấp 3h, tự động gộp thông báo khi có nhiều việc.
/// - Tự động thu hồi (Auto-Dismissal): Khi người dùng hoàn thành việc và thoát khỏi quá tải, thông báo cũ tự động biến mất.
/// - Tôn trọng tuyệt đối quyền riêng tư: Tắt thông báo trong Cài đặt sẽ lập tức hủy toàn bộ thông báo đang chờ.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Notification IDs
  static const int overloadNotificationId = 1001;
  static const int deadlineNotificationId = 2001;

  // Channels
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

  /// Kiểm tra và cảnh báo Quá tải thông minh:
  /// - Chỉ gửi khi người dùng bật thông báo quá tải.
  /// - Tự động xóa thông báo khi công việc giảm xuống dưới ngưỡng an toàn.
  /// - Giới hạn cooldown tối thiểu 2 giờ hoặc khi khối lượng việc tăng vọt (+2 việc trở lên).
  static Future<void> checkAndNotifyOverload({
    required int taskCount,
    required int threshold,
    required bool isEnabled,
  }) async {
    if (!_isInitialized) await init();

    // Nếu người dùng tắt thông báo hoặc đã hết quá tải, tự động thu hồi thông báo trên thanh trạng thái
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

    // Chỉ bắn thông báo khi thỏa mãn điều kiện thông minh, tránh spam liên tục
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

  /// Thu hồi thông báo quá tải khỏi thanh thông báo hệ thống
  static Future<void> cancelOverloadAlert() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancel(id: overloadNotificationId);
    } catch (e) {
      debugPrint('Failed to cancel overload alert: $e');
    }
  }

  /// Thu hồi thông báo hạn chót
  static Future<void> cancelDeadlineAlert() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancel(id: deadlineNotificationId);
    } catch (e) {
      debugPrint('Failed to cancel deadline alert: $e');
    }
  }

  /// Quét thông minh danh sách công việc để nhắc nhở hạn chót đúng thực tế:
  /// - Phân loại 2 mốc thời gian: Sắp đến hạn (dưới 24h) và Khẩn cấp (dưới 3h).
  /// - Chống trùng lặp (Deduplication): Mỗi mốc của 1 công việc chỉ thông báo đúng 1 lần.
  /// - Gộp thông báo (Batching): Khi có nhiều việc cùng đến hạn, tổng hợp thông minh thay vì spam từng thông báo.
  static Future<void> checkAndNotifyApproachingDeadlines({
    required List<TaskItem> tasks,
    required bool isEnabled,
  }) async {
    if (!_isInitialized) await init();
    if (!isEnabled || tasks.isEmpty) return;

    final now = DateTime.now();
    final notifiedMap = LocalStorageService.getNotifiedDeadlines();

    // Lọc công việc đang hoạt động và có hạn chót trong tương lai
    final pendingTasks = tasks.where((t) =>
        t.deletedAt == null &&
        t.status != TaskStatus.done &&
        t.status != TaskStatus.cancelled &&
        t.deadline != null).toList();

    if (pendingTasks.isEmpty) return;

    // Sắp xếp theo hạn chót gần nhất trước
    pendingTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

    TaskItem? urgentTask;
    final List<TaskItem> approachingTasks = [];

    for (final task in pendingTasks) {
      final diff = task.deadline!.difference(now);
      if (diff.isNegative) continue; // Đã quá hạn

      final hoursLeft = diff.inHours;

      // Mốc 1: Khẩn cấp (<= 3 giờ)
      if (hoursLeft <= 3) {
        final lastMilestone = notifiedMap[task.id];
        if (lastMilestone != 'urgent_3h') {
          urgentTask = task;
          break; // Ưu tiên việc khẩn cấp nhất
        }
      }
      // Mốc 2: Sắp đến hạn trong ngày (<= 24 giờ)
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

    // 1. Nếu có việc rất gấp (< 3 giờ): Bắn cảnh báo ưu tiên cao nhất
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

    // 2. Nếu có việc sắp đến hạn trong vòng 24h và chưa được nhắc
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
          // Gộp nhiều việc thành 1 thông báo súc tích, chuyên nghiệp
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

  /// Hủy toàn bộ các thông báo đang được hiển thị / lên lịch (Thường dùng khi Đăng xuất)
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
