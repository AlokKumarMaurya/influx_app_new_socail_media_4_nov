class UserModel {
  final int id;
  final String name;
  final String? username;
  final String? email;
  final String? avatar;
  final String? phone;
  final String? gender;
  final DateTime? birthDate;
  final String? bio;
  final String? country;
  final String? state;
  final String? city;
  final String? zipCode;
  final String? address;
  final String? work;
  final String? education;
  final String? website;
  final String? location;

  // Notification settings
  final bool notifyFriendRequests;
  final bool notifyMessages;
  final bool notifyComments;
  final bool notifyLikes;
  final bool notifyShares;
  final bool notifyGroupActivity;
  final bool notifyMentions;
  final bool notifyEmail;

  // Privacy settings
  final String privacyProfile;
  final String privacyPosts;
  final String privacyFriendsList;
  final String privacyPhotos;
  final bool privacySearchVisible;
  final bool privacyOnlineStatus;
  final String? kycStatus;
  final String? profileType;
  final String? badgeIconUrl;
  final String? customBadgeIconUrl;
  final bool isBadgePrivate;
  final bool _rawIsAdmin;
  final Map<String, dynamic> customFieldsData;
  final Map<String, dynamic> profileFieldPrivacy;
  final String messagePrivacy;
  final bool messageSpamFilter;
  final String? messageSpamKeywords;

  bool get isAdmin => _rawIsAdmin || profileType == 'admin';

  String getFieldPrivacy(String field) {
    if (profileFieldPrivacy.containsKey(field) &&
        ['public', 'friends', 'only_me'].contains(profileFieldPrivacy[field])) {
      return profileFieldPrivacy[field].toString();
    }
    const sensitive = ['email', 'phone', 'birth_date', 'address', 'zip_code'];
    return sensitive.contains(field) ? 'only_me' : 'public';
  }

  UserModel({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.avatar,
    this.phone,
    this.gender,
    this.birthDate,
    this.bio,
    this.country,
    this.state,
    this.city,
    this.zipCode,
    this.address,
    this.work,
    this.education,
    this.website,
    this.location,
    this.customFieldsData = const {},
    this.profileFieldPrivacy = const {},
    this.notifyFriendRequests = true,
    this.notifyMessages = true,
    this.notifyComments = true,
    this.notifyLikes = true,
    this.notifyShares = true,
    this.notifyGroupActivity = true,
    this.notifyMentions = true,
    this.notifyEmail = false,
    this.privacyProfile = 'public',
    this.privacyPosts = 'public',
    this.privacyFriendsList = 'public',
    this.privacyPhotos = 'public',
    this.privacySearchVisible = true,
    this.privacyOnlineStatus = true,
    this.kycStatus,
    this.profileType = 'user',
    this.badgeIconUrl,
    this.customBadgeIconUrl,
    this.isBadgePrivate = false,
    this.messagePrivacy = 'requests',
    this.messageSpamFilter = true,
    this.messageSpamKeywords,
    bool isAdmin = false,
  }) : _rawIsAdmin = isAdmin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
      avatar: json['avatar'],
      phone: json['phone'],
      gender: json['gender'],
      birthDate: (json['birth_date'] != null && json['birth_date'].toString().trim().isNotEmpty)
          ? DateTime.tryParse(json['birth_date'].toString())
          : null,
      bio: json['bio'],
      country: json['country'],
      state: json['state'],
      city: json['city'],
      zipCode: json['zip_code'],
      address: json['address'],
      work: json['work'],
      education: json['education'],
      website: json['website'],
      location: json['location'],
      notifyFriendRequests: json['notify_friend_requests'] ?? true,
      notifyMessages: json['notify_messages'] ?? true,
      notifyComments: json['notify_comments'] ?? true,
      notifyLikes: json['notify_likes'] ?? true,
      notifyShares: json['notify_shares'] ?? true,
      notifyGroupActivity: json['notify_group_activity'] ?? true,
      notifyMentions: json['notify_mentions'] ?? true,
      notifyEmail: json['notify_email'] ?? false,
      privacyProfile: json['privacy_profile'] ?? 'public',
      privacyPosts: json['privacy_posts'] ?? 'public',
      privacyFriendsList: json['privacy_friends_list'] ?? 'public',
      privacyPhotos: json['privacy_photos'] ?? 'public',
      privacySearchVisible: json['privacy_search_visible'] ?? true,
      privacyOnlineStatus: json['privacy_online_status'] ?? true,
      kycStatus: json['kyc_status'],
      profileType: json['profile_type'] ?? 'user',
      badgeIconUrl: json['badge_icon_url'],
      customBadgeIconUrl: json['custom_badge_icon_url'],
      isBadgePrivate: json['is_badge_private'] ?? false,
      isAdmin: json['is_admin'] == true || json['role'] == 'admin' || json['user_type'] == 'admin' || json['profile_type'] == 'admin',
      customFieldsData: json['custom_fields_data'] != null && json['custom_fields_data'] is Map
          ? Map<String, dynamic>.from(json['custom_fields_data'])
          : {},
      profileFieldPrivacy: json['profile_field_privacy'] != null && json['profile_field_privacy'] is Map
          ? Map<String, dynamic>.from(json['profile_field_privacy'])
          : {},
      messagePrivacy: json['message_privacy'] ?? 'requests',
      messageSpamFilter: json['message_spam_filter'] ?? true,
      messageSpamKeywords: json['message_spam_keywords'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().split('T')[0],
      'bio': bio,
      'country': country,
      'state': state,
      'city': city,
      'zip_code': zipCode,
      'address': address,
      'work': work,
      'education': education,
      'website': website,
      'location': location,
      'message_privacy': messagePrivacy,
      'message_spam_filter': messageSpamFilter,
      'message_spam_keywords': messageSpamKeywords,
      'notify_friend_requests': notifyFriendRequests,
      'notify_messages': notifyMessages,
      'notify_comments': notifyComments,
      'notify_likes': notifyLikes,
      'notify_shares': notifyShares,
      'notify_group_activity': notifyGroupActivity,
      'notify_mentions': notifyMentions,
      'notify_email': notifyEmail,
      'privacy_profile': privacyProfile,
      'privacy_posts': privacyPosts,
      'privacy_friends_list': privacyFriendsList,
      'privacy_photos': privacyPhotos,
      'privacy_search_visible': privacySearchVisible,
      'privacy_online_status': privacyOnlineStatus,
      'kyc_status': kycStatus,
      'profile_type': profileType,
      'custom_fields_data': customFieldsData,
      'profile_field_privacy': profileFieldPrivacy,
    };
  }

  UserModel copyWith({
    String? name,
    String? username,
    String? email,
    String? avatar,
    String? phone,
    String? gender,
    DateTime? birthDate,
    String? bio,
    String? country,
    String? state,
    String? city,
    String? zipCode,
    String? address,
    String? work,
    String? education,
    String? website,
    String? location,
    bool? notifyFriendRequests,
    bool? notifyMessages,
    bool? notifyComments,
    bool? notifyLikes,
    bool? notifyShares,
    bool? notifyGroupActivity,
    bool? notifyMentions,
    bool? notifyEmail,
    String? privacyProfile,
    String? privacyPosts,
    String? privacyFriendsList,
    String? privacyPhotos,
    bool? privacySearchVisible,
    bool? privacyOnlineStatus,
    String? kycStatus,
    String? profileType,
    Map<String, dynamic>? customFieldsData,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      address: address ?? this.address,
      work: work ?? this.work,
      education: education ?? this.education,
      website: website ?? this.website,
      location: location ?? this.location,
      notifyFriendRequests: notifyFriendRequests ?? this.notifyFriendRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyComments: notifyComments ?? this.notifyComments,
      notifyLikes: notifyLikes ?? this.notifyLikes,
      notifyShares: notifyShares ?? this.notifyShares,
      notifyGroupActivity: notifyGroupActivity ?? this.notifyGroupActivity,
      notifyMentions: notifyMentions ?? this.notifyMentions,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      privacyProfile: privacyProfile ?? this.privacyProfile,
      privacyPosts: privacyPosts ?? this.privacyPosts,
      privacyFriendsList: privacyFriendsList ?? this.privacyFriendsList,
      privacyPhotos: privacyPhotos ?? this.privacyPhotos,
      privacySearchVisible: privacySearchVisible ?? this.privacySearchVisible,
      privacyOnlineStatus: privacyOnlineStatus ?? this.privacyOnlineStatus,
      kycStatus: kycStatus ?? this.kycStatus,
      profileType: profileType ?? this.profileType,
      customFieldsData: customFieldsData ?? this.customFieldsData,
    );
  }
}
