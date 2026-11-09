class FriendRequestModel {
  final int id;
  final String type; // 'friend_request' or 'group_join_request'
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String? senderProfileType;
  final String? senderUrl;
  final String timeAgo;
  final String createdAt;
  
  // Group fields
  final int? groupId;
  final String? groupName;
  final String? groupSlug;

  FriendRequestModel({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.senderProfileType,
    this.senderUrl,
    required this.timeAgo,
    required this.createdAt,
    this.groupId,
    this.groupName,
    this.groupSlug,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'],
      type: json['type'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      senderProfileType: json['sender_profile_type'] ?? 'user',
      senderUrl: json['sender_url'],
      timeAgo: json['time_ago'] ?? '',
      createdAt: json['created_at'] ?? '',
      groupId: json['group_id'],
      groupName: json['group_name'],
      groupSlug: json['group_slug'],
    );
  }
}
