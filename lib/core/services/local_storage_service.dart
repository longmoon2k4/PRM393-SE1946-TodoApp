import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _userKey = 'cached_user_profile';
  static const String _tasksKey = 'cached_task_items';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _themeModeKey = 'app_is_dark_mode';
  static const String _lastOverloadNotifiedTimeKey = 'last_overload_notified_timestamp';
  static const String _lastOverloadNotifiedCountKey = 'last_overload_notified_count';
  static const String _notifiedDeadlinesKey = 'notified_task_deadlines_map';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static bool? getIsDarkMode() {
    return _prefs?.getBool(_themeModeKey);
  }

  static Future<bool> saveIsDarkMode(bool isDark) async {
    return await _prefs?.setBool(_themeModeKey, isDark) ?? false;
  }

  static UserModel? getCachedUser() {
    final raw = _prefs?.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveUser(UserModel user) async {
    final encoded = jsonEncode(user.toJson());
    return await _prefs?.setString(_userKey, encoded) ?? false;
  }

  static Future<bool> clearUser() async {
    return await _prefs?.remove(_userKey) ?? false;
  }

  static List<TaskItem>? getCachedTasks() {
    final raw = _prefs?.getString(_tasksKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedList = jsonDecode(raw) as List<dynamic>;
      return decodedList
          .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveTasks(List<TaskItem> tasks) async {
    final encoded = jsonEncode(tasks.map((t) => t.toJson()).toList());
    return await _prefs?.setString(_tasksKey, encoded) ?? false;
  }

  static DateTime? getLastSyncTime() {
    final raw = _prefs?.getString(_lastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<bool> updateLastSyncTime() async {
    return await _prefs?.setString(
          _lastSyncKey,
          DateTime.now().toIso8601String(),
        ) ??
        false;
  }

  static DateTime? getLastOverloadAlertTime() {
    final raw = _prefs?.getString(_lastOverloadNotifiedTimeKey);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  static int getLastOverloadNotifiedCount() {
    return _prefs?.getInt(_lastOverloadNotifiedCountKey) ?? 0;
  }

  static Future<bool> setLastOverloadAlertTime(DateTime time, int count) async {
    await _prefs?.setInt(_lastOverloadNotifiedCountKey, count);
    return await _prefs?.setString(
          _lastOverloadNotifiedTimeKey,
          time.toIso8601String(),
        ) ??
        false;
  }

  static Future<bool> clearOverloadAlertHistory() async {
    await _prefs?.remove(_lastOverloadNotifiedCountKey);
    return await _prefs?.remove(_lastOverloadNotifiedTimeKey) ?? false;
  }

  static Map<String, String> getNotifiedDeadlines() {
    final raw = _prefs?.getString(_notifiedDeadlinesKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  static Future<bool> saveNotifiedDeadline(String taskId, String milestone) async {
    final map = getNotifiedDeadlines();
    map[taskId] = milestone;
    return await _prefs?.setString(_notifiedDeadlinesKey, jsonEncode(map)) ?? false;
  }

  static Future<bool> clearNotifiedDeadlines() async {
    return await _prefs?.remove(_notifiedDeadlinesKey) ?? false;
  }
}
