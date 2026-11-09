import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../data/models/forum_model.dart';
import '../data/services/forum_service.dart';

class ForumController extends GetxController {
  final ForumService _service = ForumService();

  final categories = <ForumCategoryModel>[].obs;
  final recentTopics = <ForumTopicModel>[].obs;
  final trendingTopics = <ForumTopicModel>[].obs;
  final currentTopic = Rx<ForumTopicModel?>(null);

  final searchQuery = ''.obs;
  final selectedCategoryId = Rx<int?>(null);
  final selectedSubcategoryId = Rx<int?>(null);

  final isLoading = true.obs;
  final isDetailLoading = false.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadForumFeed();
  }

  String _parseErrorMessage(dynamic e, String fallback) {
    if (e is DioException) {
      final resData = e.response?.data;
      if (resData is Map && resData.containsKey('message')) {
        return resData['message'].toString();
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
    }
    return fallback;
  }

  Future<void> loadForumFeed([String? search]) async {
    isLoading.value = true;
    if (search != null) {
      searchQuery.value = search;
    }
    try {
      final res = await _service.getForumData(
        search: searchQuery.value,
        categoryId: selectedCategoryId.value,
        subcategoryId: selectedSubcategoryId.value,
      );
      categories.assignAll(res['categories'] ?? []);
      recentTopics.assignAll(res['recent_topics'] ?? []);
      trendingTopics.assignAll(res['trending_topics'] ?? []);
    } catch (e) {
      Get.snackbar('Error', _parseErrorMessage(e, 'Failed to load forum feed'));
    } finally {
      isLoading.value = false;
    }
  }

  void filterByCategory(int? categoryId, {int? subcategoryId}) {
    selectedCategoryId.value = categoryId;
    selectedSubcategoryId.value = subcategoryId;
    loadForumFeed();
  }

  void searchTopics(String query) {
    searchQuery.value = query;
    loadForumFeed(query);
  }

  void clearSearch() {
    searchQuery.value = '';
    selectedCategoryId.value = null;
    selectedSubcategoryId.value = null;
    loadForumFeed('');
  }

  Future<void> loadTopicDetail(String slug) async {
    isDetailLoading.value = true;
    try {
      final topic = await _service.getTopic(slug);
      currentTopic.value = topic;
    } catch (e) {
      Get.snackbar('Error', _parseErrorMessage(e, 'Failed to load topic details'));
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<bool> createTopic({
    required int categoryId,
    int? subcategoryId,
    required String title,
    required String content,
    List<File> attachments = const [],
  }) async {
    isSubmitting.value = true;
    try {
      final newTopic = await _service.createTopic(
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        title: title,
        content: content,
        attachments: attachments,
      );
      recentTopics.insert(0, newTopic);
      return true;
    } catch (e) {
      Get.snackbar('Error', _parseErrorMessage(e, 'Failed to create topic'));
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> replyToTopic({
    required String topicSlug,
    required String content,
    int? parentId,
    List<File> attachments = const [],
  }) async {
    try {
      await _service.postReply(
        topicSlug: topicSlug,
        content: content,
        parentId: parentId,
        attachments: attachments,
      );
      await loadTopicDetail(topicSlug);
      Get.snackbar('success'.tr, 'reply_posted_success'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, _parseErrorMessage(e, 'failed_to_post_reply'.tr));
    }
  }

  Future<void> toggleSolution(int replyId, String topicSlug) async {
    try {
      await _service.toggleSolution(replyId);
      await loadTopicDetail(topicSlug);
    } catch (e) {
      Get.snackbar('error'.tr, _parseErrorMessage(e, 'could_not_update_solution_status'.tr));
    }
  }

  Future<void> toggleLike(String type, int id) async {
    try {
      await _service.toggleReaction(type, id);
    } catch (e) {
      // quiet retry
    }
  }

  Future<bool> updateTopic({
    required int topicId,
    required String title,
    required int categoryId,
    required String content,
    required String topicSlug,
  }) async {
    isSubmitting.value = true;
    try {
      final updated = await _service.updateTopic(
        topicId: topicId,
        title: title,
        categoryId: categoryId,
        content: content,
      );
      if (currentTopic.value?.id == topicId) {
        currentTopic.value = updated;
      }
      final index = recentTopics.indexWhere((t) => t.id == topicId);
      if (index != -1) {
        recentTopics[index] = updated;
      }
      Get.snackbar('success'.tr, 'topic_updated_success'.tr);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, _parseErrorMessage(e, 'failed_to_update_topic'.tr));
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateReply({
    required int replyId,
    required String content,
    required String topicSlug,
  }) async {
    isSubmitting.value = true;
    try {
      await _service.updateReply(
        replyId: replyId,
        content: content,
      );
      await loadTopicDetail(topicSlug);
      Get.snackbar('success'.tr, 'reply_updated_success'.tr);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, _parseErrorMessage(e, 'failed_to_update_reply'.tr));
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteTopic(int topicId) async {
    try {
      await _service.deleteTopic(topicId);
      recentTopics.removeWhere((t) => t.id == topicId);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, _parseErrorMessage(e, 'failed_to_delete_topic'.tr));
      return false;
    }
  }

  Future<bool> deleteReply(int replyId, String topicSlug) async {
    try {
      await _service.deleteReply(replyId);
      await loadTopicDetail(topicSlug);
      Get.snackbar('success'.tr, 'reply_deleted_success'.tr);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, _parseErrorMessage(e, 'failed_to_delete_reply'.tr));
      return false;
    }
  }
}
