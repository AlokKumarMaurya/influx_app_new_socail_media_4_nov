import 'dart:async';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../utils/app_theme.dart';
import '../data/models/post_model.dart';
import '../data/models/story_model.dart';
import '../data/models/comment_model.dart';
import '../data/models/user_model.dart';
import '../data/models/live_stream_model.dart';
import '../data/services/feed_service.dart';
import '../data/services/post_service.dart';
import '../data/models/feed_item.dart';

class FeedController extends GetxController {
  final FeedService _feedService = FeedService();
  final PostService _postService = PostService();
  final ScrollController scrollController = ScrollController();

  // ─── Observable State ──────────────────
  final feedItems = <FeedItem>[].obs;
  final posts = <PostModel>[].obs;
  final stories = <StoryGroup>[].obs;
  final liveStoryStreams = <LiveStreamModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasNewPosts = false.obs;
  final newPostsCount = 0.obs;

  // ─── Suggestions State ──────────────────
  final suggestedAds = <Map<String, dynamic>>[].obs;
  final suggestedGroups = <Map<String, dynamic>>[].obs;
  final suggestedPages = <Map<String, dynamic>>[].obs;
  final suggestedPeople = <Map<String, dynamic>>[].obs;
  final suggestedProducts = <Map<String, dynamic>>[].obs;
  final suggestedLives = <Map<String, dynamic>>[].obs;

  // ─── Comments State ──────────────────
  final postComments = <int, RxList<CommentModel>>{}.obs;
  final isCommentsLoading = <int, RxBool>{}.obs;
  final replyingToCommentId = Rx<int?>(null);
  final replyingToUserName = Rx<String?>(null);

  // ─── Pagination ──────────────────
  int _currentPage = 1;
  String? _nextPageUrl;
  bool _hasMorePages = true;

  // ─── Long-poll ──────────────────
  Timer? _longPollTimer;
  int _feedLoadedTimestamp = 0;
  int _lastNewCount = -1;

  @override
  void onInit() {
    super.onInit();
    loadFeed();
  }

  @override
  void onClose() {
    _longPollTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  // ─── Feed Loading ──────────────────

  Future<void> loadFeed() async {
    isLoading.value = true;
    _currentPage = 1;
    _hasMorePages = true;
    _nextPageUrl = null;

    try {
      final results = await Future.wait([
        _feedService.getPosts(1),
        _feedService.getStories(),
        _feedService.getStoryLiveStreams(),
      ]);

      final postResult = results[0] as Map<String, dynamic>;
      final postModels = postResult['posts'] as List<PostModel>;
      posts.value = postModels;
      _nextPageUrl = postResult['nextPageUrl'];
      _currentPage = postResult['currentPage'] as int;
      _hasMorePages = _nextPageUrl != null;

      // Suggestions from API
      final suggestions = postResult['suggestions'] as Map<String, dynamic>?;
      if (suggestions != null) {
        suggestedAds.assignAll(List<Map<String, dynamic>>.from(suggestions['ads'] ?? []));
        suggestedGroups.assignAll(List<Map<String, dynamic>>.from(suggestions['groups'] ?? []));
        suggestedPages.assignAll(List<Map<String, dynamic>>.from(suggestions['pages'] ?? []));
        suggestedPeople.assignAll(List<Map<String, dynamic>>.from(suggestions['people'] ?? []));
        suggestedProducts.assignAll(List<Map<String, dynamic>>.from(suggestions['products'] ?? []));
        suggestedLives.assignAll(List<Map<String, dynamic>>.from(suggestions['live_streams'] ?? []));
      }

      // Initial Feed Composition
      _composeFeed(postModels, isRefresh: true);

      for (var post in postModels) {
        postComments[post.id] = post.comments.obs;
        isCommentsLoading[post.id] = false.obs;
      }

      stories.value = results[1] as List<StoryGroup>;
      liveStoryStreams.assignAll(results[2] as List<LiveStreamModel>);

      // Mark feed load time for long-polling
      _feedLoadedTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _lastNewCount = -1;
      hasNewPosts.value = false;

      // Start long-polling for new posts
      _startLongPolling();
    } catch (e) {
      Get.log('Feed load error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _composeFeed(List<PostModel> newPosts, {bool isRefresh = false}) {
    if (isRefresh) {
      feedItems.clear();
    }

    int postsAdded = 0;
    int adOffset = isRefresh ? 0 : suggestedAds.length; 

    for (var post in newPosts) {
      feedItems.add(FeedItem.post(post));
      postsAdded++;

      if (isRefresh && postsAdded == 1 && suggestedLives.isNotEmpty) {
        feedItems.add(FeedItem.lives(suggestedLives.take(6).toList()));
      }

      // Intersperse logic
      if (postsAdded % 5 == 0 && suggestedAds.isNotEmpty) {
        final adData = suggestedAds[adOffset % suggestedAds.length];
        feedItems.add(FeedItem.ad(AdModel.fromJson(adData)));
        adOffset++;
      }

      if (postsAdded % 6 == 0 && suggestedPages.isNotEmpty) {
        feedItems.add(FeedItem.pages(suggestedPages.take(5).toList()));
      }

      if (postsAdded % 10 == 0 && suggestedGroups.isNotEmpty) {
        feedItems.add(FeedItem.groups(suggestedGroups.take(5).toList()));
      }

      if (postsAdded % 15 == 0 && suggestedPeople.isNotEmpty) {
        feedItems.add(FeedItem.people(suggestedPeople.take(5).toList()));
      }

      if (postsAdded % 7 == 0 && suggestedProducts.isNotEmpty) {
        feedItems.add(FeedItem.products(suggestedProducts.take(5).toList()));
      }
    }
  }

  Future<void> refreshFeed() async {
    _longPollTimer?.cancel();
    hasNewPosts.value = false;
    newPostsCount.value = 0;
    await loadFeed();
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || !_hasMorePages) return;
    isLoadingMore.value = true;

    try {
      final result = await _feedService.getPosts(_currentPage + 1);
      final newPosts = result['posts'] as List<PostModel>;
      posts.addAll(newPosts);
      _nextPageUrl = result['nextPageUrl'];
      _currentPage = result['currentPage'] as int;
      _hasMorePages = _nextPageUrl != null;

      final suggestions = result['suggestions'] as Map<String, dynamic>?;
      if (suggestions != null) {
        suggestedAds.addAll(List<Map<String, dynamic>>.from(suggestions['ads'] ?? []));
        suggestedGroups.addAll(List<Map<String, dynamic>>.from(suggestions['groups'] ?? []));
        suggestedPages.addAll(List<Map<String, dynamic>>.from(suggestions['pages'] ?? []));
        suggestedPeople.addAll(List<Map<String, dynamic>>.from(suggestions['people'] ?? []));
      }

      _composeFeed(newPosts);

      for (var post in newPosts) {
        postComments[post.id] = post.comments.obs;
        isCommentsLoading[post.id] = false.obs;
      }
    } catch (e) {
      Get.log('Load more error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _startLongPolling() {
    _longPollTimer?.cancel();
    _longPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkNewPosts();
    });
    Future.delayed(const Duration(seconds: 10), _checkNewPosts);
  }

  Future<void> _checkNewPosts() async {
    if (_feedLoadedTimestamp == 0) return;
    try {
      final result = await _feedService.checkNewPosts(
        _feedLoadedTimestamp,
        lastCount: _lastNewCount,
      );
      final hasNew = result['has_new'] == true;
      final count = result['count'] as int? ?? 0;

      hasNewPosts.value = hasNew;
      newPostsCount.value = count;
      _lastNewCount = count;
    } catch (e) {
      Get.log('Error checking new posts: $e');
    }
  }

  void showNewPosts() {
    hasNewPosts.value = false;
    newPostsCount.value = 0;
    refreshFeed();
  }

  void scrollToTopAndRefresh() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      ).then((_) {
        refreshFeed();
      });
    } else {
      refreshFeed();
    }
  }

  // ─── Reactions ──────────────────

  Future<void> toggleReaction(int postId, String type) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = posts[index];
    final wasReacted = post.userReaction != null;
    final sameType = post.userReaction == type;

    final updatedPost = post.copyWith(
      userReaction: sameType ? null : type,
      clearUserReaction: sameType,
      reactionsCount: sameType
          ? (post.reactionsCount - 1)
          : (wasReacted ? post.reactionsCount : post.reactionsCount + 1),
    );
    posts[index] = updatedPost;
    
    final feedIndex = feedItems.indexWhere((item) => item.type == FeedItemType.post && item.post?.id == postId);
    if (feedIndex != -1) {
      feedItems[feedIndex] = FeedItem.post(updatedPost);
    }

    try {
      final result = await _postService.toggleReaction(postId, type);
      if (result['success'] == true) {
        final serverType = result['current_type'];
        final finalPost = posts[index].copyWith(
          userReaction: serverType,
          clearUserReaction: serverType == null,
          reactionsCount: result['total_count'] ?? posts[index].reactionsCount,
          reactionSummary: result['summary'] != null ? Map<String, int>.from(result['summary']) : posts[index].reactionSummary,
        );
        posts[index] = finalPost;
        
        if (feedIndex != -1) {
          feedItems[feedIndex] = FeedItem.post(finalPost);
          feedItems.refresh();
        }
        posts.refresh();
      }
    } catch (e) {
      posts[index] = post;
      if (feedIndex != -1) {
        feedItems[feedIndex] = FeedItem.post(post);
        feedItems.refresh();
      }
      posts.refresh();
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
    } catch (_) {
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
      final comment = await _postService.addComment(postId, content, image: image, parentId: parentId);
      if (postComments.containsKey(postId)) {
        if (parentId == null) {
          postComments[postId]!.insert(0, comment);
        } else {
          _addReplyToCommentRecursively(postComments[postId]!, parentId, comment);
        }
      }
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        posts[index] = posts[index].copyWith(commentsCount: posts[index].commentsCount + 1);
      }
      clearReplyTo();
    } catch (e) {
      Get.log('Error adding comment: $e');
    }
  }

  bool _addReplyToCommentRecursively(List<CommentModel> comments, int parentId, CommentModel reply) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == parentId) {
        comments[i] = comments[i].copyWith(replies: [...comments[i].replies, reply]);
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        if (_addReplyToCommentRecursively(comments[i].replies, parentId, reply)) {
          comments[i] = comments[i].copyWith(replies: comments[i].replies);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> toggleCommentReaction(int postId, int commentId, String type) async {
    if (!postComments.containsKey(postId)) return;
    _toggleCommentReactionOptimistic(postComments[postId]!, commentId, type);
    postComments[postId]!.refresh();
    try {
      final result = await _postService.toggleReaction(commentId, type, model: 'comment');
      if (result['success'] == true) {
        _updateCommentReactionFromServer(postComments[postId]!, commentId, result['current_type'], result['total_count'], result['summary'] != null ? Map<String, int>.from(result['summary']) : null);
        postComments[postId]!.refresh();
      }
    } catch (e) {
      Get.log('Error toggling comment reaction: $e');
    }
  }

  bool _toggleCommentReactionOptimistic(List<CommentModel> comments, int commentId, String type) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        final comment = comments[i];
        final wasReacted = comment.userReaction != null;
        final sameType = comment.userReaction == type;
        comments[i] = comment.copyWith(
          userReactionValue: sameType ? null : type,
          likesCount: sameType ? (comment.likesCount - 1) : (wasReacted ? comment.likesCount : comment.likesCount + 1),
        );
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        if (_toggleCommentReactionOptimistic(comments[i].replies, commentId, type)) {
          comments[i] = comments[i].copyWith(replies: comments[i].replies);
          return true;
        }
      }
    }
    return false;
  }

  bool _updateCommentReactionFromServer(List<CommentModel> comments, int commentId, String? currentType, int? totalCount, Map<String, int>? summary) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        comments[i] = comments[i].copyWith(
          userReactionValue: currentType,
          likesCount: totalCount ?? comments[i].likesCount,
          reactionSummary: summary ?? comments[i].reactionSummary,
        );
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        if (_updateCommentReactionFromServer(comments[i].replies, commentId, currentType, totalCount, summary)) {
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
          postComments[postId]![i] = c.copyWith(replies: c.replies.where((r) => r.id != commentId).toList());
        }
      }
    }
    try {
      final res = await _postService.deleteComment(commentId);
      if (res['success'] != true && original != null) postComments[postId]?.assignAll(original);
    } catch (e) {
      Get.log('Error deleting comment: $e');
      if (original != null) postComments[postId]?.assignAll(original);
    }
  }

  // ─── Post Actions ──────────────────

  Future<void> toggleSave(int postId) async {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = posts[index];
    posts[index] = post.copyWith(isSaved: !post.isSaved);
    try {
      await _postService.toggleSave(postId);
    } catch (e) {
      Get.log('Error toggling save: $e');
      posts[index] = post;
    }
  }

  Future<void> sharePost(int postId, String content, String privacy) async {
    try {
      final result = await _postService.sharePost(postId, content, privacy);
      if (result['success'] == true) refreshFeed();
    } catch (e) {
      Get.log('Error sharing post: $e');
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      final res = await _postService.deletePost(postId);
      if (res['success'] == true) {
        posts.removeWhere((p) => p.id == postId);
        feedItems.removeWhere((item) => item.type == FeedItemType.post && item.post?.id == postId);
      }
    } catch (e) {
      Get.log('Error deleting post: $e');
    }
  }

  Future<void> updatePost(int postId, Map<String, dynamic> data) async {
    try {
      final res = await _postService.updatePost(postId, data);
      if (res['success'] == true) {
        final updated = PostModel.fromJson(res['data']);
        final index = posts.indexWhere((p) => p.id == postId);
        if (index != -1) posts[index] = updated;
        final fIndex = feedItems.indexWhere((item) => item.type == FeedItemType.post && item.post?.id == postId);
        if (fIndex != -1) feedItems[fIndex] = FeedItem.post(updated);
      }
    } catch (e) {
      Get.log('Error updating post: $e');
    }
  }

  Future<void> updatePostWithMedia(
    int postId, {
    String? content,
    required String privacy,
    String? postType,
    String? bgColor,
    String? feelingAction,
    String? feelingValue,
    String? location,
    List<File>? newMedia,
    List<int>? removeMediaIds,
  }) async {
    isLoading.value = true;
    try {
      final res = await _postService.updatePostWithMedia(
        postId,
        content: content,
        privacy: privacy,
        postType: postType,
        bgColor: bgColor,
        feelingAction: feelingAction,
        feelingValue: feelingValue,
        location: location,
        newMedia: newMedia,
        removeMediaIds: removeMediaIds,
      );

      if (res['success'] == true) {
        final updated = PostModel.fromJson(res['data']);
        final index = posts.indexWhere((p) => p.id == postId);
        if (index != -1) posts[index] = updated;
        final fIndex = feedItems.indexWhere((item) => item.type == FeedItemType.post && item.post?.id == postId);
        if (fIndex != -1) feedItems[fIndex] = FeedItem.post(updated);
        Get.back();
        Get.snackbar('success'.tr, 'post_updated_successfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white);
      }
    } catch (e) {
      Get.log('Error updating post: $e');
      Get.snackbar('error'.tr, 'failed_to_update_post'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> hidePost(int postId) async {
    try {
      final res = await _postService.hidePost(postId);
      if (res['success'] == true) {
        posts.removeWhere((p) => p.id == postId);
        feedItems.removeWhere((item) => item.type == FeedItemType.post && item.post?.id == postId);
        Get.snackbar(
          'post_hidden'.tr,
          'post_hidden_desc'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey.shade900,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.log('Error hiding post: $e');
      Get.snackbar('error'.tr, 'failed_to_hide_post'.tr);
    }
  }

  Future<void> unhidePost(int postId) async {
    try {
      final res = await _postService.unhidePost(postId);
      if (res['success'] == true) {
        Get.snackbar(
          'post_unhidden'.tr,
          'post_unhidden_desc'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.log('Error unhiding post: $e');
      Get.snackbar('error'.tr, 'failed_to_unhide_post'.tr);
    }
  }

  Future<void> reportPost(int postId, String reason, String? details) async {
    try {
      final res = await _postService.reportPost(postId, reason, details);
      if (res['success'] == true) {
        posts.removeWhere((p) => p.id == postId);
        feedItems.removeWhere((item) => item.type == FeedItemType.post && item.post?.id == postId);
        Get.snackbar(
          'report_submitted'.tr,
          'report_submitted_desc'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.log('Error reporting post: $e');
      Get.snackbar('error'.tr, 'failed_to_submit_report'.tr);
    }
  }

  Future<Map<String, dynamic>?> fetchLinkMeta(String url) async {
    return await _postService.fetchLinkMeta(url);
  }

  Future<void> createPost({
    String? content,
    required String postType,
    String? bgColor,
    String? feelingAction,
    String? feelingValue,
    String? location,
    required String privacy,
    int? groupId,
    int? fanPageId,
    String? linkUrl,
    String? linkTitle,
    String? linkDescription,
    String? linkImage,
    String? linkDomain,
    bool ignoreLinkPreview = false,
    List<File>? media,
    List<int>? tags,
  }) async {
    try {
      isLoading.value = true;
      final result = await _postService.createPost(
        content: content, postType: postType, bgColor: bgColor,
        feelingAction: feelingAction, feelingValue: feelingValue,
        location: location, privacy: privacy, groupId: groupId,
        fanPageId: fanPageId,
        linkUrl: linkUrl, linkTitle: linkTitle,
        linkDescription: linkDescription, linkImage: linkImage,
        linkDomain: linkDomain, ignoreLinkPreview: ignoreLinkPreview,
        media: media, tags: tags,
      );
      if (result['success'] == true) {
        await refreshFeed();
        Get.back();
      }
    } catch (e) {
      Get.log('Error creating post: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _postService.searchUsers(query);
    } catch (e) {
      Get.log('Error searching users: $e');
      return [];
    }
  }

  // ─── Global Search ──────────────────
  final globalSearchResults = <String, List<dynamic>>{
    'people': <UserModel>[].obs,
    'groups': <Map<String, dynamic>>[].obs,
    'posts': <PostModel>[].obs,
  }.obs;
  final isSearchingGlobal = false.obs;

  Future<void> performGlobalSearch(String query) async {
    if (query.isEmpty) return;
    isSearchingGlobal.value = true;
    try {
      final result = await _postService.globalSearch(query);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        
        globalSearchResults['people'] = (data['people'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
            
        globalSearchResults['groups'] = List<Map<String, dynamic>>.from(data['groups'] ?? []);
        
        globalSearchResults['posts'] = (data['posts'] as List)
            .map((p) => PostModel.fromJson(p))
            .toList();
            
        globalSearchResults.refresh();
      }
    } catch (e) {
      Get.log('Global search error: $e');
    } finally {
      isSearchingGlobal.value = false;
    }
  }
}
