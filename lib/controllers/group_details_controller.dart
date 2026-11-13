import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/group_model.dart';
import '../data/models/post_model.dart';
import '../data/services/group_service.dart';

class GroupDetailsController extends GetxController {
  final GroupService _groupService = Get.find<GroupService>();

  final int groupId;
  GroupDetailsController({required this.groupId});

  var group = Rxn<GroupModel>();
  var isLoading = true.obs;
  var posts = <PostModel>[].obs;
  var isLoadingPosts = false.obs;

  // Membership status: none, member, pending, invited
  var membershipStatus = 'none'.obs;
  var memberCount = 0.obs;
  var isAdmin = false.obs;
  var canPost = false.obs;
  var pendingCount = 0.obs;

  var members = <Map<String, dynamic>>[].obs;
  var isLoadingMembers = false.obs;

  var media = <Map<String, dynamic>>[].obs;
  var isLoadingMedia = false.obs;

  var inviteableFriends = <Map<String, dynamic>>[].obs;
  var isLoadingInviteable = false.obs;
  var isUpdatingGroup = false.obs;

  int _currentPage = 1;
  bool _hasMore = true;


  Future<void> refreshAll() async {
    await loadGroupDetails();
  }

  Future<void> loadGroupDetails() async {
    try {
      isLoading.value = true;
      final data = await _groupService.getGroupDetails(groupId);
      if (data['data'] != null) {
        group.value = GroupModel.fromJson(data['data']);
        membershipStatus.value = data['membership'] ?? 'none';
        memberCount.value = data['member_count'] ?? 0;
        isAdmin.value = data['is_admin'] ?? false;
        canPost.value = data['can_post'] ?? false;
        pendingCount.value = data['pending_count'] ?? 0;

        _currentPage = 1;
        _hasMore = true;
        posts.clear();
        await loadPosts(refresh: true);
      } else {}
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error loading group details',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (isLoadingPosts.value || (!_hasMore && !refresh)) return;

    try {
      isLoadingPosts.value = true;
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
      }

      final data = await _groupService.getGroupPosts(
        groupId,
        page: _currentPage,
      );
      if (data['data'] != null) {
        final List<PostModel> newPosts = (data['data'] as List)
            .map((json) => PostModel.fromJson(json))
            .toList();

        if (refresh) {
          posts.assignAll(newPosts);
        } else {
          posts.addAll(newPosts);
        }

        _hasMore = data['next_page_url'] != null;
        if (_hasMore) _currentPage++;
      } else {}
    } catch (e) {
      String message = 'Error loading posts';
      if (e is DioException && e.response?.data != null) {
        message = e.response?.data['message'] ?? message;
      }
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingPosts.value = false;
    }
  }

  Future<void> toggleJoin() async {
    try {
      if (membershipStatus.value == 'member') {
        // Leave
        final data = await _groupService.leaveGroup(groupId);
        if (data['success']) {
          membershipStatus.value = 'none';
          memberCount.value--;
          Get.snackbar(
            'Success',
            data['message'],
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } else if (membershipStatus.value == 'none' ||
          membershipStatus.value == 'invited') {
        // Join
        final data = await _groupService.joinGroup(groupId);
        if (data['success']) {
          membershipStatus.value = data['membership'];
          if (membershipStatus.value == 'member') {
            memberCount.value++;
          }
          Get.snackbar(
            'Success',
            data['message'],
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Action failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> loadMembers({bool refresh = false}) async {
    if (isLoadingMembers.value) return;
    try {
      isLoadingMembers.value = true;
      final result = await _groupService.getMembers(groupId);
      if (result['success']) {
        members.assignAll(List<Map<String, dynamic>>.from(result['data']));
      }
    } catch (_) {
    } finally {
      isLoadingMembers.value = false;
    }
  }

  Future<void> loadMedia({bool refresh = false}) async {
    if (isLoadingMedia.value) return;
    try {
      isLoadingMedia.value = true;
      final result = await _groupService.getGroupMedia(groupId);
      if (result['success']) {
        media.assignAll(List<Map<String, dynamic>>.from(result['data']));
      }
    } catch (_) {
    } finally {
      isLoadingMedia.value = false;
    }
  }

  Future<void> updateGroup({
    required String name,
    required String description,
    required String privacy,
    dynamic avatar,
    dynamic coverPhoto,
  }) async {
    try {
      isUpdatingGroup.value = true;
      final response = await _groupService.updateGroup(
        groupId,
        name: name,
        description: description,
        privacy: privacy,
        avatar: avatar,
        coverPhoto: coverPhoto,
      );
      if (response['success']) {
        group.value = GroupModel.fromJson(response['data']);
        Get.snackbar(
          'Success',
          'Group updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      String msg = 'Failed to update group';
      if (e is DioException) {
        msg = e.response?.data['message'] ?? e.message ?? msg;
      }
      Get.snackbar(
        'Error',
        msg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUpdatingGroup.value = false;
    }
  }

  Future<void> deleteGroup() async {
    try {
      final response = await _groupService.deleteGroup(groupId);
      if (response['success']) {
        Get.back(); // Close dialog
        Get.back(); // Go back from group details
        Get.snackbar(
          'Success',
          'Group deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete group',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> searchInviteableFriends(String term) async {
    try {
      isLoadingInviteable.value = true;
      final result = await _groupService.getInviteableFriends(
        groupId,
        term: term,
      );
      if (result['success']) {
        inviteableFriends.assignAll(
          List<Map<String, dynamic>>.from(result['data']),
        );
      }
    } catch (_) {
    } finally {
      isLoadingInviteable.value = false;
    }
  }

  Future<void> inviteUser(int userId) async {
    try {
      final result = await _groupService.inviteToGroup(groupId, userId);
      if (result['success']) {
        Get.snackbar(
          'Success',
          result['message'],
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Warning',
          result['message'],
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send invite',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pickAndUploadMedia(String type) async {
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
        final response = await _groupService.updateGroupMedia(
          groupId,
          File(image.path),
          type,
        );

        if (response['success'] == true) {
          Get.snackbar('success'.tr, response['message'] ?? 'group_media_updated'.tr, backgroundColor: Colors.green, colorText: Colors.white);
          await loadGroupDetails();
        } else {
          Get.snackbar('error'.tr, response['message'] ?? 'upload_failed'.tr, backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'error_occurred_during_upload'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
