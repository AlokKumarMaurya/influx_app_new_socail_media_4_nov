import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/forum_model.dart';

class ForumService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getForumData({String? search, int? categoryId, int? subcategoryId}) async {
    final response = await _dio.get('/forum', queryParameters: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
    });
    final data = response.data['data'];

    return {
      'categories': (data['categories'] as List? ?? [])
          .map((c) => ForumCategoryModel.fromJson(c))
          .toList(),
      'recent_topics': (data['recent_topics']['data'] as List? ?? [])
          .map((t) => ForumTopicModel.fromJson(t))
          .toList(),
      'trending_topics': (data['trending_topics'] as List? ?? [])
          .map((t) => ForumTopicModel.fromJson(t))
          .toList(),
    };
  }

  Future<ForumTopicModel> getTopic(String slug) async {
    final response = await _dio.get('/forum/t/$slug');
    return ForumTopicModel.fromJson(response.data['data']);
  }

  Future<ForumTopicModel> createTopic({
    required int categoryId,
    int? subcategoryId,
    required String title,
    required String content,
    List<File> attachments = const [],
  }) async {
    final formData = FormData.fromMap({
      'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      'title': title,
      'content': content,
    });

    for (var file in attachments) {
      formData.files.add(MapEntry(
        'attachments[]',
        await MultipartFile.fromFile(file.path),
      ));
    }

    final response = await _dio.post('/forum/store', data: formData);
    return ForumTopicModel.fromJson(response.data['data']);
  }

  Future<ForumReplyModel> postReply({
    required String topicSlug,
    required String content,
    int? parentId,
    List<File> attachments = const [],
  }) async {
    final formData = FormData.fromMap({
      'content': content,
      if (parentId != null) 'parent_id': parentId,
    });

    for (var file in attachments) {
      formData.files.add(MapEntry(
        'attachments[]',
        await MultipartFile.fromFile(file.path),
      ));
    }

    final response = await _dio.post('/forum/t/$topicSlug/reply', data: formData);
    return ForumReplyModel.fromJson(response.data['data']);
  }

  Future<bool> toggleSolution(int replyId) async {
    final response = await _dio.post('/forum/reply/$replyId/solution');
    return response.data['is_solution'] ?? false;
  }

  Future<Map<String, dynamic>> toggleReaction(String type, int id) async {
    final response = await _dio.post('/forum/react/$type/$id');
    return response.data;
  }

  Future<ForumTopicModel> updateTopic({
    required int topicId,
    String? title,
    int? categoryId,
    required String content,
  }) async {
    final response = await _dio.post('/forum/t/$topicId/update', data: {
      if (title != null) 'title': title,
      if (categoryId != null) 'category_id': categoryId,
      'content': content,
    });
    return ForumTopicModel.fromJson(response.data['data']);
  }

  Future<ForumReplyModel> updateReply({
    required int replyId,
    required String content,
  }) async {
    final response = await _dio.post('/forum/reply/$replyId/update', data: {
      'content': content,
    });
    return ForumReplyModel.fromJson(response.data['data']);
  }

  Future<void> deleteTopic(int topicId) async {
    await _dio.delete('/forum/t/$topicId');
  }

  Future<void> deleteReply(int replyId) async {
    await _dio.delete('/forum/reply/$replyId');
  }
}
