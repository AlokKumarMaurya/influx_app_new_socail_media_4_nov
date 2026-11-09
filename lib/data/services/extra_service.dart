import 'package:dio/dio.dart';
import '../providers/api_client.dart';
class ExtraService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getMemories(int page) async {
    try {
      final response = await _dio.get('/memories', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCommonUsers(int page) async {
    try {
      final response = await _dio.get('/common-things', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSavedPosts(int page) async {
    try {
      final response = await _dio.get('/saved-posts', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSavedProducts(int page) async {
    try {
      final response = await _dio.get('/saved-products', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHiddenPosts(int page) async {
    try {
      final response = await _dio.get('/hidden-posts', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyReports(int page) async {
    try {
      final response = await _dio.get('/my-reports', queryParameters: {'page': page});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
