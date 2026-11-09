import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../providers/api_client.dart';
import '../models/group_model.dart';
import '../models/post_model.dart';

class GroupService extends GetxService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getGroupsLanding() async {
    final response = await _dio.get('/groups');
    return {
      'my_groups': (response.data['my_groups'] as List).map((g) => GroupModel.fromJson(g)).toList(),
      'suggested': (response.data['suggested'] as List).map((g) => GroupModel.fromJson(g)).toList(),
    };
  }

  Future<Map<String, dynamic>> getMyGroups(int page) async {
    final response = await _dio.get('/groups/my', queryParameters: {'page': page});
    return {
      'groups': (response.data['data'] as List).map((g) => GroupModel.fromJson(g)).toList(),
      'nextPageUrl': response.data['next_page_url'],
    };
  }

  Future<Map<String, dynamic>> getSuggestedGroups(int page) async {
    final response = await _dio.get('/groups/suggestions', queryParameters: {'page': page});
    return {
      'groups': (response.data['data'] as List).map((g) => GroupModel.fromJson(g)).toList(),
      'nextPageUrl': response.data['next_page_url'],
    };
  }

  Future<Map<String, dynamic>> getGroupFeed(int page) async {
    final response = await _dio.get('/groups/feed', queryParameters: {'page': page});
    return {
      'posts': (response.data['data'] as List).map((p) => PostModel.fromJson(p)).toList(),
      'suggestions': response.data['suggestions'],
      'nextPageUrl': response.data['next_page_url'],
      'currentPage': response.data['current_page'],
    };
  }

  // --- New Advanced Group Methods ---

  Future<Map<String, dynamic>> createGroup(dynamic data) async {
    try {
      final response = await _dio.post('/groups', data: data);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGroup(
    int groupId, {
    required String name,
    required String description,
    required String privacy,
    dynamic avatar,
    dynamic coverPhoto,
  }) async {
    try {
      dynamic data;
      if (avatar != null || coverPhoto != null) {
        data = FormData.fromMap({
          '_method': 'PUT',
          'name': name,
          'description': description,
          'privacy': privacy,
          if (avatar != null && avatar is File)
            'avatar': await MultipartFile.fromFile(avatar.path),
          if (coverPhoto != null && coverPhoto is File)
            'cover_photo': await MultipartFile.fromFile(coverPhoto.path),
        });
      } else {
        data = {
          'name': name,
          'description': description,
          'privacy': privacy,
        };
      }

      final response = await _dio.post('/groups/$groupId', data: data);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteGroup(int groupId) async {
    try {
      final response = await _dio.delete('/groups/$groupId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> joinGroup(int groupId) async {
    try {
      final response = await _dio.post('/groups/$groupId/join');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> leaveGroup(int groupId) async {
    try {
      final response = await _dio.post('/groups/$groupId/leave');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGroupPosts(int groupId, {int page = 1}) async {
    try {
      final response = await _dio.get('/groups/$groupId/posts', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGroupMedia(int groupId, {int page = 1}) async {
    try {
      final response = await _dio.get('/groups/$groupId/media', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGroupMedia(int groupId, File image, String type) async {
    try {
      final formData = FormData.fromMap({
        type: await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      });

      final endpoint = type == 'avatar' ? '/groups/$groupId/avatar' : '/groups/$groupId/cover';
      final response = await _dio.post(endpoint, data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // --- Member Management ---

  Future<Map<String, dynamic>> getMembers(int groupId, {int page = 1}) async {
    try {
      final response = await _dio.get('/groups/$groupId/members', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRequests(int groupId, {int page = 1}) async {
    try {
      final response = await _dio.get('/groups/$groupId/members/requests', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> approveMember(int groupId, int userId) async {
    try {
      final response = await _dio.post('/groups/$groupId/members/$userId/approve');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectMember(int groupId, int userId) async {
    try {
      final response = await _dio.post('/groups/$groupId/members/$userId/reject');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeMember(int groupId, int userId) async {
    try {
      final response = await _dio.delete('/groups/$groupId/members/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateRole(int groupId, int userId, String role) async {
    try {
      final response = await _dio.put('/groups/$groupId/members/$userId/role', data: {'role': role});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> inviteToGroup(int groupId, int userId) async {
    try {
      final response = await _dio.post('/groups/$groupId/members/$userId/invite');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInviteableFriends(int groupId, {String? term}) async {
    try {
      final response = await _dio.get('/groups/$groupId/inviteable-friends', queryParameters: {'term': term});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
