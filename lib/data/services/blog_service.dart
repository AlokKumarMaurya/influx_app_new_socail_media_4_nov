import 'dart:io';
import 'package:dio/dio.dart';
import '../providers/api_client.dart';
import '../models/blog_model.dart';
import '../models/creator_model.dart';

class BlogService {
  final Dio _dio = ApiClient().dio;

  /// Get blog homepage data (hero, featured, latest).
  Future<Map<String, dynamic>> getBlogs({int page = 1}) async {
    try {
      final response = await _dio.get('/blogs', queryParameters: {'page': page});
      final data = response.data;

      return {
        'hero': data['hero'] != null ? BlogModel.fromJson(data['hero']) : null,
        'featured': (data['featured'] as List?)
                ?.map((b) => BlogModel.fromJson(b))
                .toList() ??
            [],
        'latest': (data['latest']?['data'] as List?)
                ?.map((b) => BlogModel.fromJson(b))
                .toList() ??
            [],
        'categories': List<String>.from(data['categories'] ?? []),
        'currentPage': data['latest']?['current_page'] ?? 1,
        'lastPage': data['latest']?['last_page'] ?? 1,
        'nextPageUrl': data['latest']?['next_page_url'],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get single blog by slug.
  Future<Map<String, dynamic>> getBlog(String slug) async {
    try {
      final response = await _dio.get('/blogs/$slug');
      final data = response.data;

      return {
        'blog': BlogModel.fromJson(data['data']),
        'related': (data['related'] as List?)
                ?.map((b) => BlogModel.fromJson(b))
                .toList() ??
            [],
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user's blogs.
  Future<Map<String, dynamic>> getMyBlogs({int page = 1}) async {
    try {
      final response = await _dio.get('/blogs/my', queryParameters: {'page': page});
      final data = response.data;

      return {
        'blogs': (data['data'] as List?)
                ?.map((b) => BlogModel.fromJson(b))
                .toList() ??
            [],
        'currentPage': data['current_page'] ?? 1,
        'lastPage': data['last_page'] ?? 1,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new blog.
  Future<Map<String, dynamic>> createBlog({
    required String title,
    required String content,
    required String status,
    String? excerpt,
    String? category,
    String? tags,
    File? featuredImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'content': content,
        'status': status,
        'excerpt': ?excerpt,
        'category': ?category,
        'tags': ?tags,
        if (featuredImage != null)
          'featured_image': await MultipartFile.fromFile(
            featuredImage.path,
            filename: featuredImage.path.split('/').last,
          ),
      });

      final response = await _dio.post('/blogs', data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a blog.
  Future<Map<String, dynamic>> updateBlog({
    required int id,
    required String title,
    required String content,
    required String status,
    String? excerpt,
    String? category,
    String? tags,
    File? featuredImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'content': content,
        'status': status,
        'excerpt': ?excerpt,
        'category': ?category,
        'tags': ?tags,
        if (featuredImage != null)
          'featured_image': await MultipartFile.fromFile(
            featuredImage.path,
            filename: featuredImage.path.split('/').last,
          ),
      });

      final response = await _dio.post('/blogs/$id', data: formData);
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a blog.
  Future<Map<String, dynamic>> deleteBlog(int id) async {
    try {
      final response = await _dio.delete('/blogs/$id');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get discover creators list.
  Future<Map<String, dynamic>> getCreators({int page = 1}) async {
    try {
      final response = await _dio.get('/creators', queryParameters: {'page': page});
      final data = response.data;

      return {
        'creators': (data['data'] as List?)
                ?.map((c) => CreatorModel.fromJson(c))
                .toList() ??
            [],
        'currentPage': data['current_page'] ?? 1,
        'lastPage': data['last_page'] ?? 1,
        'nextPageUrl': data['next_page_url'],
      };
    } catch (e) {
      rethrow;
    }
  }
}
