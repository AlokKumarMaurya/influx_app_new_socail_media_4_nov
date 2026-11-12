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

      if (response.statusCode == 200) {
        final credentials = argument.signUpRequest;
        final loginIdentifier = credentials.email?.trim().isNotEmpty == true
            ? credentials.email!.trim()
            : (credentials.username ?? '').trim();
        final password = credentials.password ?? '';

        if (loginIdentifier.isNotEmpty && password.isNotEmpty) {
          // Reuse the existing login flow so token persistence, profile setup,
          // push registration and post-login navigation stay consistent.
          final authController = Get.find<AuthController>();
          await authController.login(loginIdentifier, password);

          if (authController.isAuthenticated.value) return;
        }

        // If automatic login cannot complete, let the user sign in manually
        // instead of leaving the OTP screen stuck behind its loading overlay.
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
