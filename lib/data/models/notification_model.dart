class NotificationModel {
  final int id;
  final String type;
  final String message;
  final String actorName;
  final String actorAvatar;
  final String? actorUsername;
  final String? actorProfileType;
  final String icon;
  final String iconColor;
  final bool isUnread;
  final String time;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.actorName,
    required this.actorAvatar,
    this.actorUsername,
    this.actorProfileType,
    required this.icon,
    required this.iconColor,
    required this.isUnread,
    required this.time,
    this.metadata,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      message: json['message'],
      actorName: json['actor_name'],
      actorAvatar: json['actor_avatar'],
      actorUsername: json['actor_username'],
      actorProfileType: json['actor_profile_type'],
      icon: json['icon'],
      iconColor: json['icon_color'],
      isUnread: json['is_unread'],
      time: json['time'],
      metadata: json['metadata'],
    );
  }
}

class NotificationCounts {
  final int count;
  final int msgCount;
  final String mode;

  NotificationCounts({
    required this.count,
    required this.msgCount,
    required this.mode,
  });

  factory NotificationCounts.fromJson(Map<String, dynamic> json) {
    return NotificationCounts(
      count: json['count'] ?? 0,
      msgCount: json['msg_count'] ?? 0,
      mode: json['mode'] ?? 'poll',
    );
  }
}
