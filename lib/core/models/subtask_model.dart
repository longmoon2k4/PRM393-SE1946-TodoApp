class SubTask {
  final String id;
  final String title;
  final bool isCompleted;
  final double orderIndex; // Phục vụ tính năng kéo thả sắp xếp

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.orderIndex = 0.0,
  });
}
