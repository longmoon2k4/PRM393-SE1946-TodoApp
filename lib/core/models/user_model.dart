class UserModel {
  final String id;
  final String name;
  final String email;
  final int backlogThreshold;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.backlogThreshold = 10,
  });
}
