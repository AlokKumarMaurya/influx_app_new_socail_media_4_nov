import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/models/group_model.dart';
import '../data/models/post_model.dart';
import '../data/models/feed_item.dart';
import '../data/services/group_service.dart';

class GroupsController extends GetxController {
  final GroupService _groupService = GroupService();

  final myGroups = <GroupModel>[].obs;
  final suggestedGroups = <GroupModel>[].obs;
  final feedItems = <FeedItem>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;

  final suggestedAds = <Map<String, dynamic>>[].obs;
  final suggestedDiscoveryGroups = <GroupModel>[].obs;

  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void onInit() {
    super.onInit();
    loadGroupsTab();
  }

  Future<void> loadGroupsTab() async {
    isLoading.value = true;
    _currentPage = 1;
    _hasMorePages = true;

    try {
      final results = await Future.wait([
        _groupService.getGroupsLanding(),
        _groupService.getGroupFeed(1),
      ]);

      final landing = results[0];
      myGroups.assignAll(landing['my_groups']);
      suggestedGroups.assignAll(landing['suggested']);

      final feedResult = results[1];
      final posts = feedResult['posts'] as List<PostModel>? ?? [];
      _currentPage = feedResult['currentPage'] ?? 1;
      _hasMorePages = feedResult['nextPageUrl'] != null;

      final suggestions = feedResult['suggestions'];
      if (suggestions != null) {
        suggestedAds.assignAll(List<Map<String, dynamic>>.from(suggestions['ads'] ?? []));
        if (suggestions['groups'] != null) {
          suggestedDiscoveryGroups.assignAll(
            (suggestions['groups'] as List).map((g) => GroupModel.fromJson(g)).toList()
          );
        }
      }

      _composeFeed(posts, isRefresh: true);
    } catch (e, stack) {
      debugPrint('GROUPS_DEBUG: load error: $e');
      debugPrint('GROUPS_DEBUG: stack: $stack');
    } finally {
      isLoading.value = false;
    }
  }

  void _composeFeed(List<PostModel> posts, {bool isRefresh = false}) {
    if (isRefresh) feedItems.clear();

    int postsAdded = 0;
    int adOffset = isRefresh ? 0 : feedItems.where((i) => i.type == FeedItemType.ad).length;

    for (var post in posts) {
      feedItems.add(FeedItem.post(post));
      postsAdded++;

      if (postsAdded % 5 == 0 && suggestedAds.isNotEmpty) {
        final adData = suggestedAds[adOffset % suggestedAds.length];
        feedItems.add(FeedItem.ad(AdModel.fromJson(adData)));
        adOffset++;
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMorePages) return;
    isLoadingMore.value = true;

    try {
      final result = await _groupService.getGroupFeed(_currentPage + 1);
      final posts = result['posts'] as List<PostModel>? ?? [];
      _currentPage = result['currentPage'] ?? (_currentPage + 1);
      _hasMorePages = result['nextPageUrl'] != null;

      _composeFeed(posts);
    } catch (e) {
      Get.log('Groups load more error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadGroupsTab();
  }
}
