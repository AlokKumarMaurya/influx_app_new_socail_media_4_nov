import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../utils/app_theme.dart';
import '../data/models/watch_video_model.dart';
import '../data/models/comment_model.dart';
import '../data/models/feed_item.dart';
import '../data/services/post_service.dart';

class WatchController extends GetxController {
  final PostService _postService = PostService();

  // ─── Observable State ──────────────────
  final videos = <WatchVideoModel>[].obs;
  final feedItems = <FeedItem>[].obs;
  final suggestedAds = <Map<String, dynamic>>[].obs;
  final suggestedGroups = <Map<String, dynamic>>[].obs;
  final suggestedPeople = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;

  // ─── Comments State ──────────────────
  final postComments = <int, RxList<CommentModel>>{}.obs;
  final isCommentsLoading = <int, RxBool>{}.obs;
  final replyingToCommentId = Rx<int?>(null);
  final replyingToUserName = Rx<String?>(null);

  // ─── Pagination ──────────────────
  int _currentPage = 1;
  String? _nextPageUrl;
  bool _hasMorePages = true;

  @override
  void onInit() {
    super.onInit();
    loadVideos();
  }

  // ─── Video Loading ──────────────────

  Future<void> loadVideos() async {
    isLoading.value = true;
    _currentPage = 1;
    _hasMorePages = true;
    _nextPageUrl = null;

    try {
      final result = await _postService.getWatchVideos(1);

      if (result['success'] == true) {
        final dataList = result['data'] as List;
        final videoModels = dataList
            .map((v) => WatchVideoModel.fromJson(Map<String, dynamic>.from(v)))
            .toList();
        videos.value = videoModels;

        // Suggestions from API
        final suggestions = result['suggestions'] as Map<String, dynamic>?;
        if (suggestions != null) {
          suggestedAds.assignAll(
            List<Map<String, dynamic>>.from(suggestions['ads'] ?? []),
          );
          suggestedGroups.assignAll(
            List<Map<String, dynamic>>.from(suggestions['groups'] ?? []),
          );
          suggestedPeople.assignAll(
            List<Map<String, dynamic>>.from(suggestions['people'] ?? []),
          );
        }

        _composeFeed(videoModels, isRefresh: true);

        _nextPageUrl = result['next_page_url'];
        _currentPage = result['current_page'] ?? 1;
        _hasMorePages = _nextPageUrl != null;
      }
    } catch (e) {
      Get.log('Watch load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _composeFeed(List<WatchVideoModel> newVideos, {bool isRefresh = false}) {
    if (isRefresh) {
      feedItems.clear();
    }

    int videosAdded = isRefresh
        ? 0
        : feedItems.where((item) => item.type == FeedItemType.post).length;
    int adOffset = isRefresh ? 0 : suggestedAds.length;

    for (var video in newVideos) {
      feedItems.add(
        FeedItem.post(video.post),
      ); // Note: WatchVideoCard needs WatchVideoModel normally, but FeedItem.post takes PostModel. I might need a specific FeedItem.watch
      // Actually, FeedItem and PostCard use PostModel. Let's see if I can add a FeedItemType.watchVideo
      videosAdded++;

      // Intersperse logic
      if (videosAdded % 4 == 0 && suggestedAds.isNotEmpty) {
        final adData = suggestedAds[adOffset % suggestedAds.length];
        feedItems.add(FeedItem.ad(AdModel.fromJson(adData)));
        adOffset++;
      }

      if (videosAdded % 8 == 0 && suggestedGroups.isNotEmpty) {
        feedItems.add(FeedItem.groups(suggestedGroups.take(5).toList()));
      }

      if (videosAdded % 12 == 0 && suggestedPeople.isNotEmpty) {
        feedItems.add(FeedItem.people(suggestedPeople.take(5).toList()));
      }
    }
  }

  Future<void> refreshVideos() async {
    await loadVideos();
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMorePages) return;
    isLoadingMore.value = true;

    try {
      final result = await _postService.getWatchVideos(_currentPage + 1);

      if (result['success'] == true) {
        final dataList = result['data'] as List;
        final newVideos = dataList
            .map((v) => WatchVideoModel.fromJson(Map<String, dynamic>.from(v)))
            .toList();
        videos.addAll(newVideos);

        _composeFeed(newVideos);

        _nextPageUrl = result['next_page_url'];
        _currentPage = result['current_page'] ?? _currentPage + 1;
        _hasMorePages = _nextPageUrl != null;
      }
    } catch (e) {
      Get.log('Watch load more error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ─── Reactions ──────────────────

  Future<void> toggleReaction(int postId, String type) async {
    final index = videos.indexWhere((v) => v.post.id == postId);
    if (index == -1) return;

    final video = videos[index];
    final post = video.post;
    final wasReacted = post.userReaction != null;
    final sameType = post.userReaction == type;

    final updatedPost = post.copyWith(
      userReaction: sameType ? null : type,
      clearUserReaction: sameType,
      reactionsCount: sameType
          ? (post.reactionsCount - 1)
          : (wasReacted ? post.reactionsCount : post.reactionsCount + 1),
    );

    videos[index] = WatchVideoModel(
      mediaId: video.mediaId,
      videoUrl: video.videoUrl,
      viewsCount: video.viewsCount,
      post: updatedPost,
    );
    videos.refresh();

    try {
      final result = await _postService.toggleReaction(postId, type);
      if (result['success'] == true) {
        final serverType = result['current_type'];
        final finalPost = updatedPost.copyWith(
          userReaction: serverType,
          clearUserReaction: serverType == null,
          reactionsCount: result['total_count'] ?? updatedPost.reactionsCount,
          reactionSummary: result['summary'] != null
              ? Map<String, int>.from(result['summary'])
              : updatedPost.reactionSummary,
        );
        videos[index] = WatchVideoModel(
          mediaId: video.mediaId,
          videoUrl: video.videoUrl,
          viewsCount: video.viewsCount,
          post: finalPost,
        );
        videos.refresh();
      }
    } catch (e) {
      // Revert on error
      videos[index] = video;
      videos.refresh();
      Get.log('Watch reaction error: $e');
    }
  }

  // ─── Comments ──────────────────

  Future<void> loadComments(int postId) async {
    if (isCommentsLoading[postId]?.value == true) return;
    if (!postComments.containsKey(postId)) {
      postComments[postId] = <CommentModel>[].obs;
      isCommentsLoading[postId] = false.obs;
    }
    isCommentsLoading[postId]!.value = true;
    try {
      final result = await _postService.getComments(postId, 1);
      postComments[postId]!.assignAll(result['comments'] as List<CommentModel>);
    } catch (e) {
      Get.log('Watch load comments error: $e');
    } finally {
      isCommentsLoading[postId]!.value = false;
    }
  }

  void setReplyTo(int commentId, String userName) {
    replyingToCommentId.value = commentId;
    replyingToUserName.value = userName;
  }

  void clearReplyTo() {
    replyingToCommentId.value = null;
    replyingToUserName.value = null;
  }

  Future<void> addComment(int postId, String content, {File? image}) async {
    final parentId = replyingToCommentId.value;
    try {
      final comment = await _postService.addComment(
        postId,
        content,
        image: image,
        parentId: parentId,
      );

      if (postComments.containsKey(postId)) {
        if (parentId == null) {
          postComments[postId]!.insert(0, comment);
        } else {
          _addReplyRecursively(postComments[postId]!, parentId, comment);
        }
      }

      // Update comment count
      final index = videos.indexWhere((v) => v.post.id == postId);
      if (index != -1) {
        final v = videos[index];
        videos[index] = WatchVideoModel(
          mediaId: v.mediaId,
          videoUrl: v.videoUrl,
          viewsCount: v.viewsCount,
          post: v.post.copyWith(commentsCount: v.post.commentsCount + 1),
        );
      }

      clearReplyTo();
    } catch (e) {
      Get.log('Watch add comment error: $e');
    }
  }

  bool _addReplyRecursively(
    List<CommentModel> comments,
    int parentId,
    CommentModel reply,
  ) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == parentId) {
        comments[i] = comments[i].copyWith(
          replies: [...comments[i].replies, reply],
        );
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        final found = _addReplyRecursively(
          comments[i].replies,
          parentId,
          reply,
        );
        if (found) {
          comments[i] = comments[i].copyWith(replies: comments[i].replies);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> toggleCommentReaction(
    int postId,
    int commentId,
    String type,
  ) async {
    if (!postComments.containsKey(postId)) return;
    _toggleCommentReactionOptimistic(postComments[postId]!, commentId, type);
    postComments[postId]!.refresh();

    try {
      await _postService.toggleReaction(commentId, type, model: 'comment');
    } catch (e) {
      Get.log('Watch comment reaction error: $e');
    }
  }

  bool _toggleCommentReactionOptimistic(
    List<CommentModel> comments,
    int commentId,
    String type,
  ) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        final c = comments[i];
        final sameType = c.userReaction == type;
        comments[i] = c.copyWith(
          userReactionValue: sameType ? null : type,
          likesCount: sameType
              ? (c.likesCount - 1)
              : (c.userReaction != null ? c.likesCount : c.likesCount + 1),
        );
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        final found = _toggleCommentReactionOptimistic(
          comments[i].replies,
          commentId,
          type,
        );
        if (found) {
          comments[i] = comments[i].copyWith(replies: comments[i].replies);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> deleteComment(int postId, int commentId) async {
    final original = postComments[postId]?.toList();
    if (postComments[postId] != null) {
      postComments[postId]!.removeWhere((c) => c.id == commentId);
      for (var i = 0; i < postComments[postId]!.length; i++) {
        final c = postComments[postId]![i];
        if (c.replies.any((r) => r.id == commentId)) {
          postComments[postId]![i] = c.copyWith(
            replies: c.replies.where((r) => r.id != commentId).toList(),
          );
        }
      }
    }

    try {
      final result = await _postService.deleteComment(commentId);
      if (result['success'] != true && original != null) {
        postComments[postId]?.assignAll(original);
      }
    } catch (e) {
      if (original != null) postComments[postId]?.assignAll(original);
      Get.snackbar('error'.tr, 'failed_to_delete_comment'.tr);
    }
  }

  // ─── Save / Bookmark ──────────────────

  Future<void> toggleSave(int postId) async {
    final index = videos.indexWhere((v) => v.post.id == postId);
    if (index == -1) return;

    final v = videos[index];
    videos[index] = WatchVideoModel(
      mediaId: v.mediaId,
      videoUrl: v.videoUrl,
      viewsCount: v.viewsCount,
      post: v.post.copyWith(isSaved: !v.post.isSaved),
    );

    try {
      await _postService.toggleSave(postId);
    } catch (e) {
      videos[index] = v; // Revert
      Get.log('Watch save error: $e');
    }
  }

  // ─── Share ──────────────────

  Future<void> sharePost(int postId, String content, String privacy) async {
    try {
      final result = await _postService.sharePost(postId, content, privacy);
      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          'Post shared successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to share post',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
