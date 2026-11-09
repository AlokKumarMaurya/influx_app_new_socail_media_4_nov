import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/story_model.dart';

class StoryService {
  final Dio _dio = ApiClient().dio;

  /// Create a new story (media or text).
  Future<StoryModel> createStory({
    required String type,
    File? media,
    String? content,
    String? bgColor,
    String? fontStyle,
    String privacy = 'public',
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'content': content,
        'bg_color': bgColor,
        'font_style': fontStyle,
        'privacy': privacy,
      });

      if (media != null) {
        formData.files.add(MapEntry(
          'media',
          await MultipartFile.fromFile(media.path, filename: media.path.split('/').last),
        ));
      }

      final response = await _dio.post(
        '/stories', 
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      return StoryModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Record a view for a story.
  Future<void> recordView(int storyId) async {
    try {
      await _dio.post('/stories/$storyId/view');
    } catch (e) {
      // Silently fail for background analytics
    }
  }

  /// React to a story.
  Future<void> reactToStory(int storyId, String reaction) async {
    try {
      await _dio.post('/stories/$storyId/react', data: {'reaction': reaction});
    } catch (e) {
      rethrow;
    }
  }

  /// Get viewers list for own story.
  Future<List<Map<String, dynamic>>> getViewers(int storyId) async {
    try {
      final response = await _dio.get('/stories/$storyId/viewers');
      return List<Map<String, dynamic>>.from(response.data['viewers']);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete own story.
  Future<void> deleteStory(int storyId) async {
    try {
      await _dio.delete('/stories/$storyId');
    } catch (e) {
      rethrow;
    }
  }

  /// Send story reply message or reaction to chat.
  Future<Map<String, dynamic>> sendStoryReply(int storyId, {String? body, String? reaction}) async {
    try {
      final response = await _dio.post('/stories/$storyId/reply', data: {
        if (body != null && body.isNotEmpty) 'body': body,
        if (reaction != null && reaction.isNotEmpty) 'reaction': reaction,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
