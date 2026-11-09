import '../../utils/url_utils.dart';

class FanPageCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  FanPageCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory FanPageCategoryModel.fromJson(Map<String, dynamic> json) {
    return FanPageCategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
    );
  }
}

class FanPageModel {
  final int id;
  final String name;
  final String slug;
  final String? bio;
  final String? description;
  final String? avatar;
  final String? coverPhoto;
  final String? website;
  final String? email;
  final String? phone;
  final String? location;
  final String ctaButtonType;
  final String? ctaButtonUrl;
  final bool isVerified;
  final bool isFeatured;
  final int followersCount;
  final int postsCount;
  final double averageRating;
  final bool isFollowing;
  final bool canManage;
  final String? userRole;
  final bool allowVisitorPosts;
  final FanPageCategoryModel? category;

  int? get categoryId => category?.id;

  FanPageModel({
    required this.id,
    required this.name,
    required this.slug,
    this.bio,
    this.description,
    this.avatar,
    this.coverPhoto,
    this.website,
    this.email,
    this.phone,
    this.location,
    this.ctaButtonType = 'message',
    this.ctaButtonUrl,
    this.isVerified = false,
    this.isFeatured = false,
    this.followersCount = 0,
    this.postsCount = 0,
    this.averageRating = 5.0,
    this.isFollowing = false,
    this.canManage = false,
    this.userRole,
    this.allowVisitorPosts = true,
    this.category,
  });

  factory FanPageModel.fromJson(Map<String, dynamic> json) {
    return FanPageModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      bio: json['bio'],
      description: json['description'],
      avatar: (json['avatar_url'] != null || json['avatar'] != null)
          ? UrlUtils.getFullUrl((json['avatar_url'] ?? json['avatar'])?.toString())
          : null,
      coverPhoto: (json['cover_url'] != null || json['cover_photo'] != null)
          ? UrlUtils.getFullUrl((json['cover_url'] ?? json['cover_photo'])?.toString())
          : null,
      website: json['website'],
      email: json['email'],
      phone: json['phone'],
      location: json['location'],
      ctaButtonType: json['cta_button_type'] ?? 'message',
      ctaButtonUrl: json['cta_button_url'],
      isVerified: json['is_verified'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      averageRating: (json['rating'] != null)
          ? (json['rating'] as num).toDouble()
          : (json['average_rating'] != null
              ? (json['average_rating'] as num).toDouble()
              : 5.0),
      isFollowing: json['is_following'] ?? false,
      canManage: json['can_manage'] ?? false,
      userRole: json['user_role'],
      allowVisitorPosts: json['allow_visitor_posts'] == null || json['allow_visitor_posts'] == true || json['allow_visitor_posts'] == 1,
      category: json['category'] != null
          ? (json['category'] is Map<String, dynamic>
              ? FanPageCategoryModel.fromJson(json['category'])
              : (json['category'] is String
                  ? FanPageCategoryModel(id: 0, name: json['category'], slug: '')
                  : null))
          : null,
    );
  }

  String? get avatarUrl => avatar;
  String? get coverUrl => coverPhoto;
  String? get categoryName => category?.name;
  double get rating => averageRating;

  FanPageModel copyWith({
    int? id,
    String? name,
    String? slug,
    String? bio,
    String? description,
    String? avatar,
    String? coverPhoto,
    String? website,
    String? email,
    String? phone,
    String? location,
    String? ctaButtonType,
    String? ctaButtonUrl,
    bool? isVerified,
    bool? isFeatured,
    int? followersCount,
    int? postsCount,
    double? averageRating,
    bool? isFollowing,
    bool? canManage,
    String? userRole,
    FanPageCategoryModel? category,
  }) {
    return FanPageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      bio: bio ?? this.bio,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      ctaButtonType: ctaButtonType ?? this.ctaButtonType,
      ctaButtonUrl: ctaButtonUrl ?? this.ctaButtonUrl,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      followersCount: followersCount ?? this.followersCount,
      postsCount: postsCount ?? this.postsCount,
      averageRating: averageRating ?? this.averageRating,
      isFollowing: isFollowing ?? this.isFollowing,
      canManage: canManage ?? this.canManage,
      userRole: userRole ?? this.userRole,
      category: category ?? this.category,
    );
  }
}
