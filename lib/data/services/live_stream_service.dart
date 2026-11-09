import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/live_stream_model.dart';

class LiveStreamService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getConfig() async {
    final response = await _dio.get('/live/config');
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<List<LiveStreamModel>> getStreams({
    String filter = 'popular',
    String category = 'all',
    String query = '',
    int page = 1,
    int? userId,
    int? fanPageId,
    bool includeEnded = false,
  }) async {
    final response = await _dio.get(
      '/live/streams',
      queryParameters: {
        'filter': filter,
        'category': category,
        'q': query,
        'page': page,
        'user_id': ?userId,
        'fan_page_id': ?fanPageId,
        if (includeEnded) 'include_ended': 1,
      },
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((item) => LiveStreamModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> startStream({
    required String title,
    String? description,
    String category = 'general',
    int? fanPageId,
    bool isPaid = false,
    double entryFee = 0.0,
    File? thumbnailFile,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'category': category,
      'fan_page_id': ?fanPageId,
      'is_paid': isPaid ? 1 : 0,
      if (isPaid) 'entry_fee': entryFee,
      if (thumbnailFile != null)
        'thumbnail': await MultipartFile.fromFile(thumbnailFile.path),
    });

    final response = await _dio.post('/live/start', data: formData);
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> joinStream(String uuid) async {
    final response = await _dio.get('/live/$uuid');
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> unlockStream(String uuid) async {
    final response = await _dio.post('/live/$uuid/unlock');
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<LiveEventModel> sendComment(
    String uuid, {
    required String message,
    bool isSuperChat = false,
    double amount = 0.0,
  }) async {
    final response = await _dio.post(
      '/live/$uuid/comment',
      data: {
        'message': message,
        'is_super_chat': isSuperChat,
        if (isSuperChat) 'amount': amount,
      },
    );
    return LiveEventModel.fromJson(
      Map<String, dynamic>.from(response.data['data']['event']),
    );
  }

  Future<void> pinComment(String uuid, int eventId) async {
    await _dio.post('/live/$uuid/comment/$eventId/pin');
  }

  Future<LiveEventModel> sendGift(
    String uuid, {
    required int giftId,
    int quantity = 1,
    String? message,
  }) async {
    final response = await _dio.post(
      '/live/$uuid/gift',
      data: {
        'live_gift_id': giftId,
        'quantity': quantity,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
    return LiveEventModel.fromJson(
      Map<String, dynamic>.from(response.data['data']['event']),
    );
  }

  Future<LiveEventModel> sendTip(
    String uuid, {
    required double amount,
    String? message,
  }) async {
    final response = await _dio.post(
      '/live/$uuid/tip',
      data: {
        'amount': amount,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
    return LiveEventModel.fromJson(
      Map<String, dynamic>.from(response.data['data']['event']),
    );
  }

  Future<void> sendReaction(String uuid, String emoji) async {
    await _dio.post('/live/$uuid/react', data: {'emoji': emoji});
  }

  Future<Map<String, dynamic>> sync(String uuid, int afterEventId) async {
    final response = await _dio.get(
      '/live/$uuid/sync',
      queryParameters: {'after_event_id': afterEventId},
    );
    return Map<String, dynamic>.from(response.data['data'] ?? {});
  }

  Future<void> endStream(String uuid) async {
    await _dio.post('/live/$uuid/end');
  }

  Future<void> leaveStream(String uuid) async {
    try {
      await _dio.post('/live/$uuid/leave');
    } catch (_) {}
  }
}
