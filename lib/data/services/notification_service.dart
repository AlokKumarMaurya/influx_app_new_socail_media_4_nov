import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final Dio _dio = ApiClient().dio;

  /// Get paginated notifications.
  Future<Map<String, dynamic>> getNotifications(int page, {String filter = 'all'}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': page, 'filter': filter},
      );
      final data = response.data;
      final items = (data['data'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();

      return {
        'items': items,
        'nextPageUrl': data['next_page_url'],
        'currentPage': data['current_page'],
        'lastPage': data['last_page'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread counts (with optional long-polling).
  Future<NotificationCounts> getCounts({int? lastCount, int? lastMsgCount}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (lastCount != null) queryParams['last_count'] = lastCount;
      if (lastMsgCount != null) queryParams['last_msg_count'] = lastMsgCount;

      final response = await _dio.get(
        '/notifications/count',
        queryParameters: queryParams,
        // Long timeout for long-polling
        options: Options(receiveTimeout: const Duration(seconds: 35)),
      );
      
      return NotificationCounts.fromJson(response.data);
    } catch (e) {
      // If timeout or error, return null or rethrow based on logic
      rethrow;
    }
  }

  /// Mark a single notification as read.
  Future<bool> markAsRead(int id) async {
    try {
      final response = await _dio.post('/notifications/$id/read');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read.
  Future<bool> markAllRead() async {
    try {
      final response = await _dio.post('/notifications/read-all');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
