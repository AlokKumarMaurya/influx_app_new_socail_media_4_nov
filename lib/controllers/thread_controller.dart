import 'dart:io';
import 'package:get/get.dart';
import '../data/models/thread_model.dart';
import '../data/services/thread_service.dart';

class ThreadController extends GetxController {
  final ThreadService _service = ThreadService();

  final threads = <ThreadModel>[].obs;
  final currentThread = Rx<ThreadModel?>(null);
  final isLoading = true.obs;
  final isDetailLoading = false.obs;
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadThreads();
  }

  Future<void> loadThreads() async {
    isLoading.value = true;
    try {
      final list = await _service.getThreads();
      threads.value = list;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_load_threads_feed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadThreadDetail(int id) async {
    isDetailLoading.value = true;
    try {
      final item = await _service.getThread(id);
      currentThread.value = item;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_load_thread_detail'.tr);
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<bool> createThread({
    required String content,
    List<File> attachments = const [],
  }) async {
    isSubmitting.value = true;
    try {
      final newThread = await _service.createThread(
        content: content,
        attachments: attachments,
      );
      threads.insert(0, newThread);
      Get.snackbar('success'.tr, 'thread_posted_successfully'.tr);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_post_thread'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> replyThread({
    required int threadId,
    required String content,
    List<File> attachments = const [],
  }) async {
    try {
      await _service.replyThread(
        threadId: threadId,
        content: content,
        attachments: attachments,
      );
      await loadThreadDetail(threadId);
      Get.snackbar('success'.tr, 'reply_added_to_thread'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_post_reply'.tr);
    }
  }

  Future<void> toggleReaction(int threadId) async {
    try {
      await _service.toggleReaction(threadId);
    } catch (e) {
      // quiet retry
    }
  }

  Future<bool> updateThread({
    required int threadId,
    required String content,
  }) async {
    isSubmitting.value = true;
    try {
      final updated = await _service.updateThread(
        threadId: threadId,
        content: content,
      );
      if (currentThread.value?.id == threadId) {
        currentThread.value = updated;
      }
      final index = threads.indexWhere((t) => t.id == threadId);
      if (index != -1) {
        threads[index] = updated;
      }
      Get.snackbar('success'.tr, 'thread_updated_successfully'.tr);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_update_thread'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateReply({
    required int replyId,
    required String content,
    required int threadId,
  }) async {
    isSubmitting.value = true;
    try {
      await _service.updateReply(
        replyId: replyId,
        content: content,
      );
      await loadThreadDetail(threadId);
      Get.snackbar('success'.tr, 'reply_updated_successfully'.tr);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_update_reply'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteThread(int threadId) async {
    try {
      await _service.deleteThread(threadId);
      threads.removeWhere((t) => t.id == threadId);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_delete_thread'.tr);
      return false;
    }
  }

  Future<bool> deleteReply(int replyId, int threadId) async {
    try {
      await _service.deleteReply(replyId);
      await loadThreadDetail(threadId);
      Get.snackbar('success'.tr, 'reply_deleted_success'.tr);
      return true;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_delete_reply'.tr);
      return false;
    }
  }
}
