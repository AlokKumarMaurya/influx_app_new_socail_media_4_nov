import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../providers/api_client.dart';

class ProfileService extends GetxService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getProfile(dynamic userId) async {
    try {
      final clean = userId.toString().replaceAll('@', '').trim();
      final response = await _dio.get('/profile/$clean');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfilePosts(
    int userId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/profile/$userId/posts',
        queryParameters: {'page': page},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFriends(int userId) async {
    try {
      final response = await _dio.get('/profile/$userId/friends');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMedia(
    int userId,
    String type, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/profile/$userId/media',
        queryParameters: {'type': type, 'page': page},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/profile/update', data: data);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePhoto(File image, String type) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      });

      final response = await _dio.post('/profile/update-photo', data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Friendship Actions
  Future<Map<String, dynamic>> sendFriendRequest(int userId) async {
    try {
      final response = await _dio.post('/friends/send/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptFriendRequest(int userId) async {
    try {
      final response = await _dio.post('/friends/accept/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectFriendRequest(int userId) async {
    try {
      final response = await _dio.post('/friends/reject/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> cancelFriendRequest(int userId) async {
    try {
      final response = await _dio.post('/friends/cancel/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> unfriend(int userId) async {
    try {
      final response = await _dio.post('/friends/unfriend/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFriendRequests() async {
    try {
      final response = await _dio.get('/friends/requests');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFriendRequestsCount() async {
    try {
      final response = await _dio.get('/friends/requests/count');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPeopleSuggestions() async {
    try {
      final response = await _dio.get('/profile/suggestions');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
