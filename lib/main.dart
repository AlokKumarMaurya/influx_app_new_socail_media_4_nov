import 'package:material_ui/material_ui.dart' hide ThemeMode;
import 'package:flutter/foundation.dart';
import 'services/network_inspector.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'pages/splash/splash_page.dart';
import 'utils/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'data/providers/api_client.dart';
import 'data/services/profile_service.dart';
import 'data/services/group_service.dart';
import 'data/services/settings_service.dart';
import 'controllers/user_settings_controller.dart';
import 'controllers/custom_page_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/feed_controller.dart';
import 'data/services/deep_link_service.dart';
import 'config/app_config.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:flutter_localizations/flutter_localizations.dart' hide GlobalMaterialLocalizations;
import 'controllers/language_controller.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  if (kDebugMode) {
    NetworkInspector.initialize();
  }
  Stripe.publishableKey = 'pk_test_placeholder';
  try {
    await Stripe.instance.applySettings();
  } catch (_) {}
  
  // Register Global Services
  Get.put(ApiClient());
  Get.put(SettingsService());
  Get.put(ProfileService());
  Get.put(GroupService());

  // Initialize Global Controllers
  Get.put(LanguageController());
  Get.put(SettingsController());
  Get.put(AuthController());
  Get.put(UserSettingsController());
  Get.put(CustomPageController());
  Get.put(ChatController(), permanent: true);
  Get.put(FeedController(), permanent: true);

  // Initialize Deep Linking System
  DeepLinkService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final languageController = Get.find<LanguageController>();
    
    return Obx(() {
      return GetMaterialApp(
        navigatorKey: NetworkInspector.navigatorKey,
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settingsController.themeMode.value,
        translations: AppTranslations(),
        locale: languageController.currentLocale.value,
        fallbackLocale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              const NetworkInspectorLauncher(),
            ],
          );
        },
        localeResolutionCallback: (deviceLocale, supportedLocales) {
          // Always honor the app's default/selected language instead of device system locale
          return languageController.currentLocale.value;
        },
        home: const SplashPage(),
      );
    });
  }
}
