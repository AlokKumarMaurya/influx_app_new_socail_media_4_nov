class GroupModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? avatar;
  final String? coverPhoto;
  final String privacy; // 'public', 'private'
  final int memberCount;
  final bool isMember;
  final String? role; // 'admin', 'moderator', 'member', null
  final int? creatorId;

  GroupModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.avatar,
    this.coverPhoto,
    required this.privacy,
    this.memberCount = 0,
    this.isMember = false,
    this.role,
    this.creatorId,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      avatar: json['avatar'],
      coverPhoto: json['cover_photo'],
      privacy: json['privacy'] ?? 'public',
      memberCount: json['member_count'] ?? 0,
      isMember: json['is_member'] ?? false,
      role: json['role'],
      creatorId: json['creator_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'avatar': avatar,
      'cover_photo': coverPhoto,
      'privacy': privacy,
      'member_count': memberCount,
      'is_member': isMember,
      'role': role,
      'creator_id': creatorId,
    };
  }
}
