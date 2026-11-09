import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:influx_app/pages/auth/auth_page.dart';

import '../data/services/auth_service.dart';
import '../pages/auth/verify_otp.dart';

class VerificationCodeController extends GetxController {
  bool isLoading = false;
  String error = '';

  Future<void> verifyCodeForSignUp({
    required String otp,
    required VerifyOtpArguments argument,
  }) async {
    isLoading = true;
    error = '';
    update();
    final AuthService authService = AuthService();
    final response = await authService.verifyOTP({
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
      Get.offAll(() => const AuthPage());
    } else {
      Get.snackbar(
        'success'.tr,
        response.data['message'],
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }
}
