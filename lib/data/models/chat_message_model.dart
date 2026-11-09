class StoryReplyModel {
  final int id;
  final int userId;
  final String userName;
  final String type; // image, video, text
  final String? mediaUrl;
  final String? content;
  final String? bgColor;
  final bool isExpired;

  StoryReplyModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    this.mediaUrl,
    this.content,
    this.bgColor,
    required this.isExpired,
  });

  factory StoryReplyModel.fromJson(Map<String, dynamic> json) {
    return StoryReplyModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      type: json['type'] ?? 'text',
      mediaUrl: json['media_url'],
      content: json['content'],
      bgColor: json['bg_color'],
      isExpired: json['is_expired'] ?? false,
    );
  }
}

class MessageReplyModel {
  final int id;
  final String senderName;
  final String? body;
  final String? attachmentType;
  final bool isDeleted;

  MessageReplyModel({
    required this.id,
    required this.senderName,
    this.body,
    this.attachmentType,
    required this.isDeleted,
  });

  factory MessageReplyModel.fromJson(Map<String, dynamic> json) {
    return MessageReplyModel(
      id: json['id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      body: json['body'],
      attachmentType: json['attachment_type'],
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class MessageReactionModel {
  final String emoji;
  final int count;
  final bool reacted;

  MessageReactionModel({
    required this.emoji,
    required this.count,
    required this.reacted,
  });

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) {
    return MessageReactionModel(
      emoji: json['emoji'] ?? '',
      count: json['count'] is int ? json['count'] : int.tryParse('${json['count']}') ?? 0,
      reacted: json['reacted'] == true,
    );
  }
}

class ChatMessageModel {
  final dynamic id;
  final String? body;
  final int senderId;
  final bool isMine;
  final String senderName;
  final String senderAvatar;
  final String? attachment;
  final String? attachmentType;
  final StoryReplyModel? storyReply;
  final MessageReplyModel? replyTo;
  final List<MessageReactionModel> reactions;
  final bool isRead;
  final String time;
  final String date;
  final String createdAt;
  final String? editedAt;
  final String? deletedAt;
  final bool isDeleted;
  final bool viewOnce;
  final String? viewedAt;
  final bool viewOnceOpened;
  final Map<String, dynamic>? payload;
  final bool isForwarded;
  final bool isOptimistic;

  ChatMessageModel({
    required this.id,
    this.body,
    required this.senderId,
    required this.isMine,
    required this.senderName,
    required this.senderAvatar,
    this.attachment,
    this.attachmentType,
    this.storyReply,
    this.replyTo,
    this.reactions = const [],
    required this.isRead,
    required this.time,
    required this.date,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.isDeleted = false,
    this.viewOnce = false,
    this.viewedAt,
    this.viewOnceOpened = false,
    this.payload,
    this.isForwarded = false,
    this.isOptimistic = false,
  });

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Map<String, dynamic>? _payloadFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List) {
      return {'_list': raw};
    }
    return null;
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final reactionsRaw = json['reactions'];
    final reactionsList = reactionsRaw is List ? reactionsRaw : const [];
    return ChatMessageModel(
      id: json['id'],
      body: json['body'],
      senderId: json['sender_id'] ?? 0,
      isMine: json['is_mine'] ?? false,
      senderName: json['sender_name'] ?? '',
      senderAvatar: json['sender_avatar'] ?? '',
      attachment: json['attachment'] is String ? json['attachment'] as String? : json['attachment']?.toString(),
      attachmentType: json['attachment_type'],
      storyReply: _mapOrNull(json['story_reply']) != null
          ? StoryReplyModel.fromJson(_mapOrNull(json['story_reply'])!)
          : null,
      replyTo: _mapOrNull(json['reply_to']) != null
          ? MessageReplyModel.fromJson(_mapOrNull(json['reply_to'])!)
          : null,
      reactions: reactionsList
          .whereType<Map>()
          .map((e) => MessageReactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      isRead: json['is_read'] ?? false,
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      editedAt: json['edited_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      isDeleted: json['is_deleted'] ?? false,
      viewOnce: json['view_once'] ?? false,
      viewedAt: json['viewed_at']?.toString(),
      viewOnceOpened: json['view_once_opened'] ?? false,
      payload: _payloadFromJson(json['payload']),
      isForwarded: json['is_forwarded'] ?? false,
    );
  }

  ChatMessageModel withViewOnceOpened() {
    return ChatMessageModel(
      id: id,
      body: body,
      senderId: senderId,
      isMine: isMine,
      senderName: senderName,
      senderAvatar: senderAvatar,
      attachment: attachment,
      attachmentType: attachmentType,
      storyReply: storyReply,
      replyTo: replyTo,
      reactions: reactions,
      isRead: isRead,
      time: time,
      date: date,
      createdAt: createdAt,
      editedAt: editedAt,
      deletedAt: deletedAt,
      isDeleted: isDeleted,
      viewOnce: viewOnce,
      viewedAt: viewedAt,
      viewOnceOpened: true,
      payload: payload,
      isForwarded: isForwarded,
      isOptimistic: isOptimistic,
    );
  }

  ChatMessageModel copyWithMerged(ChatMessageModel other) {
    return ChatMessageModel(
      id: other.id,
      body: other.body,
      senderId: other.senderId,
      isMine: other.isMine,
      senderName: other.senderName,
      senderAvatar: other.senderAvatar,
      attachment: other.attachment,
      attachmentType: other.attachmentType,
      storyReply: other.storyReply,
      replyTo: other.replyTo,
      reactions: other.reactions,
      isRead: other.isRead,
      time: other.time,
      date: other.date,
      createdAt: other.createdAt,
      editedAt: other.editedAt,
      deletedAt: other.deletedAt,
      isDeleted: other.isDeleted,
      viewOnce: other.viewOnce,
      viewedAt: other.viewedAt,
      viewOnceOpened: other.viewOnceOpened,
      payload: other.payload,
      isForwarded: other.isForwarded,
      isOptimistic: isOptimistic,
    );
  }

  factory ChatMessageModel.optimistic({
    required String? body,
    required int senderId,
    String? attachmentPreview,
    String? attachmentType,
  }) {
    final now = DateTime.now();
    return ChatMessageModel(
      id: 'opt_${now.millisecondsSinceEpoch}',
      body: body,
      senderId: senderId,
      isMine: true,
      senderName: '',
      senderAvatar: '',
      attachment: attachmentPreview,
      attachmentType: attachmentType,
      isRead: false,
      time: 'Sending...',
      date: _formatDate(now),
      createdAt: now.toIso8601String(),
      isOptimistic: true,
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }
}
