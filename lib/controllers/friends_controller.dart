import 'package:get/get.dart';
import 'auth_controller.dart';
import '../data/models/friend_request_model.dart';
import '../data/models/user_model.dart';
import '../data/services/profile_service.dart';

class FriendsController extends GetxController {
  final ProfileService _profileService = Get.find<ProfileService>();
  
  final requests = <FriendRequestModel>[].obs;
  final suggestions = <UserModel>[].obs;
  final friends = <UserModel>[].obs;
  final filteredFriends = <UserModel>[].obs;
  
  final isLoadingRequests = false.obs;
  final isLoadingSuggestions = false.obs;
  final isLoadingFriends = false.obs;
  final requestCount = 0.obs;
  final searchQuery = ''.obs;
  final selectedTab = 'Requests'.obs; // Default to Requests

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadRequests(),
      loadSuggestions(),
      loadRequestCount(),
      loadFriends(),
    ]);
  }

  Future<void> loadRequests() async {
    isLoadingRequests.value = true;
    try {
      final result = await _profileService.getFriendRequests();
      if (result['success'] == true) {
        requests.assignAll(
          (result['items'] as List).map((i) => FriendRequestModel.fromJson(i)).toList()
        );
      }
    } catch (e) {
      Get.log('Error loading friend requests: $e');
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> loadRequestCount() async {
    try {
      final result = await _profileService.getFriendRequestsCount();
      if (result['count'] != null) {
        requestCount.value = result['count'];
      }
    } catch (e) {
      Get.log('Error loading friend requests count: $e');
    }
  }

  Future<void> loadSuggestions() async {
    isLoadingSuggestions.value = true;
    try {
      final result = await _profileService.getPeopleSuggestions();
      if (result['success'] == true) {
        suggestions.assignAll(
          (result['data'] as List).map((u) => UserModel.fromJson(u)).toList()
        );
      }
    } catch (e) {
      Get.log('Error loading friend suggestions: $e');
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  Future<void> loadFriends() async {
    final authController = Get.find<AuthController>();
    final userId = authController.user.value?.id;
    if (userId == null) return;

    isLoadingFriends.value = true;
    try {
      final result = await _profileService.getFriends(userId);
      if (result['success'] == true) {
        final List<UserModel> loadedFriends = (result['data'] as List).map((u) => UserModel.fromJson(u)).toList();
        friends.assignAll(loadedFriends);
        _applyFilter();
      }
    } catch (e) {
      Get.log('Error loading friends: $e');
    } finally {
      isLoadingFriends.value = false;
    }
  }

  void onSearch(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void changeTab(String tab) {
    selectedTab.value = tab;
  }

  void _applyFilter() {
    if (searchQuery.isEmpty) {
      filteredFriends.assignAll(friends);
    } else {
      filteredFriends.assignAll(
        friends.where((u) => u.name.toLowerCase().contains(searchQuery.value.toLowerCase())).toList()
      );
    }
  }

  Future<void> acceptRequest(FriendRequestModel request) async {
    try {
      final result = await _profileService.acceptFriendRequest(request.senderId);
      if (result['success'] == true) {
        requests.remove(request);
        requestCount.value = (requestCount.value - 1).clamp(0, 999);
        Get.snackbar('success'.tr, 'friend_request_accepted'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_accept_friend_request'.tr);
    }
  }

  Future<void> rejectRequest(FriendRequestModel request) async {
    try {
      final result = await _profileService.rejectFriendRequest(request.senderId);
      if (result['success'] == true) {
        requests.remove(request);
        requestCount.value = (requestCount.value - 1).clamp(0, 999);
        Get.snackbar('success'.tr, 'friend_request_removed'.tr);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_reject_friend_request'.tr);
    }
  }

  Future<void> sendRequest(UserModel user) async {
    try {
      final result = await _profileService.sendFriendRequest(user.id);
      if (result['success'] == true) {
        suggestions.remove(user);
        Get.snackbar('success'.tr, 'friend_request_sent_to'.trParams({'name': user.name}));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_send_friend_request'.tr);
    }
  }

  Future<void> unfriend(UserModel user) async {
    try {
      final result = await _profileService.unfriend(user.id);
      if (result['success'] == true) {
        friends.remove(user);
        filteredFriends.remove(user);
        Get.snackbar('success'.tr, 'user_removed_from_friends'.trParams({'name': user.name}));
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_unfriend'.tr);
    }
  }
}
