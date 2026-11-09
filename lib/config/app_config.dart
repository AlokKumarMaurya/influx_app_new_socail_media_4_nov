import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Hme Company';

  // Base URL for the API
  static const String baseUrl = 'https://staging.hmecompany.com/api';

  // Separate customer mall catalogue API.
  static const String mallBaseUrl = 'https://mall.hmecompany.com/api';
  static const String mallApiKey = String.fromEnvironment('MALL_API_KEY');

  // Deep Linking Configuration:
  // 1. webDomain: Set your web domain without protocol (e.g. '127.0.0.1:8000', 'influx.com', or 'social.mydomain.com')
  static const String webDomain = 'influx.mhquickdev.com';

  // 2. deepLinkScheme: Custom URL scheme for opening the app directly (e.g. 'influx://')
  static const String deepLinkScheme = 'influx';

  static const String appVersion = '2.0.0';

  // Default App Language ('en', 'bn', 'it', etc.)
  static const String defaultLanguage = 'en';

  // static const Color primaryColor = Color(0xFF3EAFFF);
  static const Color primaryColor = Color(0xFFfc7700);
  static const String logoPath = 'assets/images/logo/logo.png';

  // Derived web base URL
  static String get webBaseUrl => baseUrl.replaceAll('/api', '');
}
