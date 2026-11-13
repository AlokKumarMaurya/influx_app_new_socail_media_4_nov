import 'package:material_ui/material_ui.dart' hide TextButton;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:influx_app/data/models/sign_up_getcountries_List_response._modal.dart';
import '../data/models/auth_response.dart';
import '../data/services/auth_service.dart';
import '../data/providers/api_client.dart';
import '../data/models/user_model.dart';
import '../pages/auth/verify_otp.dart';
import '../pages/main_screen.dart';
import '../pages/auth/auth_page.dart';
import './feed_controller.dart';
import './custom_page_controller.dart';
import './chat_controller.dart';
import './user_settings_controller.dart';
import '../data/services/push_notification_service.dart';
import 'package:flutter/material.dart' show TextButton;

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final GetStorage _storage = GetStorage();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  var isLoading = false.obs;
  var isAuthenticated = false.obs;
  var user = Rxn<UserModel>();
  var countries = Rxn<GetCountriesListResponseModal>();
  String? selectedCountryId;

  @override
  void onInit() {
    super.onInit();
    verifySession();
    getCountry();
  }

  Future<void> verifySession() async {
    String? token = await _secureStorage.read(key: 'token');

    // Migrate legacy token from GetStorage to secure storage if present
    if (token == null && _storage.hasData('token')) {
      final legacyToken = _storage.read('token');
      if (legacyToken != null) {
        token = legacyToken.toString();
        await _secureStorage.write(key: 'token', value: token);
      }
      await _storage.remove('token');
    }

    if (token == null) {
      isAuthenticated.value = false;
      return;
    }

    try {
      // Set token in dio headers
      ApiClient().dio.options.headers['Authorization'] = 'Bearer $token';

      // Active verification with server
      final response = await ApiClient().dio.get('/user');
      if (response.statusCode == 200) {
        user.value = UserModel.fromJson(response.data);
        isAuthenticated.value = true;
        if (user.value?.id != null) {
          PushNotificationService.setExternalUserId(user.value!.id.toString());
        }
        if (Get.isRegistered<UserSettingsController>()) {
          Get.find<UserSettingsController>().initFields();
        }
      } else {
        logout();
      }
    } catch (e) {
      logout();
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool showError = true,
  }) async {
    try {
      isLoading.value = true;
      final response = await _authService.login(email, password);
      await _handleAuthSuccess(response);
      return isAuthenticated.value;
    } catch (e) {
      if (showError) {
        String message = 'Login failed';
        bool isUnverified = false;
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            message = data['message']?.toString() ?? message;
            if (data['code'] == 'EMAIL_UNVERIFIED' ||
                (e.response?.statusCode == 403 && message.contains('activate'))) {
              isUnverified = true;
            }
          } else if (data is String) {
            message = data;
          }
        }
        Get.snackbar(
          isUnverified ? 'Account Unverified' : 'Error',
          message,
          backgroundColor: isUnverified ? Colors.orange.shade900 : Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 7),
          mainButton: isUnverified
              ? TextButton(
                  onPressed: () => resendVerification(email),
                  child: Text(
                    'resend_email'.tr,
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        );
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
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
      isLoading.value = true;
      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        countryId: countryId,
      );
      Get.to(
        VerificationCodeView(
          argument: VerifyOtpArguments(
            signUpRequest: SignUpRequestModal(
              phone: phone,
              passwordConfirmation: passwordConfirmation,
              password: password,
              lastName: lastName,
              firstName: firstName,
              email: email,
              username: username,
              isAutoFill: response.isOtpAvailable == true,
              otp: response.data?.otp,
            ),
            token: response.data!.token!,
          ),
        ),
      );
      // await _handleAuthSuccess(response);
    } catch (e) {
      String message = 'registration_failed'.tr;
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          final errors = data['errors'];
          if (errors != null && errors is Map && errors.isNotEmpty) {
            final List<String> errorList = [];
            for (final fieldErrors in errors.values) {
              if (fieldErrors is List) {
                for (final err in fieldErrors) {
                  final str = err.toString();
                  errorList.add(str.tr);
                }
              } else if (fieldErrors is String) {
                errorList.add(fieldErrors.tr);
              }
            }
            if (errorList.isNotEmpty) {
              message = errorList.join('\n');
            } else {
              message = (data['message']?.toString() ?? message).tr;
            }
          } else {
            message = (data['message']?.toString() ?? message).tr;
          }
        } else if (data is String) {
          message = data.tr;
        }
      }
      Get.snackbar(
        'error'.tr,
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendVerification(String email) async {
    if (email.trim().isEmpty) {
      Get.snackbar(
        'error'.tr,
        'enter_email_address'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    try {
      isLoading.value = true;
      await _authService.resendVerification(email);
      Get.snackbar(
        'email_sent'.tr,
        'activation_link_resent'.tr,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      String message = 'failed_resend_activation_email'.tr;
      if (e is DioException && e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }
      Get.snackbar(
        'error'.tr,
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCountry() async {
    try {
      isLoading.value = true;

      final res = await _authService.getCountry();
      countries.value = res;

      final countryList = countries.value?.data;

      if (countryList != null && countryList.isNotEmpty) {
        // Find India using phone code 91
        final india = countryList.where((country) => country.phoneCode == "91");

        if (india.isNotEmpty) {
          selectedCountryId = india.first.id.toString();
        } else {
          // Fallback to first country
          selectedCountryId = countryList.first.id.toString();
        }
      } else {
        selectedCountryId = '';
      }
    } catch (e) {
      debugPrint('Error fetching countries: $e');
      selectedCountryId = '';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      isLoading.value = true;
      await _authService.forgotPassword(email);
      Get.snackbar(
        'success'.tr,
        'reset_link_sent'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_send_reset_link'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleAuthSuccess(AuthResponse response) async {
    if (response.accessToken == null || response.user == null) return;
    final token = response.accessToken!;
    final userData = response.user!;

    await _secureStorage.write(key: 'token', value: token);
    await _storage.remove('token'); // Remove legacy plain text token if present
    _storage.write('user', userData.toJson());

    // Set token for future requests
    ApiClient().dio.options.headers['Authorization'] = 'Bearer $token';

    user.value = userData;
    isAuthenticated.value = true;
    PushNotificationService.setExternalUserId(userData.id.toString());

    _storage.write('selected_country', 'all');
    _storage.write('selected_country_chosen', true);
    // if (userData.country != null && userData.country!.isNotEmpty) {
    //   _storage.write('selected_country', userData.country);
    //   _storage.write('selected_country_chosen', true);
    // } else {
    //   _storage.remove('selected_country_chosen');
    // }

    // Refresh global/permanent controllers with the new token
    if (Get.isRegistered<FeedController>()) {
      Get.find<FeedController>().loadFeed();
    }
    if (Get.isRegistered<CustomPageController>()) {
      Get.find<CustomPageController>().fetchPages();
    }
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().loadConversations();
    }
    if (Get.isRegistered<UserSettingsController>()) {
      final settingsCtrl = Get.find<UserSettingsController>();
      settingsCtrl.initFields();
      settingsCtrl.fetchSessions();
      settingsCtrl.fetchBlockedUsers();
      settingsCtrl.fetchKycStatus();
      settingsCtrl.fetchProfessionalStatus();
    }

    Get.offAll(() => const MainScreen());
  }

  void logout() async {
    try {
      PushNotificationService.removeExternalUserId();
    } catch (_) {}

    try {
      await _authService.logout();
    } catch (e) {
      Get.log('Logout API error: $e');
    }

    await _secureStorage.delete(key: 'token');
    await _storage.remove('token'); // Remove legacy plain text token if present
    await _storage.remove('user');
    await _storage.remove('selected_country_chosen');

    ApiClient().dio.options.headers.remove('Authorization');

    isAuthenticated.value = false;
    user.value = null;
    Get.offAll(() => const AuthPage());
  }
}
