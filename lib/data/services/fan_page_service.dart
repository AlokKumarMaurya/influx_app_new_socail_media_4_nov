import 'dart:io';
import 'package:dio/dio.dart';
import '../models/fan_page_chat_model.dart';
import '../models/fan_page_model.dart';
import '../models/post_model.dart';
import '../providers/api_client.dart';

class FanPageService {
  final Dio _dio = ApiClient().dio;

  Future<List<FanPageModel>> getPages({String? query, String? category, int page = 1}) async {
    try {
      final res = await _dio.get('/fan-pages', queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
      });

      final items = res.data['data']['data'] as List;
      return items.map((e) => FanPageModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FanPageCategoryModel>> getCategories() async {
    try {
      final res = await _dio.get('/fan-pages/categories');
      final list = res.data['data'] as List;
      return list.map((e) => FanPageCategoryModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, List<FanPageModel>>> getMyPages() async {
    try {
      final res = await _dio.get('/fan-pages/my');
      final managed = (res.data['data']['managed'] as List).map((e) => FanPageModel.fromJson(e)).toList();
      final followed = (res.data['data']['followed'] as List).map((e) => FanPageModel.fromJson(e)).toList();
      return {'managed': managed, 'followed': followed};
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageModel> getPageDetails(String slug) async {
    try {
      final res = await _dio.get('/fan-pages/$slug');
      final data = res.data['data']['page'];
      data['is_following'] = res.data['data']['is_following'];
      data['can_manage'] = res.data['data']['can_manage'];
      data['user_role'] = res.data['data']['user_role'];
      data['rating'] = res.data['data']['rating'];
      return FanPageModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleFollow(String slug) async {
    try {
      final res = await _dio.post('/fan-pages/$slug/follow');
      final data = res.data;
      final isFollowed = (data['is_followed'] ?? data['is_following']) == true;
      final followers = data['followers'] is int
          ? data['followers'] as int
          : int.tryParse(data['followers']?.toString() ?? '0') ?? 0;
      return {
        'is_followed': isFollowed,
        'followers': followers,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PostModel>> getPagePosts(String slug, {int page = 1}) async {
    try {
      final res = await _dio.get('/fan-pages/$slug/posts', queryParameters: {'page': page});
      final list = res.data['data']['data'] as List;
      return list.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<FanPageModel> createPage({
    required String name,
    required int categoryId,
    String? bio,
    String? website,
    String? location,
    String ctaButtonType = 'message',
    String? ctaButtonUrl,
    File? avatarFile,
    File? coverFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'category_id': categoryId,
        'bio':? bio,
        'website':? website,
        'location':? location,
        'cta_button_type': ctaButtonType,
        'cta_button_url':? ctaButtonUrl,
        if (avatarFile != null)
          'avatar': await MultipartFile.fromFile(avatarFile.path),
        if (coverFile != null)
          'cover_photo': await MultipartFile.fromFile(coverFile.path),
      });

      final res = await _dio.post('/fan-pages', data: formData);
      return FanPageModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<PostModel> createPagePost({
    required String slug,
    String? content,
    List<File>? mediaFiles,
  }) async {
    try {
      final formData = FormData();
      if (content != null) {
        formData.fields.add(MapEntry('content', content));
      }
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        for (var f in mediaFiles) {
          formData.files.add(MapEntry('media[]', await MultipartFile.fromFile(f.path)));
        }
      }

      final res = await _dio.post('/fan-pages/$slug/posts', data: formData);
      return PostModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitReview({
    required String slug,
    required int rating,
    required String review,
  }) async {
    try {
      await _dio.post('/fan-pages/$slug/reviews', data: {
        'rating': rating,
        'review': review,
      });
    } catch (e) {
      rethrow;
    }
  }

  // --- Inbox & Messaging ---

  Future<List<dynamic>> getPageConversations(String slug) async {
    try {
      final res = await _dio.get('/fan-pages/$slug/inbox');
      final raw = res.data;
      if (raw is Map) {
        if (raw['conversations'] is List) {
          return raw['conversations'] as List;
        }
        final data = raw['data'];
        if (data is List) {
          return data;
        } else if (data is Map && data['data'] is List) {
          return data['data'] as List;
        }
      } else if (raw is List) {
        return raw;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConversationMessages(String slug, int conversationId) async {
    try {
      final res = await _dio.get('/fan-pages/$slug/inbox/$conversationId');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'data': data};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> replyAsPage(
    String slug,
    int conversationId, {
    String? message,
    File? media,
  }) async {
    try {
      final formData = FormData();
      if (message != null && message.isNotEmpty) {
        formData.fields.add(MapEntry('message', message));
      }
      if (media != null) {
        formData.files.add(MapEntry('media', await MultipartFile.fromFile(media.path)));
      }

      final res = await _dio.post('/fan-pages/$slug/inbox/$conversationId/reply', data: formData);
      return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCustomerChat(String slug) async {
    try {
      final res = await _dio.get('/fan-pages/$slug/chat');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {'data': data};
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendCustomerMessage(
    String slug, {
    String? message,
    File? media,
  }) async {
    try {
      final formData = FormData();
      if (message != null && message.isNotEmpty) {
        formData.fields.add(MapEntry('message', message));
      }
      if (media != null) {
        formData.files.add(MapEntry('media', await MultipartFile.fromFile(media.path)));
      }

      final res = await _dio.post('/fan-pages/$slug/chat/send', data: formData);
      return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
    } catch (e) {
      rethrow;
    }
  }

  /// Get all fan pages the logged-in user has sent messages to (Sent to Pages)
  Future<List<FanPageConversationModel>> getUserPageChats() async {
    try {
      final res = await _dio.get('/user/page-chats');
      final data = res.data;
      List list = [];
      if (data['data'] is List) {
        list = data['data'];
      } else if (data['conversations'] is List) {
        list = data['conversations'];
      }
      return list.map((e) => FanPageConversationModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Page Suggestions ---

  Future<List<FanPageModel>> getSuggestedPages({int limit = 10}) async {
    try {
      final res = await _dio.get('/fan-pages/suggested', queryParameters: {'limit': limit});
      final list = res.data['data'] as List;
      return list.map((e) => FanPageModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // --- Page Management ---

  Future<FanPageModel> updatePage(String slug, Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/fan-pages/$slug', data: data);
      return FanPageModel.fromJson(res.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> updateAvatar(String slug, File file) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(file.path),
      });
      final res = await _dio.post('/fan-pages/$slug/avatar', data: formData);
      return res.data['avatar_url'] ?? '';
    } catch (e) {
      rethrow;
    }
  }

  Future<String> updateCover(String slug, File file) async {
    try {
      final formData = FormData.fromMap({
        'cover_photo': await MultipartFile.fromFile(file.path),
      });
      final res = await _dio.post('/fan-pages/$slug/cover', data: formData);
      return res.data['cover_url'] ?? '';
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPageMembers(String slug) async {
    try {
      final res = await _dio.get('/fan-pages/$slug/members');
      return res.data['data'] is Map<String, dynamic> ? res.data['data'] : {'members': []};
    } catch (e) {
      return {'members': []};
    }
  }

  Future<void> assignMember(String slug, {int? userId, String? username, required String role}) async {
    try {
      await _dio.post('/fan-pages/$slug/members', data: {
        'user_id':? userId,
        'username':? username,
        'role': role,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember(String slug, int userId) async {
    try {
      await _dio.delete('/fan-pages/$slug/members/$userId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePage(String slug) async {
    try {
      await _dio.delete('/fan-pages/$slug');
    } catch (e) {
      rethrow;
    }
  }
}
