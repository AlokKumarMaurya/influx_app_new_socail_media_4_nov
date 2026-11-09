import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/reaction_model.dart';
import '../models/user_model.dart';

class PostService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final response = await _dio.delete('/comments/$commentId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle reaction on a post or comment.
  Future<Map<String, dynamic>> toggleReaction(int id, String type, {String model = 'post'}) async {
    try {
      final response = await _dio.post('/reactions/toggle', data: {
        'id': id,
        'type': type,
        'model': model,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get details for a single post.
  Future<PostModel> getPostDetails(int postId) async {
    try {
      final response = await _dio.get('/posts/$postId');
      return PostModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get paginated comments for a post.
  Future<Map<String, dynamic>> getComments(int postId, int page) async {
    try {
      final response = await _dio.get(
        '/comments/post/$postId',
        queryParameters: {'page': page},
      );
      final data = response.data;

      final comments = (data['data'] as List)
          .map((c) => CommentModel.fromJson(c))
          .toList();

      return {
        'comments': comments,
        'nextPageUrl': data['next_page_url'],
        'total': data['total'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Add a comment to a post.
  Future<CommentModel> addComment(int postId, String content, {File? image, int? parentId}) async {
    try {
      final formData = FormData.fromMap({
        'post_id': postId,
        'content': content,
        'parent_id': ?parentId,
      });

      if (image != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
        ));
      }

      final response = await _dio.post('/comments', data: formData);
      return CommentModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle save/bookmark on a post.
  Future<String> toggleSave(int postId) async {
    try {
      final response = await _dio.post('/posts/$postId/save');
      return response.data['action']; // 'saved' or 'removed'
    } catch (e) {
      rethrow;
    }
  }

  /// Share a post.
  Future<Map<String, dynamic>> sharePost(int postId, String content, String privacy) async {
    try {
      final response = await _dio.post('/posts/$postId/share', data: {
        'content': content,
        'privacy': privacy,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch OpenGraph metadata for a URL.
  Future<Map<String, dynamic>?> fetchLinkMeta(String url) async {
    try {
      final response = await _dio.post('/posts/fetch-link-meta', data: {'url': url});
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new post.
  Future<Map<String, dynamic>> createPost({
    String? content,
    required String postType,
    String? bgColor,
    String? feelingAction,
    String? feelingValue,
    String? location,
    required String privacy,
    int? groupId,
    int? fanPageId,
    String? linkUrl,
    String? linkTitle,
    String? linkDescription,
    String? linkImage,
    String? linkDomain,
    bool ignoreLinkPreview = false,
    List<File>? media,
    List<int>? tags,
  }) async {
    try {
      final formData = FormData.fromMap({
        'content': ?content,
        'post_type': postType,
        'bg_color': ?bgColor,
        'feeling_action': ?feelingAction,
        'feeling_value': ?feelingValue,
        'location': ?location,
        'privacy': privacy,
        'group_id': ?groupId,
        'fan_page_id': ?fanPageId,
        'link_url': ?linkUrl,
        'link_title': ?linkTitle,
        'link_description': ?linkDescription,
        'link_image': ?linkImage,
        'link_domain': ?linkDomain,
        'ignore_link_preview': ignoreLinkPreview ? '1' : '0',
      });

      if (media != null && media.isNotEmpty) {
        for (var file in media) {
          formData.files.add(MapEntry(
            'media[]',
            await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ));
        }
      }

      if (tags != null && tags.isNotEmpty) {
        for (var i = 0; i < tags.length; i++) {
          formData.fields.add(MapEntry('tags[$i]', tags[i].toString()));
        }
      }

      final response = await _dio.post('/posts', data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a post.
  Future<Map<String, dynamic>> updatePost(int postId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/posts/$postId', data: data);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a post with full media & remove_media support.
  Future<Map<String, dynamic>> updatePostWithMedia(
    int postId, {
    String? content,
    required String privacy,
    String? postType,
    String? bgColor,
    String? feelingAction,
    String? feelingValue,
    String? location,
    List<File>? newMedia,
    List<int>? removeMediaIds,
  }) async {
    try {
      final formData = FormData.fromMap({
        '_method': 'PUT',
        'content': content ?? '',
        'privacy': privacy,
        'post_type': postType,
        'bg_color': bgColor,
        'feeling_action': feelingAction,
        'feeling_value': feelingValue,
        'location': location,
      });

      if (newMedia != null && newMedia.isNotEmpty) {
        for (var file in newMedia) {
          formData.files.add(MapEntry(
            'media[]',
            await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
          ));
        }
      }

      if (removeMediaIds != null && removeMediaIds.isNotEmpty) {
        for (var i = 0; i < removeMediaIds.length; i++) {
          formData.fields.add(MapEntry('remove_media[$i]', removeMediaIds[i].toString()));
        }
      }

      final response = await _dio.post('/posts/$postId', data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Hide a post from timeline.
  Future<Map<String, dynamic>> hidePost(int postId) async {
    try {
      final response = await _dio.post('/posts/$postId/hide');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Unhide a post.
  Future<Map<String, dynamic>> unhidePost(int postId) async {
    try {
      final response = await _dio.post('/posts/$postId/unhide');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Report a post.
  Future<Map<String, dynamic>> reportPost(int postId, String reason, String? details) async {
    try {
      final response = await _dio.post('/posts/$postId/report', data: {
        'reason': reason,
        'details': details,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a post.
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final response = await _dio.delete('/posts/$postId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get paginated reactions for a post or comment.
  Future<Map<String, dynamic>> getReactions(int id, {int page = 1, String type = 'all', String model = 'post'}) async {
    try {
      final response = await _dio.get(
        '/reactions/post/$id',
        queryParameters: {
          'page': page,
          'type': type,
          'model': model,
        },
      );
      final data = response.data;

      final reactions = (data['data'] as List)
          .map((r) => ReactionModel.fromJson(r))
          .toList();

      return {
        'reactions': reactions,
        'summary': data['summary'],
        'currentPage': data['current_page'],
        'lastPage': data['last_page'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Search for users to tag or mention.
  Future<List<UserModel>> searchUsers(String query, {bool friendsOnly = true}) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {
          'q': query,
          if (friendsOnly) 'friends_only': 1,
        },
      );
      return (response.data['data'] as List)
          .map((u) => UserModel.fromJson(u))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Global search for users, groups, and posts.
  Future<Map<String, dynamic>> globalSearch(String query) async {
    try {
      final response = await _dio.get('/search', queryParameters: {'q': query});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get paginated watch videos.
  Future<Map<String, dynamic>> getWatchVideos(int page) async {
    try {
      final response = await _dio.get('/feed/watch', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
