import '../../utils/url_utils.dart';
import 'common_user_model.dart';
import 'fan_page_model.dart';

class FanPageConversationModel {
  final int id;
  final int fanPageId;
  final int userId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int userUnreadCount;
  final int pageUnreadCount;
  final CommonUserModel? user;
  final FanPageModel? page;

  FanPageConversationModel({
    required this.id,
    required this.fanPageId,
    required this.userId,
    this.lastMessage,
    this.lastMessageAt,
    this.userUnreadCount = 0,
    this.pageUnreadCount = 0,
    this.user,
    this.page,
  });

  factory FanPageConversationModel.fromJson(Map<String, dynamic> json) {
    return FanPageConversationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fanPageId: json['fan_page_id'] is int ? json['fan_page_id'] : int.tryParse(json['fan_page_id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      lastMessage: json['last_message_preview'] ?? json['last_message'],
      lastMessageAt: json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at'].toString()) : null,
      userUnreadCount: json['user_unread_count'] is int
          ? json['user_unread_count']
          : (json['unread_user_count'] is int
              ? json['unread_user_count']
              : int.tryParse(json['user_unread_count']?.toString() ?? json['unread_user_count']?.toString() ?? '0') ?? 0),
      pageUnreadCount: json['page_unread_count'] is int
          ? json['page_unread_count']
          : (json['unread_page_count'] is int
              ? json['unread_page_count']
              : int.tryParse(json['page_unread_count']?.toString() ?? json['unread_page_count']?.toString() ?? '0') ?? 0),
      user: json['user'] != null ? CommonUserModel.fromJson(json['user']) : null,
      page: json['page'] != null
          ? FanPageModel.fromJson(json['page'])
          : (json['fan_page'] != null ? FanPageModel.fromJson(json['fan_page']) : null),
    );
  }
}

class FanPageMessageModel {
  final int id;
  final int fanPageConversationId;
  final String senderType; // 'user' or 'page'
  final int senderId;
  final String? message;
  final String? attachmentUrl;
  final String? mediaType;
  final bool isRead;
  final DateTime createdAt;
  final CommonUserModel? sender;

  FanPageMessageModel({
    required this.id,
    required this.fanPageConversationId,
    required this.senderType,
    required this.senderId,
    this.message,
    this.attachmentUrl,
    this.mediaType,
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  bool get isFromPage => senderType == 'page';

  factory FanPageMessageModel.fromJson(Map<String, dynamic> json) {
    String? attachment;
    final rawUrl = json['media_url'] ?? json['attachment_url'] ?? json['attachment_path'];
    if (rawUrl != null && rawUrl.toString().isNotEmpty) {
      attachment = UrlUtils.getFullUrl(rawUrl.toString());
    }

    final rawSenderId = json['sender_user_id'] ?? json['sender_id'];

    return FanPageMessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fanPageConversationId: json['fan_page_conversation_id'] is int
          ? json['fan_page_conversation_id']
          : int.tryParse(json['fan_page_conversation_id']?.toString() ?? '0') ?? 0,
      senderType: json['sender_type'] ?? 'user',
      senderId: rawSenderId is int ? rawSenderId : int.tryParse(rawSenderId?.toString() ?? '0') ?? 0,
      message: json['message'],
      attachmentUrl: attachment,
      mediaType: json['media_type']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      sender: json['sender'] != null ? CommonUserModel.fromJson(json['sender']) : null,
    );
  }
}
