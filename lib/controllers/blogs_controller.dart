import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/models/blog_model.dart';
import '../data/services/blog_service.dart';
import '../utils/app_theme.dart';

class BlogsController extends GetxController {
  final BlogService _blogService = BlogService();

  // ─── Blog Listing State ──────────────────
  final heroBlog = Rx<BlogModel?>(null);
  final featuredBlogs = <BlogModel>[].obs;
  final latestBlogs = <BlogModel>[].obs;
  final categories = <String>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;

  int _currentPage = 1;
  int _lastPage = 1;

  // ─── Blog Detail State ──────────────────
  final currentBlog = Rx<BlogModel?>(null);
  final relatedBlogs = <BlogModel>[].obs;
  final isDetailLoading = true.obs;

  // ─── My Blogs State ──────────────────
  final myBlogs = <BlogModel>[].obs;
  final isMyBlogsLoading = true.obs;
  final isMyBlogsLoadingMore = false.obs;
  int _myBlogsPage = 1;
  int _myBlogsLastPage = 1;

  // ─── Create / Edit State ──────────────────
  final isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadBlogs();
  }

  // ═══════════════════════════════════════════
  // Blog Listing
  // ═══════════════════════════════════════════

  Future<void> loadBlogs() async {
    isLoading.value = true;
    _currentPage = 1;

    try {
      final result = await _blogService.getBlogs(page: 1);
      heroBlog.value = result['hero'] as BlogModel?;
      featuredBlogs.value = result['featured'] as List<BlogModel>;
      latestBlogs.value = result['latest'] as List<BlogModel>;
      categories.value = result['categories'] as List<String>;
      _currentPage = result['currentPage'] as int;
      _lastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load blogs error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshBlogs() async {
    await loadBlogs();
  }

  Future<void> loadMoreLatest() async {
    if (isLoadingMore.value || _currentPage >= _lastPage) return;
    isLoadingMore.value = true;

    try {
      final result = await _blogService.getBlogs(page: _currentPage + 1);
      final newBlogs = result['latest'] as List<BlogModel>;
      latestBlogs.addAll(newBlogs);
      _currentPage = result['currentPage'] as int;
      _lastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load more blogs error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ═══════════════════════════════════════════
  // Blog Detail
  // ═══════════════════════════════════════════

  Future<void> loadBlog(String slug) async {
    isDetailLoading.value = true;
    currentBlog.value = null;

    try {
      final result = await _blogService.getBlog(slug);
      currentBlog.value = result['blog'] as BlogModel;
      relatedBlogs.value = result['related'] as List<BlogModel>;
    } catch (e) {
      Get.log('Load blog detail error: $e');
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════
  // My Blogs
  // ═══════════════════════════════════════════

  Future<void> loadMyBlogs() async {
    isMyBlogsLoading.value = true;
    _myBlogsPage = 1;

    try {
      final result = await _blogService.getMyBlogs(page: 1);
      myBlogs.value = result['blogs'] as List<BlogModel>;
      _myBlogsPage = result['currentPage'] as int;
      _myBlogsLastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load my blogs error: $e');
    } finally {
      isMyBlogsLoading.value = false;
    }
  }

  Future<void> loadMoreMyBlogs() async {
    if (isMyBlogsLoadingMore.value || _myBlogsPage >= _myBlogsLastPage) return;
    isMyBlogsLoadingMore.value = true;

    try {
      final result = await _blogService.getMyBlogs(page: _myBlogsPage + 1);
      final newBlogs = result['blogs'] as List<BlogModel>;
      myBlogs.addAll(newBlogs);
      _myBlogsPage = result['currentPage'] as int;
      _myBlogsLastPage = result['lastPage'] as int;
    } catch (e) {
      Get.log('Load more my blogs error: $e');
    } finally {
      isMyBlogsLoadingMore.value = false;
    }
  }

  // ═══════════════════════════════════════════
  // Create / Edit / Delete
  // ═══════════════════════════════════════════

  Future<bool> createBlog({
    required String title,
    required String content,
    required String status,
    String? excerpt,
    String? category,
    String? tags,
    File? featuredImage,
  }) async {
    isSubmitting.value = true;

    try {
      final result = await _blogService.createBlog(
        title: title,
        content: content,
        status: status,
        excerpt: excerpt,
        category: category,
        tags: tags,
        featuredImage: featuredImage,
      );

      if (result['success'] == true) {
        // Refresh lists
        loadBlogs();
        loadMyBlogs();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> updateBlog({
    required int id,
    required String title,
    required String content,
    required String status,
    String? excerpt,
    String? category,
    String? tags,
    File? featuredImage,
  }) async {
    isSubmitting.value = true;

    try {
      final result = await _blogService.updateBlog(
        id: id,
        title: title,
        content: content,
        status: status,
        excerpt: excerpt,
        category: category,
        tags: tags,
        featuredImage: featuredImage,
      );

      if (result['success'] == true) {
        loadBlogs();
        loadMyBlogs();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> deleteBlog(int id) async {
    try {
      final result = await _blogService.deleteBlog(id);
      if (result['success'] == true) {
        myBlogs.removeWhere((b) => b.id == id);
        Get.snackbar('success'.tr, 'blog_deleted_success'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primary,
            colorText: Colors.white);
        loadBlogs();
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_delete_blog'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return false;
    }
  }
}
