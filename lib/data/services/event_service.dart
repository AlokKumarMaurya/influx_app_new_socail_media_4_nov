import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/event_model.dart';

class EventService {
  final Dio _dio = ApiClient().dio;

  /// Get events index: discover (paginated), attending, hosted (paginated).
  Future<Map<String, dynamic>> getEvents({int page = 1}) async {
    try {
      final response = await _dio.get('/events', queryParameters: {'page': page});
      final data = response.data;

      return {
        'discover': (data['discover']?['data'] as List?)
                ?.map((e) => EventModel.fromJson(e))
                .toList() ??
            [],
        'discoverCurrentPage': data['discover']?['current_page'] ?? 1,
        'discoverLastPage': data['discover']?['last_page'] ?? 1,
        'attending': (data['attending'] as List?)
                ?.map((e) => EventModel.fromJson(e))
                .toList() ??
            [],
        'hosted': (data['hosted']?['data'] as List?)
                ?.map((e) => EventModel.fromJson(e))
                .toList() ??
            [],
        'hostedCurrentPage': data['hosted']?['current_page'] ?? 1,
        'hostedLastPage': data['hosted']?['last_page'] ?? 1,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Load more discover events.
  Future<Map<String, dynamic>> getMoreDiscoverEvents({required int page}) async {
    try {
      final response = await _dio.get('/events', queryParameters: {'page': page});
      final data = response.data;

      return {
        'events': (data['discover']?['data'] as List?)
                ?.map((e) => EventModel.fromJson(e))
                .toList() ??
            [],
        'currentPage': data['discover']?['current_page'] ?? 1,
        'lastPage': data['discover']?['last_page'] ?? 1,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Load more hosted events.
  Future<Map<String, dynamic>> getMoreHostedEvents({required int page}) async {
    try {
      final response = await _dio.get('/events', queryParameters: {'hosted_page': page});
      final data = response.data;

      return {
        'events': (data['hosted']?['data'] as List?)
                ?.map((e) => EventModel.fromJson(e))
                .toList() ??
            [],
        'currentPage': data['hosted']?['current_page'] ?? 1,
        'lastPage': data['hosted']?['last_page'] ?? 1,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get single event detail.
  Future<EventModel> getEvent(int id) async {
    try {
      final response = await _dio.get('/events/$id');
      return EventModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new event.
  Future<Map<String, dynamic>> createEvent({
    required String name,
    required String type,
    required String category,
    required String startDate,
    String? endDate,
    String? location,
    String? link,
    required String description,
    bool isPaid = false,
    double ticketPrice = 0.0,
    File? coverImage,
    List<File>? materials,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'name': name,
        'type': type,
        'category': category,
        'start_date': startDate,
        'description': description,
        'is_paid': isPaid ? 1 : 0,
        'ticket_price': ticketPrice,
      };

      if (endDate != null && endDate.isNotEmpty) map['end_date'] = endDate;
      if (location != null && location.isNotEmpty) map['location'] = location;
      if (link != null && link.isNotEmpty) map['link'] = link;
      if (coverImage != null) {
        map['cover_image'] = await MultipartFile.fromFile(
          coverImage.path,
          filename: coverImage.path.split('/').last,
        );
      }

      if (materials != null && materials.isNotEmpty) {
        final List<MultipartFile> fileList = [];
        for (var f in materials) {
          fileList.add(await MultipartFile.fromFile(
            f.path,
            filename: f.path.split('/').last,
          ));
        }
        map['materials[]'] = fileList;
      }

      final formData = FormData.fromMap(map);

      final response = await _dio.post(
        '/events',
        data: formData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'success': true};
    } catch (e) {
      rethrow;
    }
  }

  /// Update an event.
  Future<Map<String, dynamic>> updateEvent({
    required int id,
    required String name,
    required String type,
    required String category,
    required String startDate,
    String? endDate,
    String? location,
    String? link,
    required String description,
    bool isPaid = false,
    double ticketPrice = 0.0,
    File? coverImage,
    List<File>? materials,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'name': name,
        'type': type,
        'category': category,
        'start_date': startDate,
        'description': description,
        'is_paid': isPaid ? 1 : 0,
        'ticket_price': ticketPrice,
      };

      if (endDate != null && endDate.isNotEmpty) map['end_date'] = endDate;
      if (location != null && location.isNotEmpty) map['location'] = location;
      if (link != null && link.isNotEmpty) map['link'] = link;
      if (coverImage != null) {
        map['cover_image'] = await MultipartFile.fromFile(
          coverImage.path,
          filename: coverImage.path.split('/').last,
        );
      }

      if (materials != null && materials.isNotEmpty) {
        final List<MultipartFile> fileList = [];
        for (var f in materials) {
          fileList.add(await MultipartFile.fromFile(
            f.path,
            filename: f.path.split('/').last,
          ));
        }
        map['materials[]'] = fileList;
      }

      final formData = FormData.fromMap(map);

      final response = await _dio.post(
        '/events/$id',
        data: formData,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'success': true};
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an event.
  Future<Map<String, dynamic>> deleteEvent(int id) async {
    try {
      final response = await _dio.delete('/events/$id');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle RSVP attendance.
  Future<Map<String, dynamic>> attendEvent(int eventId, String status) async {
    try {
      final response = await _dio.post('/events/$eventId/attend', data: {'status': status});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Purchase ticket for paid event.
  Future<Map<String, dynamic>> buyTicket(int eventId) async {
    try {
      final response = await _dio.post('/events/$eventId/buy-ticket');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Invite users to event.
  Future<Map<String, dynamic>> inviteUsers(int eventId, List<int> userIds) async {
    try {
      final response = await _dio.post('/events/$eventId/invite', data: {'user_ids': userIds});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
