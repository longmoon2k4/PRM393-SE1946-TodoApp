enum ProjectRole { owner, admin, member, viewer }

class ProjectMember {
  final String userId;
  final ProjectRole role;
  final DateTime joinedAt;

  const ProjectMember({
    required this.userId,
    this.role = ProjectRole.member,
    required this.joinedAt,
  });
}

class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime? deletedAt; // Xóa mềm dự án
  final List<ProjectMember> members;

  const ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    this.deletedAt,
    this.members = const [],
  });
}
