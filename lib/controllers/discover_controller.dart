import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../data/models/creator_model.dart';
import '../data/services/blog_service.dart';
import '../data/services/profile_service.dart';
import '../utils/app_theme.dart';

class DiscoverController extends GetxController {
  final BlogService _blogService = BlogService();
  final ProfileService _profileService = ProfileService();

  final creators = <CreatorModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;

  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void onInit() {
    super.onInit();
    loadCreators();
  }

  Future<void> loadCreators() async {
    isLoading.value = true;
    _currentPage = 1;

    try {
      final result = await _blogService.getCreators(page: 1);
      creators.value = result['creators'] as List<CreatorModel>;
      _currentPage = result['currentPage'] as int;
      _lastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load creators error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCreators() async {
    await loadCreators();
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || _currentPage >= _lastPage) return;
    isLoadingMore.value = true;

    try {
      final result = await _blogService.getCreators(page: _currentPage + 1);
      final newCreators = result['creators'] as List<CreatorModel>;
      creators.addAll(newCreators);
      _currentPage = result['currentPage'] as int;
      _lastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load more creators error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> sendFriendRequest(int userId) async {
    try {
      await _profileService.sendFriendRequest(userId);
      final index = creators.indexWhere((c) => c.id == userId);
      if (index != -1) {
        final c = creators[index];
        creators[index] = CreatorModel(
          id: c.id,
          name: c.name,
          username: c.username,
          avatar: c.avatar,
          cover: c.cover,
          bio: c.bio,
          work: c.work,
          profileType: c.profileType,
          socialLinks: c.socialLinks,
          stats: c.stats,
          relation: 'pending_sent',
        );
      }
      Get.snackbar('success'.tr, 'friend_request_sent_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_send_friend_request'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  Future<void> cancelFriendRequest(int userId) async {
    try {
      await _profileService.cancelFriendRequest(userId);
      final index = creators.indexWhere((c) => c.id == userId);
      if (index != -1) {
        final c = creators[index];
        creators[index] = CreatorModel(
          id: c.id,
          name: c.name,
          username: c.username,
          avatar: c.avatar,
          cover: c.cover,
          bio: c.bio,
          work: c.work,
          profileType: c.profileType,
          socialLinks: c.socialLinks,
          stats: c.stats,
          relation: 'none',
        );
      }
    } catch (e) {
      Get.log('Cancel friend request error: $e');
    }
  }
}
