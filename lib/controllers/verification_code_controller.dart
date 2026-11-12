import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:influx_app/controllers/auth_controller.dart';
import 'package:influx_app/pages/auth/auth_page.dart';

import '../data/services/auth_service.dart';
import '../pages/auth/verify_otp.dart';

class VerificationCodeController extends GetxController {
  bool isLoading = false;
  bool _verificationInProgress = false;
  String error = '';

  Future<void> verifyCodeForSignUp({
    required String otp,
    required VerifyOtpArguments argument,
  }) async {
    if (_verificationInProgress) return;

    _verificationInProgress = true;
    isLoading = true;
    error = '';
    update();

    try {
      final response = await AuthService().verifyOTP({
        "first_name": argument.signUpRequest.firstName ?? '',
        "last_name": argument.signUpRequest.lastName ?? '',
        "number": argument.signUpRequest.phone ?? '',
        "user_name": argument.signUpRequest.username ?? "",
        "password": argument.signUpRequest.password ?? '',
        "confirm_password": argument.signUpRequest.passwordConfirmation ?? '',
        "code": otp,
        "token": argument.token,
      });

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final credentials = argument.signUpRequest;
        final email = (credentials.email ?? '').trim();
        final username = (credentials.username ?? '').trim();
        final password = credentials.password ?? '';

        if (password.isNotEmpty) {
          // Reuse the app's existing login method. The API accepts either
          // email or username in its "login" field, so try both credentials
          // when they are present instead of assuming email is accepted.
          final authController = Get.find<AuthController>();
          final identifiers = <String>[
            if (email.isNotEmpty) email,
            if (username.isNotEmpty && username.toLowerCase() != email.toLowerCase())
              username,
          ];

          for (final identifier in identifiers) {
            final loggedIn = await authController.login(
              identifier,
              password,
              showError: false,
            );
            if (loggedIn || authController.isAuthenticated.value) return;
          }
        }

        error = 'OTP verified, but automatic login failed. Please log in.';
        Get.snackbar(
          'Verification successful',
          error,
          backgroundColor: Colors.orange.shade900,
          colorText: Colors.white,
          duration: const Duration(seconds: 6),
        );
        Get.offAll(() => const AuthPage());
      } else {
        final message = response.data is Map
            ? (response.data['message']?.toString() ?? 'OTP verification failed')
            : 'OTP verification failed';
        error = message;
        Get.snackbar(
          'Verification failed',
          message,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map
          ? (data['message']?.toString() ?? 'OTP verification failed')
          : (data is String ? data : 'OTP verification failed');
      error = message;
      Get.snackbar(
        'Verification failed',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      error = 'OTP verification failed. Please try again.';
      Get.snackbar(
        'Verification failed',
        error,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
      _verificationInProgress = false;
      update();
    }
  }
}
