import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../providers/api_client.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import '../models/live_stream_model.dart';

class FeedService {
  final Dio _dio = ApiClient().dio;
  final GetStorage _storage = GetStorage();

  /// Get paginated feed posts.
  Future<Map<String, dynamic>> getPosts(int page) async {
    try {
      final selectedCountry = _storage.read('selected_country') ?? 'all';
      final response = await _dio.get('/feed/posts', queryParameters: {
        'page': page,
        'country': selectedCountry,
      });
      final data = response.data;

      final posts = (data['data'] as List).map((p) => PostModel.fromJson(p)).toList();

      return {
        'posts': posts,
        'suggestions': data['suggestions'] ?? {},
        'nextPageUrl': data['next_page_url'],
        'currentPage': data['current_page'],
        'lastPage': data['last_page'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Long-poll for new posts since a given timestamp.
  Future<Map<String, dynamic>> checkNewPosts(int sinceTimestamp, {int lastCount = -1}) async {
    try {
      final response = await _dio.get(
        '/feed/check-new',
        queryParameters: {'since': sinceTimestamp, 'last_count': lastCount},
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      // Timeout = no new posts, return gracefully
      return {'has_new': false, 'count': 0};
    }
  }

  /// Get stories grouped by user.
  Future<List<StoryGroup>> getStories() async {
    try {
      final response = await _dio.get('/feed/stories');
      final data = response.data['data'] as List;

      return data.map((group) {
        final user = UserModel.fromJson(group['user']);
        final stories = (group['stories'] as List)
            .map((s) => StoryModel.fromJson(s))
            .toList();
        return StoryGroup(
          user: user,
          stories: stories,
          hasUnseenStories: group['has_unseen'] ?? true,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get active live streams synced into the Story Slider.
  Future<List<LiveStreamModel>> getStoryLiveStreams() async {
    try {
      final response = await _dio.get('/feed/stories');
      final liveRaw = response.data['live_streams'] as List? ?? [];
      return liveRaw
          .map((s) => LiveStreamModel.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
