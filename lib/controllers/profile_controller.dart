import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/profile_model.dart';
import '../data/models/post_model.dart';
import '../data/models/user_model.dart';
import '../data/models/feed_item.dart';
import '../data/services/profile_service.dart';

class ProfileController extends GetxController {
  final ProfileService _profileService = Get.put(ProfileService());

  // ─── Observable State ──────────────────
  final profile = Rx<ProfileModel?>(null);
  final posts = <PostModel>[].obs;
  final feedItems = <FeedItem>[].obs;
  final suggestedAds = <Map<String, dynamic>>[].obs;
  final friends = <UserModel>[].obs;
  final photos = <Map<String, dynamic>>[].obs;
  final videos = <Map<String, dynamic>>[].obs;
  
  final isLoading = true.obs;
  final isPostsLoading = false.obs;
  final hasMorePosts = true.obs;
  bool isProfileFetching = false;
  int _currentPostPage = 1;

  // ─── Initial Load ──────────────────

  Future<void> loadProfile(dynamic userIdOrUsername, {bool isSilent = false, bool showSkeleton = false}) async {
    if (isProfileFetching && !showSkeleton && !isSilent) return;
    isProfileFetching = true;

    if (!isSilent || showSkeleton) {
      isLoading.value = true;
      posts.clear();
      feedItems.clear();
      suggestedAds.clear();
      friends.clear();
      photos.clear();
      videos.clear();
    }
    
    _currentPostPage = 1;
    hasMorePosts.value = true;

    try {
      final result = await _profileService.getProfile(userIdOrUsername);
      if (result['success'] == true && result['data'] != null) {
        profile.value = ProfileModel.fromJson(result['data']);
        isLoading.value = false; // Display main profile immediately!
        
        final int resolvedId = profile.value!.id;
        // Load secondary tab contents asynchronously in background
        loadPosts(resolvedId);
        loadFriends(resolvedId);
        loadMedia(resolvedId, 'image');
        loadMedia(resolvedId, 'video');
      } else {
        profile.value = null;
        isLoading.value = false;
      }
    } catch (e) {
      profile.value = null;
      isLoading.value = false;
      Get.log('Profile load error: $e');
    } finally {
      isProfileFetching = false;
    }
  }

  Future<void> loadPosts(int userId) async {
    if (isPostsLoading.value || !hasMorePosts.value) return;
    isPostsLoading.value = true;

    try {
      final result = await _profileService.getProfilePosts(userId, page: _currentPostPage);
      if (result['success'] == true) {
        final newPosts = (result['data'] as List).map((p) => PostModel.fromJson(p)).toList();
        
        if (result['suggestions'] != null && result['suggestions']['ads'] != null) {
          suggestedAds.assignAll(List<Map<String, dynamic>>.from(result['suggestions']['ads']));
        }

        if (_currentPostPage == 1) posts.clear();
        posts.addAll(newPosts);
        _composeFeed(newPosts, isRefresh: _currentPostPage == 1);
        
        _currentPostPage++;
        hasMorePosts.value = result['current_page'] < result['last_page'];
      }
    } catch (e) {
      Get.log('Profile posts load error: $e');
    } finally {
      isPostsLoading.value = false;
    }
  }

  void _composeFeed(List<PostModel> newPosts, {bool isRefresh = false}) {
    if (isRefresh) {
      feedItems.clear();
    }

    int postsAdded = _currentPostPage == 1 ? 0 : posts.length - newPosts.length;
    int adOffset = isRefresh ? 0 : feedItems.where((item) => item.type == FeedItemType.ad).length;

    for (var post in newPosts) {
      feedItems.add(FeedItem.post(post));
      postsAdded++;

      // Intersperse ads logic (every 5 posts)
      if (postsAdded % 5 == 0 && suggestedAds.isNotEmpty) {
        final adData = suggestedAds[adOffset % suggestedAds.length];
        feedItems.add(FeedItem.ad(AdModel.fromJson(adData)));
        adOffset++;
      }
    }
  }

  Future<void> loadFriends(int userId) async {
    try {
      final result = await _profileService.getFriends(userId);
      if (result['success'] == true) {
        friends.assignAll((result['data'] as List).map((u) => UserModel.fromJson(u)).toList());
      }
    } catch (e) {
      Get.log('Friends load error: $e');
    }
  }

  Future<void> loadMedia(int userId, String type) async {
    try {
      final result = await _profileService.getMedia(userId, type);
      if (result['success'] == true) {
        if (type == 'image') {
          photos.assignAll(List<Map<String, dynamic>>.from(result['data']));
        } else {
          videos.assignAll(List<Map<String, dynamic>>.from(result['data']));
        }
      }
    } catch (e) {
      Get.log('Media load error: $e');
    }
  }

  // ─── Friendship Actions ──────────────────

  Future<void> toggleFriendAction() async {
    if (profile.value == null) return;
    final userId = profile.value!.id;
    final currentRelation = profile.value!.relation;

    try {
      Map<String, dynamic> result;
      if (currentRelation == 'none') {
        result = await _profileService.sendFriendRequest(userId);
      } else if (currentRelation == 'pending_sent') {
        result = await _profileService.cancelFriendRequest(userId);
      } else if (currentRelation == 'pending_received') {
        // By default confirm, or use specific methods below
        result = await _profileService.acceptFriendRequest(userId);
      } else if (currentRelation == 'friends') {
        // By default show unfriend, or use specific methods below
        result = await _profileService.unfriend(userId);
      } else {
        return;
      }

      if (result['success'] == true) {
        final newRelation = result['status'] ?? 'none';
        _updateProfileRelation(newRelation);
        if (result['message'] != null) Get.snackbar('success'.tr, result['message']);
      }
    } catch (e) {
      Get.log('Friend action error: $e');
    }
  }

  Future<void> acceptFriendRequest(int userId) async {
    try {
      final result = await _profileService.acceptFriendRequest(userId);
      if (result['success'] == true) {
        _updateProfileRelation('friends');
        Get.snackbar('success'.tr, 'friend_request_accepted'.tr);
      }
    } catch (e) {
      Get.log('Accept error: $e');
    }
  }

  Future<void> rejectFriendRequest(int userId) async {
    try {
      final result = await _profileService.rejectFriendRequest(userId);
      if (result['success'] == true) {
        _updateProfileRelation('none');
        Get.snackbar('success'.tr, 'friend_request_deleted'.tr);
      }
    } catch (e) {
      Get.log('Reject error: $e');
    }
  }

  Future<void> unfriendUser(int userId) async {
    try {
      final result = await _profileService.unfriend(userId);
      if (result['success'] == true) {
        _updateProfileRelation('none');
        Get.snackbar('success'.tr, 'user_removed_friends'.tr);
      }
    } catch (e) {
      Get.log('Unfriend error: $e');
    }
  }

  void _updateProfileRelation(String newRelation) {
    if (profile.value != null) {
      profile.value = ProfileModel(
        id: profile.value!.id,
        name: profile.value!.name,
        username: profile.value!.username,
        avatar: profile.value!.avatar,
        cover: profile.value!.cover,
        bio: profile.value!.bio,
        location: profile.value!.location,
        work: profile.value!.work,
        education: profile.value!.education,
        website: profile.value!.website,
        socialLinks: profile.value!.socialLinks,
        stats: profile.value!.stats, // Might need count update if unfriend/accept
        relation: newRelation,
        isOwner: profile.value!.isOwner,
        profileType: profile.value!.profileType,
        customFields: profile.value!.customFields,
      );
    }
  }

  // ─── Profile Editing ──────────────────

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final result = await _profileService.updateProfile(data);
      if (result['success'] == true) {
        // Reload profile to refresh state
        await loadProfile(profile.value!.id);
        return true;
      }
    } catch (e) {
      Get.log('Profile update error: $e');
    }
    return false;
  }

  // ─── Image Picking & Upload ──────────────────

  Future<void> pickAndUploadPhoto(String type) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        isLoading.value = true;
        final result = await _profileService.updatePhoto(File(image.path), type);
        
        if (result['success'] == true) {
          Get.snackbar('success'.tr, result['message'] ?? 'uploaded_success'.tr);
          // Refresh profile to show new image
          await loadProfile(profile.value!.id);
        } else {
          Get.snackbar('error'.tr, result['message'] ?? 'upload_failed'.tr);
        }
      }
    } catch (e) {
      Get.log('Photo upload error: $e');
      Get.snackbar('error'.tr, 'error_occurred_upload'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
