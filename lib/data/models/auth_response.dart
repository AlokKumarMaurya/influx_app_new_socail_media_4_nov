import 'user_model.dart';

class AuthResponse {
  final String? accessToken;
  final UserModel? user;
  final bool requireVerification;
  final String? message;

  AuthResponse({
    this.accessToken,
    this.user,
    this.requireVerification = false,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      requireVerification: json['require_verification'] == true,
      message: json['message'] as String?,
    );
  }
}
