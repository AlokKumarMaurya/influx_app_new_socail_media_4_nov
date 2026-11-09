class ProfileModel {
  final int id;
  final String name;
  final String username;
  final String? avatar;
  final String? cover;
  final String? bio;
  final String? location;
  final String? work;
  final String? education;
  final String? website;
  final Map<String, String?> socialLinks;
  final ProfileStats stats;
  final String
  relation; // 'none', 'friends', 'pending_sent', 'pending_received'
  final bool isOwner;
  final String? profileType;
  final String? badgeIconUrl;
  final String? customBadgeIconUrl;
  final int equippedBadgeCount;
  final List<ProfileBadgeItem> ownedBadges;
  final List<Map<String, dynamic>> customFields;

  ProfileModel({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.cover,
    this.bio,
    this.location,
    this.work,
    this.education,
    this.website,
    required this.socialLinks,
    required this.stats,
    required this.relation,
    required this.isOwner,
    this.profileType,
    this.badgeIconUrl,
    this.customBadgeIconUrl,
    this.equippedBadgeCount = 1,
    this.ownedBadges = const [],
    this.customFields = const [],
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      avatar: json['avatar'],
      cover: json['cover'],
      bio: json['bio'],
      location: json['location'],
      work: json['work'],
      education: json['education'],
      website: json['website'],
      socialLinks: Map<String, String?>.from(json['social_links'] ?? {}),
      stats: ProfileStats.fromJson(json['stats'] ?? {}),
      relation: json['relation'] ?? 'none',
      isOwner: json['is_owner'] ?? false,
      profileType: json['profile_type'] ?? 'user',
      badgeIconUrl: json['badge_icon_url'],
      customBadgeIconUrl: json['custom_badge_icon_url'],
      equippedBadgeCount: json['equipped_badge'] != null ? (json['equipped_badge']['count'] ?? 1) : 1,
      ownedBadges: json['owned_badges'] != null
          ? (json['owned_badges'] as List)
                .map((e) => ProfileBadgeItem.fromJson(e))
                .toList()
          : [],
      customFields: json['custom_fields'] != null && json['custom_fields'] is List
          ? (json['custom_fields'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
          : [],
    );
  }
}

class ProfileBadgeItem {
  final int id;
  final String name;
  final String? description;
  final String iconUrl;
  final bool isEquipped;
  final bool isVisibleOnProfile;
  final bool isPublic;
  final int count;
  final String? validityPeriodLabel;
  final String? expiresAt;
  final bool isExpired;

  ProfileBadgeItem({
    required this.id,
    required this.name,
    this.description,
    required this.iconUrl,
    required this.isEquipped,
    this.isVisibleOnProfile = true,
    this.isPublic = true,
    this.count = 1,
    this.validityPeriodLabel,
    this.expiresAt,
    this.isExpired = false,
  });

  factory ProfileBadgeItem.fromJson(Map<String, dynamic> json) {
    return ProfileBadgeItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Badge',
      description: json['description'],
      iconUrl: json['icon_url'] ?? '',
      isEquipped: json['is_equipped'] ?? false,
      isVisibleOnProfile: json['is_visible_on_profile'] ?? true,
      isPublic: json['is_public'] ?? true,
      count: json['count'] ?? 1,
      validityPeriodLabel: json['validity_period_label'],
      expiresAt: json['expires_at'],
      isExpired: json['is_expired'] ?? false,
    );
  }
}

class ProfileStats {
  final int friendsCount;
  final int followersCount;
  final int followingCount;

  ProfileStats({
    required this.friendsCount,
    required this.followersCount,
    required this.followingCount,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      friendsCount: json['friends_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }
}
