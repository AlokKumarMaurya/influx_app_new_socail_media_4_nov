import 'package:dio/dio.dart';
import '../providers/api_client.dart';

class CreatorService {
  final Dio _dio = ApiClient().dio;

  /// GET /api/creator/dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get('/creator/dashboard');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
