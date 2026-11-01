class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final double orderIndex;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.orderIndex = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'orderIndex': orderIndex,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      orderIndex: (json['orderIndex'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
