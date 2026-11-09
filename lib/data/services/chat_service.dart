// ignore_for_file: use_null_aware_elements
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../providers/api_client.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final Dio _dio = ApiClient().dio;

  /// Get paginated conversations.
  Future<Map<String, dynamic>> getConversations({
    int page = 1,
    String box = 'inbox',
  }) async {
    final response = await _dio.get(
      '/chat/conversations',
      queryParameters: {'page': page, 'box': box},
    );
    final data = response.data;
    final items = (data['data'] as List)
        .map((c) => ConversationModel.fromJson(c))
        .toList();

    return {
      'items': items,
      'nextPageUrl': data['next_page_url'],
      'counts': data['counts'] ?? {},
    };
  }

  Future<Map<String, dynamic>> getRoomMessages(
    int roomId, {
    int page = 1,
    String? query,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (query != null && query.isNotEmpty) params['q'] = query;

    final response = await _dio.get(
      '/chat/rooms/$roomId/messages',
      queryParameters: params,
    );
    final data = response.data;
    final items = (data['data'] as List? ?? [])
        .whereType<Map>()
        .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return {
      'items': items,
      'nextPageUrl': data['next_page_url'],
      'room': data['room'] is Map ? Map<String, dynamic>.from(data['room']) : null,
    };
  }

  Future<Map<String, dynamic>> getRoomInfo(int roomId) async {
    final response = await _dio.get('/chat/rooms/$roomId');
    final data = response.data;
    return {
      'room': data['room'] is Map ? Map<String, dynamic>.from(data['room']) : {},
      'members': (data['members'] as List? ?? [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(),
    };
  }

  Future<void> addRoomMembers(int roomId, List<int> userIds) async {
    await _dio.post('/chat/rooms/$roomId/members', data: {
      'user_ids': userIds,
    });
  }

  Future<void> updateRoomAvatar(int roomId, File image) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(image.path),
    });
    await _dio.post('/chat/rooms/$roomId', data: formData);
  }

  Future<void> leaveRoom(int roomId) async {
    await _dio.post('/chat/rooms/$roomId/leave');
  }

  Future<Map<String, dynamic>> createRoom({
    required String type,
    required String title,
    String? description,
    List<int> memberIds = const [],
    bool isPublic = false,
  }) async {
    final response = await _dio.post(
      type == 'channel' ? '/chat/channels' : '/chat/groups',
      data: {
        'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
        if (memberIds.isNotEmpty) 'member_ids': memberIds,
        if (type == 'channel' && isPublic) 'is_public': true,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> publicChannels() async {
    final response = await _dio.get('/chat/channels/public');
    return (response.data['channels'] as List? ?? [])
        .whereType<Map>()
        .map((c) => Map<String, dynamic>.from(c))
        .toList();
  }

  Future<Map<String, dynamic>> joinChannel(int roomId) async {
    final response = await _dio.post('/chat/channels/$roomId/join');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> sendRoomMessage({
    required int roomId,
    String? body,
    File? attachment,
    int? replyToMessageId,
    bool viewOnce = false,
    bool isVoiceNote = false,
    int? voiceDuration,
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) async {
    final formData = FormData.fromMap({
      if (body != null && body.isNotEmpty) 'body': body,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (viewOnce) 'view_once': '1',
      if (isVoiceNote) 'is_voice_note': '1',
      if (isVoiceNote) 'attachment_type': 'voice',
      if (voiceDuration != null) 'voice_duration': voiceDuration,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationLabel != null) 'location_label': locationLabel,
      if (attachment != null)
        'attachment': await MultipartFile.fromFile(
          attachment.path,
          filename: isVoiceNote
              ? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'
              : attachment.path.split('/').last,
          contentType: isVoiceNote ? MediaType('audio', 'mp4') : null,
        ),
    });

    final response = await _dio.post('/chat/rooms/$roomId/send', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  Future<ChatMessageModel> reactRoomMessage(int messageId, String emoji) async {
    final response = await _dio.post('/chat/room-messages/$messageId/react', data: {'emoji': emoji});
    final msg = response.data['message'];
    return ChatMessageModel.fromJson(Map<String, dynamic>.from(msg as Map));
  }

  /// Get paginated messages for a conversation.
  Future<Map<String, dynamic>> getMessages(
    int conversationId, {
    int page = 1,
    String? query,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (query != null && query.isNotEmpty) params['q'] = query;

    final response = await _dio.get(
      '/chat/conversations/$conversationId/messages',
      queryParameters: params,
    );
    final data = response.data;
    final items = (data['data'] as List? ?? [])
        .whereType<Map>()
        .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return {
      'items': items,
      'nextPageUrl': data['next_page_url'],
    };
  }

  /// Send a message (text and/or file).
  Future<Map<String, dynamic>> sendMessage({
    int? conversationId,
    int? userId,
    String? body,
    File? attachment,
    int? replyToMessageId,
    bool viewOnce = false,
    bool isVoiceNote = false,
    int? voiceDuration,
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) async {
    final formData = FormData.fromMap({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null && conversationId == null) 'user_id': userId,
      if (body != null && body.isNotEmpty) 'body': body,
      if (replyToMessageId != null) 'reply_to_message_id': replyToMessageId,
      if (viewOnce) 'view_once': '1',
      if (isVoiceNote) 'is_voice_note': '1',
      if (isVoiceNote) 'attachment_type': 'voice',
      if (voiceDuration != null) 'voice_duration': voiceDuration,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (locationLabel != null) 'location_label': locationLabel,
      if (attachment != null)
        'attachment': await MultipartFile.fromFile(
          attachment.path,
          filename: isVoiceNote
              ? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'
              : attachment.path.split('/').last,
          contentType: isVoiceNote ? MediaType('audio', 'mp4') : null,
        ),
    });

    final response = await _dio.post('/chat/send', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> pollMessages(
    int conversationId, {
    required int afterId,
    String? since,
  }) async {
    final response = await _dio.get(
      '/chat/conversations/$conversationId/poll',
      queryParameters: {
        'after_id': afterId,
        if (since != null) 'since': since,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final messages = (data['messages'] as List? ?? [])
        .whereType<Map>()
        .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final updates = (data['updates'] as List? ?? [])
        .whereType<Map>()
        .map((m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return {
      'messages': messages,
      'updates': updates,
      'typing': data['typing'] == true,
    };
  }

  Future<ChatMessageModel> reactMessage(int messageId, String emoji) async {
    final response = await _dio.post('/chat/messages/$messageId/react', data: {'emoji': emoji});
    return ChatMessageModel.fromJson(response.data['message']);
  }

  Future<ChatMessageModel> editMessage(int messageId, String body) async {
    final response = await _dio.post('/chat/messages/$messageId/edit', data: {'body': body});
    return ChatMessageModel.fromJson(response.data['message']);
  }

  Future<Map<String, dynamic>> deleteMessage(int messageId, {required String scope}) async {
    final response = await _dio.post('/chat/messages/$messageId/delete', data: {'scope': scope});
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> openViewOnce(int messageId) async {
    final response = await _dio.post('/chat/messages/$messageId/view-once');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> forwardMessage(int messageId, List<int> userIds) async {
    await _dio.post('/chat/forward', data: {
      'message_id': messageId,
      'user_ids': userIds,
    });
  }

  Future<void> sendTyping(int conversationId) async {
    await _dio.post('/chat/conversations/$conversationId/typing');
  }

  Future<void> muteConversation(int conversationId, String duration) async {
    await _dio.post('/chat/conversations/$conversationId/mute', data: {'duration': duration});
  }

  Future<void> unmuteConversation(int conversationId) async {
    await _dio.post('/chat/conversations/$conversationId/unmute');
  }

  Future<List<Map<String, dynamic>>> getGifts() async {
    final response = await _dio.get('/chat/gifts');
    return List<Map<String, dynamic>>.from(response.data['gifts'] ?? []);
  }

  Future<Map<String, dynamic>> sendGift({
    required int giftId,
    int? conversationId,
    int? userId,
  }) async {
    final response = await _dio.post('/chat/gifts/$giftId/send', data: {
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
    });
    return Map<String, dynamic>.from(response.data);
  }

  /// Start or get a conversation with a user.
  Future<Map<String, dynamic>> startConversation(int userId) async {
    final response = await _dio.post(
      '/chat/start',
      data: {'user_id': userId},
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Search friends for new chat.
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await _dio.get(
      '/chat/search-users',
      queryParameters: {'q': query},
    );
    return List<Map<String, dynamic>>.from(response.data['users'] ?? []);
  }

  /// Mark all messages in a conversation as read.
  Future<bool> markRead(int conversationId) async {
    try {
      final response = await _dio.post(
        '/chat/conversations/$conversationId/read',
      );
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Update conversation settings.
  Future<Map<String, dynamic>> updateSettings(
    int conversationId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/chat/conversations/$conversationId/settings',
      data: data,
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Delete a conversation.
  Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await _dio.delete('/chat/conversations/$conversationId');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get total unread count across all conversations.
  Future<int> getUnreadCount() async {
    final response = await _dio.get('/chat/unread-count');
    return response.data['count'] ?? 0;
  }

  /// Accept a message request.
  Future<bool> acceptRequest(int conversationId) async {
    try {
      final response = await _dio.post('/chat/conversations/$conversationId/accept');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Decline a message request.
  Future<bool> declineRequest(int conversationId) async {
    try {
      final response = await _dio.post('/chat/conversations/$conversationId/decline');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Mark conversation as spam.
  Future<bool> markSpam(int conversationId) async {
    try {
      final response = await _dio.post('/chat/conversations/$conversationId/spam');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get user message privacy & spam settings.
  Future<Map<String, dynamic>> getMessageSettings() async {
    final response = await _dio.get('/chat/message-settings');
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  /// Update user message privacy & spam settings.
  Future<bool> updateMessageSettings({
    required String privacy,
    required bool spamFilter,
    String? spamKeywords,
  }) async {
    try {
      final response = await _dio.post('/chat/message-settings', data: {
        'message_privacy': privacy,
        'message_spam_filter': spamFilter,
        'message_spam_keywords': spamKeywords,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
