import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../config/app_config.dart';
import '../data/models/app_control_model.dart';
import '../data/providers/api_client.dart';
import '../data/services/push_notification_service.dart';

class SettingsController extends GetxController {
  final GetStorage _storage = GetStorage();

  var isLoading = false.obs;
  var currency = 'USD'.obs;
  var currencySymbol = '\$'.obs;
  var siteName = AppConfig.appName.obs;
  var themeMode = ThemeMode.system.obs;
  var appControl = const AppControlModel().obs;

  @override
  void onInit() {
    super.onInit();
    _loadLocalSettings();
    _loadTheme();
  }

  void _loadTheme() {
    String? theme = _storage.read('theme');
    if (theme == 'dark') {
      themeMode.value = ThemeMode.dark;
      Get.changeThemeMode(ThemeMode.dark);
    } else if (theme == 'light') {
      themeMode.value = ThemeMode.light;
      Get.changeThemeMode(ThemeMode.light);
    } else {
      themeMode.value = ThemeMode.system;
      Get.changeThemeMode(ThemeMode.system);
    }
  }

  void changeTheme(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    if (mode == ThemeMode.dark) {
      _storage.write('theme', 'dark');
    } else if (mode == ThemeMode.light) {
      _storage.write('theme', 'light');
    } else {
      _storage.remove('theme');
    }
  }

  void _loadLocalSettings() {
    currency.value = _storage.read('currency') ?? 'USD';
    currencySymbol.value = _storage.read('currency_symbol') ?? '\$';
    siteName.value = _storage.read('site_name') ?? AppConfig.appName;

    final cachedAppControl = _storage.read('app_control');
    if (cachedAppControl != null && cachedAppControl is Map) {
      appControl.value = AppControlModel.fromJson(
          Map<String, dynamic>.from(cachedAppControl));
    }
  }

  Future<void> fetchSettings() async {
    try {
      isLoading.value = true;
      final response = await ApiClient().dio.get('/app-config');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          currency.value = data['currency_code'] ?? 'USD';
          currencySymbol.value = data['currency_symbol'] ?? '\$';
          _storage.write('currency', currency.value);
          _storage.write('currency_symbol', currencySymbol.value);

          // Parse App Control & Versioning Settings
          if (data['app_control'] != null && data['app_control'] is Map) {
            appControl.value = AppControlModel.fromJson(
                Map<String, dynamic>.from(data['app_control']));
            _storage.write('app_control', data['app_control']);
          }

          // Initialize OneSignal Push Notifications if enabled
          final pushConfig = data['push_notification'];
          if (pushConfig != null && pushConfig['enabled'] == true) {
            final appId = pushConfig['app_id']?.toString() ?? '';
            if (appId.isNotEmpty) {
              await PushNotificationService.initialize(appId);
            }
          }
        }
      }
    } catch (e) {
      Get.log('Error fetching settings: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

