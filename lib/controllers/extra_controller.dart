import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../utils/app_theme.dart';
import '../data/models/post_model.dart';
import '../data/models/product_model.dart';
import '../data/models/common_user_model.dart';
import '../data/models/report_model.dart';
import '../data/services/extra_service.dart';
import '../data/services/profile_service.dart';
import 'feed_controller.dart';

class ExtraController extends GetxController {
  final ExtraService _extraService = ExtraService();
  final ProfileService _profileService = Get.find<ProfileService>();

  // Memories
  var memories = <PostModel>[].obs;
  var memoriesLoading = false.obs;
  var memoriesPage = 1;
  var hasMoreMemories = true.obs;

  // Common Things
  var commonUsers = <CommonUserModel>[].obs;
  var commonLoading = false.obs;
  var commonPage = 1;
  var hasMoreCommon = true.obs;

  // Saved Items
  var savedPosts = <PostModel>[].obs;
  var savedPostsLoading = false.obs;
  var savedPostsPage = 1;
  var hasMoreSavedPosts = true.obs;

  var savedProducts = <ProductModel>[].obs;
  var savedProductsLoading = false.obs;
  var savedProductsPage = 1;
  var hasMoreSavedProducts = true.obs;

  Future<void> fetchMemories({bool refresh = false}) async {
    if (refresh) {
      memoriesPage = 1;
      memories.clear();
      hasMoreMemories.value = true;
    }
    if (!hasMoreMemories.value || memoriesLoading.value) return;

    memoriesLoading.value = true;
    try {
      final response = await _extraService.getMemories(memoriesPage);
      if (response['success']) {
        final List data = response['data'];
        final posts = data.map((e) => PostModel.fromJson(e)).toList();
        memories.addAll(posts);
        hasMoreMemories.value = response['next_page_url'] != null;
        if (posts.isNotEmpty) memoriesPage++;
      }
    } catch (e) {
      debugPrint('Error fetching memories: $e');
    } finally {
      memoriesLoading.value = false;
    }
  }

  Future<void> fetchCommonUsers({bool refresh = false}) async {
    if (refresh) {
      commonPage = 1;
      commonUsers.clear();
      hasMoreCommon.value = true;
    }
    if (!hasMoreCommon.value || commonLoading.value) return;

    commonLoading.value = true;
    try {
      final response = await _extraService.getCommonUsers(commonPage);
      if (response['success']) {
        final List data = response['data'];
        final users = data.map((e) => CommonUserModel.fromJson(e)).toList();
        commonUsers.addAll(users);
        hasMoreCommon.value = response['next_page_url'] != null;
        if (users.isNotEmpty) commonPage++;
      }
    } catch (e) {
      debugPrint('Error fetching common users: $e');
    } finally {
      commonLoading.value = false;
    }
  }

  Future<void> fetchSavedPosts({bool refresh = false}) async {
    if (refresh) {
      savedPostsPage = 1;
      savedPosts.clear();
      hasMoreSavedPosts.value = true;
    }
    if (!hasMoreSavedPosts.value || savedPostsLoading.value) return;

    savedPostsLoading.value = true;
    try {
      final response = await _extraService.getSavedPosts(savedPostsPage);
      if (response['success']) {
        final List data = response['data'];
        final posts = data.map((e) => PostModel.fromJson(e)).toList();
        savedPosts.addAll(posts);
        hasMoreSavedPosts.value = response['next_page_url'] != null;
        if (posts.isNotEmpty) savedPostsPage++;
      }
    } catch (e) {
      debugPrint('Error fetching saved posts: $e');
    } finally {
      savedPostsLoading.value = false;
    }
  }

  Future<void> fetchSavedProducts({bool refresh = false}) async {
    if (refresh) {
      savedProductsPage = 1;
      savedProducts.clear();
      hasMoreSavedProducts.value = true;
    }
    if (!hasMoreSavedProducts.value || savedProductsLoading.value) return;

    savedProductsLoading.value = true;
    try {
      final response = await _extraService.getSavedProducts(savedProductsPage);
      if (response['success']) {
        final List data = response['data'];
        final products = data.map((e) => ProductModel.fromJson(e)).toList();
        savedProducts.addAll(products);
        hasMoreSavedProducts.value = response['next_page_url'] != null;
        if (products.isNotEmpty) savedProductsPage++;
      }
    } catch (e) {
      debugPrint('Error fetching saved products: $e');
    } finally {
      savedProductsLoading.value = false;
    }
  }

  Future<void> sendFriendRequest(int userId) async {
    try {
      final result = await _profileService.sendFriendRequest(userId);
      if (result['success'] == true) {
        Get.snackbar(
          'Success', 
          'Friend request sent!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        commonUsers.removeWhere((u) => u.id == userId);
      } else {
        Get.snackbar('error'.tr, result['message'] ?? 'failed_to_send_request'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'something_went_wrong'.tr);
    }
  }

  // Hidden Posts
  var hiddenPosts = <PostModel>[].obs;
  var hiddenPostsLoading = false.obs;
  var hiddenPostsPage = 1;
  var hasMoreHiddenPosts = true.obs;

  // My Reports
  var myReports = <ReportModel>[].obs;
  var myReportsLoading = false.obs;
  var myReportsPage = 1;
  var hasMoreMyReports = true.obs;

  Future<void> fetchHiddenPosts({bool refresh = false}) async {
    if (refresh) {
      hiddenPostsPage = 1;
      hiddenPosts.clear();
      hasMoreHiddenPosts.value = true;
    }
    if (!hasMoreHiddenPosts.value || hiddenPostsLoading.value) return;

    hiddenPostsLoading.value = true;
    try {
      final response = await _extraService.getHiddenPosts(hiddenPostsPage);
      if (response['success']) {
        final List data = response['data'];
        final posts = data.map((e) => PostModel.fromJson(e)).toList();
        hiddenPosts.addAll(posts);
        hasMoreHiddenPosts.value = response['next_page_url'] != null;
        if (posts.isNotEmpty) hiddenPostsPage++;
      }
    } catch (e) {
      debugPrint('Error fetching hidden posts: $e');
    } finally {
      hiddenPostsLoading.value = false;
    }
  }

  Future<void> unhidePost(int postId) async {
    try {
      final feedController = Get.find<FeedController>();
      await feedController.unhidePost(postId);
      hiddenPosts.removeWhere((p) => p.id == postId);
    } catch (e) {
      debugPrint('Error unhiding post: $e');
    }
  }

  Future<void> fetchMyReports({bool refresh = false}) async {
    if (refresh) {
      myReportsPage = 1;
      myReports.clear();
      hasMoreMyReports.value = true;
    }
    if (!hasMoreMyReports.value || myReportsLoading.value) return;

    myReportsLoading.value = true;
    try {
      final response = await _extraService.getMyReports(myReportsPage);
      if (response['success']) {
        final List data = response['data'];
        final reports = data.map((e) => ReportModel.fromJson(e)).toList();
        myReports.addAll(reports);
        hasMoreMyReports.value = response['next_page_url'] != null;
        if (reports.isNotEmpty) myReportsPage++;
      }
    } catch (e) {
      debugPrint('Error fetching my reports: $e');
    } finally {
      myReportsLoading.value = false;
    }
  }
}
