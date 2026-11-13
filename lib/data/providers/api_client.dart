import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/network_inspector.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      NetworkInspector.attachTo(dio);
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        const secureStorage = FlutterSecureStorage();
        String? token = await secureStorage.read(key: 'token');
        
        // Fallback to legacy GetStorage if secure storage is empty (in case verifySession hasn't run yet)
        if (token == null) {
          final legacyStorage = GetStorage();
          token = legacyStorage.read('token');
        }

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Add active locale header for backend multi-language API responses
        final storage = GetStorage();
        final lang = storage.read<String>('app_language') ?? AppConfig.defaultLanguage;
        options.headers['Accept-Language'] = lang;
        options.headers['X-Locale'] = lang;

        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // Handle unauthorized (e.g., redirect to login)
        }
        return handler.next(e);
      },
    ));
  }
}
