class ActivityLog {
  final String id;
  final String taskId;
  final String userId;
  final String actionType; // VD: 'CREATED_TASK', 'CHANGED_STATUS'
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.actionType,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });
}
