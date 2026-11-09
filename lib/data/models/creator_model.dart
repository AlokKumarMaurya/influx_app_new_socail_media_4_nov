class CreatorModel {
  final int id;
  final String name;
  final String? username;
  final String? avatar;
  final String? cover;
  final String? bio;
  final String? work;
  final String? profileType;
  final Map<String, String?> socialLinks;
  final CreatorStats stats;
  final String relation;

  CreatorModel({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.cover,
    this.bio,
    this.work,
    this.profileType,
    required this.socialLinks,
    required this.stats,
    required this.relation,
  });

  factory CreatorModel.fromJson(Map<String, dynamic> json) {
    return CreatorModel(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'],
      avatar: json['avatar'],
      cover: json['cover'],
      bio: json['bio'],
      work: json['work'],
      profileType: json['profile_type'] ?? 'creator',
      socialLinks: Map<String, String?>.from(json['social_links'] ?? {}),
      stats: CreatorStats.fromJson(json['stats'] ?? {}),
      relation: json['relation'] ?? 'none',
    );
  }
}

class CreatorStats {
  final int followersCount;
  final int followingCount;
  final int postsCount;

  CreatorStats({
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
  });

  factory CreatorStats.fromJson(Map<String, dynamic> json) {
    return CreatorStats(
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
    );
  }
}
