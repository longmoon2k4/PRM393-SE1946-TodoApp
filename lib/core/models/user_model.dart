class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int backlogThreshold;
  final bool notifyOnOverload;
  final bool notifyOnDeadline;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.backlogThreshold = 10,
    this.notifyOnOverload = true,
    this.notifyOnDeadline = true,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? backlogThreshold,
    bool? notifyOnOverload,
    bool? notifyOnDeadline,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      backlogThreshold: backlogThreshold ?? this.backlogThreshold,
      notifyOnOverload: notifyOnOverload ?? this.notifyOnOverload,
      notifyOnDeadline: notifyOnDeadline ?? this.notifyOnDeadline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'backlogThreshold': backlogThreshold,
      'notifyOnOverload': notifyOnOverload,
      'notifyOnDeadline': notifyOnDeadline,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      backlogThreshold: (json['backlogThreshold'] as num?)?.toInt() ?? 10,
      notifyOnOverload: json['notifyOnOverload'] as bool? ?? true,
      notifyOnDeadline: json['notifyOnDeadline'] as bool? ?? true,
    );
  }
}
