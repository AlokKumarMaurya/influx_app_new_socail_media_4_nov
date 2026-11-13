import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../utils/app_theme.dart';
import '../../config/app_config.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/version_comparator.dart';
import '../app_control/maintenance_screen.dart';
import '../../widgets/app_control/update_dialog.dart';
import '../main_screen.dart';
import '../onboarding/onboarding_page.dart';
import '../auth/auth_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    final minTimer = Future.delayed(const Duration(seconds: 2));
    final settingsController = Get.put(SettingsController());
    final authController = Get.put(AuthController());
    final storage = GetStorage();

    await Future.wait([
      settingsController.fetchSettings(),
      authController.verifySession(),
      minTimer,
    ]);

    if (!mounted) return;

    // Detect Current App Version
    String currentVersion = AppConfig.appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        currentVersion = info.version;
      }
    } catch (_) {}

    final appControl = settingsController.appControl.value;

    // 1. Maintenance Mode Check (Highest Priority)
    if (appControl.maintenanceMode) {
      Get.offAll(() => const MaintenanceScreen());
      return;
    }

    final hasSeenOnboarding = storage.read('has_seen_onboarding') == true;

    // 2. App Version Enforcement Check
    final isLowerThanMin = VersionComparator.isLowerThan(
        currentVersion, appControl.minVersion);
    final isLowerThanLatest = VersionComparator.isLowerThan(
        currentVersion, appControl.latestVersion);

    if (isLowerThanMin || (isLowerThanLatest && appControl.forceUpdate)) {
      // Mandatory Update Required:
      // Show two-step dialog first; if user dismisses, it opens ForceUpdateScreen
      UpdateDialog.show(
        appControl: appControl,
        currentVersion: currentVersion,
        isForced: true,
      );
      return;
    } else if (isLowerThanLatest && !appControl.forceUpdate) {
      // Optional Update Available
      UpdateDialog.show(
        appControl: appControl,
        currentVersion: currentVersion,
        isForced: false,
        onOptionalContinue: () {
          _proceedToApp(hasSeenOnboarding, authController);
        },
      );
      return;
    }

    _proceedToApp(hasSeenOnboarding, authController);
  }

  void _proceedToApp(bool hasSeenOnboarding, AuthController authController) {
    if (!hasSeenOnboarding) {
      Get.off(() => const OnboardingPage());
    } else {
      if (authController.isAuthenticated.value) {
        Get.off(() => const MainScreen());
      } else {
        Get.off(() => const AuthPage());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Logo
                Image.asset(AppConfig.logoPath, height: 120),

                const SizedBox(height: 24),
                Text(
                  AppConfig.appName,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 40,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect. Share. Grow.',
                  style: AppTextStyles.bodyMedium.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
