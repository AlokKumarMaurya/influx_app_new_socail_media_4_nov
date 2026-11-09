class CommonUserModel {
  final int id;
  final String name;
  final String username;
  final String avatar;
  final String profileType;
  final int mutualFriendsCount;

  CommonUserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.profileType,
    required this.mutualFriendsCount,
  });

  factory CommonUserModel.fromJson(Map<String, dynamic> json) {
    return CommonUserModel(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      profileType: json['profile_type'] ?? 'user',
      mutualFriendsCount: json['mutual_friends_count'] ?? 0,
    );
  }
}
