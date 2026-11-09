import 'package:get/get.dart';
import 'feed_controller.dart';
import 'discover_feed_controller.dart';
import 'auth_controller.dart';
import '../pages/auth/auth_page.dart';

class MainController extends GetxController {
  var currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  void _checkAuth() {
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated.value) {
      Future.microtask(() => Get.offAll(() => const AuthPage()));
    }
  }

  void changeIndex(int index) {
    if (currentIndex.value == index) {
      // If same index is tapped again
      if (index == 0) {
        // News Feed tab
        if (Get.isRegistered<FeedController>()) {
          Get.find<FeedController>().scrollToTopAndRefresh();
        }
      } else if (index == 1) {
        // Creator campaign tab
        if (Get.isRegistered<DiscoverFeedController>()) {
          Get.find<DiscoverFeedController>().refreshData();
        }
      }
    } else {
      currentIndex.value = index;
    }
  }

  Future<bool> handleBack() async {
    if (currentIndex.value != 0) {
      changeIndex(0);
      return false; // Handled locally, don't exit
    }
    return true; // Allow exit
  }
}
