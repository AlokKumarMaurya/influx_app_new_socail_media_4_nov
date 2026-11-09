import 'package:dio/dio.dart';
import 'package:influx_app/data/models/register_response.dart';
import 'package:influx_app/data/models/sign_up_getcountries_List_response._modal.dart';
import '../providers/api_client.dart';
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<AuthResponse> login(String login, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'login': login, 'password': password},
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String countryId,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
          'country_id': countryId,
        },
      );
      return RegisterResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/forgot-password', data: {'email': email});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _dio.post('/resend-verification', data: {'email': email});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String password) async {
    try {
      await _dio.post(
        '/reset-password',
        data: {
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> verifyOTP(Map<String,dynamic> json) async {
    try {
     return await _dio.post(
        '/verify-otp',
        data: json,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<GetCountriesListResponseModal> getCountry() async {
    try {
      final res = await _dio.post('/countries', data: {});
      return GetCountriesListResponseModal.fromJson(res.data);
    } catch (e) {
      rethrow;
    }
  }
}
