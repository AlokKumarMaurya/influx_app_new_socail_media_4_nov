class ConversationModel {
  final int id;
  final String kind;
  final String? roomType;
  final String? roomTitle;
  final String? roomAvatar;
  final bool canPost;
  final String? myRole;
  final ChatUser user;
  final LastMessage? lastMessage;
  final int unreadCount;
  final Map<String, dynamic> settings;
  final String status;
  final int? requestedToUserId;
  final bool isPendingRequest;
  final bool isSpam;

  bool get isRoom => kind == 'room';

  ConversationModel({
    required this.id,
    this.kind = 'direct',
    this.roomType,
    this.roomTitle,
    this.roomAvatar,
    this.canPost = true,
    this.myRole,
    required this.user,
    this.lastMessage,
    required this.unreadCount,
    required this.settings,
    this.status = 'inbox',
    this.requestedToUserId,
    this.isPendingRequest = false,
    this.isSpam = false,
  });

  ConversationModel copyWith({
    int? id,
    ChatUser? user,
    LastMessage? lastMessage,
    int? unreadCount,
    Map<String, dynamic>? settings,
    String? status,
    int? requestedToUserId,
    bool? isPendingRequest,
    bool? isSpam,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      user: user ?? this.user,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      requestedToUserId: requestedToUserId ?? this.requestedToUserId,
      isPendingRequest: isPendingRequest ?? this.isPendingRequest,
      isSpam: isSpam ?? this.isSpam,
    );
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final kind = json['kind']?.toString() ?? 'direct';
    if (kind == 'room') {
      final title = json['title']?.toString() ?? 'Room';
      final avatar = json['avatar']?.toString();
      return ConversationModel(
        id: json['id'] as int,
        kind: 'room',
        roomType: json['room_type']?.toString(),
        roomTitle: title,
        roomAvatar: avatar,
        canPost: json['can_post'] != false,
        myRole: (json['my_role'] ?? json['role'])?.toString(),
        user: ChatUser(
          id: 0,
          name: title,
          avatar: (avatar != null && avatar.isNotEmpty)
              ? avatar
              : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}&background=random',
        ),
        lastMessage: json['last_message'] != null
            ? LastMessage.fromJson(json['last_message'])
            : null,
        unreadCount: json['unread_count'] ?? 0,
        settings: {},
        status: 'inbox',
      );
    }

    return ConversationModel(
      id: json['id'],
      kind: 'direct',
      user: ChatUser.fromJson(json['user']),
      lastMessage: json['last_message'] != null
          ? LastMessage.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'])
          : {},
      status: json['status'] ?? 'inbox',
      requestedToUserId: json['requested_to_user_id'],
      isPendingRequest: json['is_pending_request'] ?? (json['status'] == 'requests'),
      isSpam: json['is_spam'] ?? (json['status'] == 'spam'),
    );
  }
}

class ChatUser {
  final int id;
  final String name;
  final String? username;
  final String avatar;
  final bool isOnline;
  final String? profileType;

  ChatUser({
    required this.id,
    required this.name,
    this.username,
    required this.avatar,
    this.isOnline = false,
    this.profileType,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'],
      avatar: (json['avatar'] != null && json['avatar'].toString().isNotEmpty)
          ? json['avatar']
          : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(json['name'] ?? 'User')}&background=random',
      isOnline: json['is_online'] ?? false,
      profileType: json['profile_type'] ?? json['sender_profile_type'],
    );
  }
}

class LastMessage {
  final String? body;
  final int senderId;
  final bool isMine;
  final String? attachmentType;
  final String time;

  LastMessage({
    this.body,
    required this.senderId,
    required this.isMine,
    this.attachmentType,
    required this.time,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      body: json['body'],
      senderId: json['sender_id'],
      isMine: json['is_mine'] ?? false,
      attachmentType: json['attachment_type'],
      time: json['time'] ?? '',
    );
  }
}
