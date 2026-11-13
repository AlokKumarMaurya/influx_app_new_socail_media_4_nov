import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';
import '../../controllers/feed_controller.dart';
import '../../widgets/feed/stories_row.dart';
import '../../widgets/feed/create_post_card.dart';
import '../../widgets/feed/feed_filter_bar.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/feed/suggested_section.dart';
import '../../widgets/feed/ad_card.dart';
import '../../data/models/feed_item.dart';

class FeedPage extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const FeedPage({super.key, this.onMenuTap});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late FeedController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FeedController());
    controller.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    controller.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (controller.scrollController.hasClients &&
        controller.scrollController.position.pixels >=
            controller.scrollController.position.maxScrollExtent - 300) {
      controller.loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      body: controller.isLoading.value
          ? _buildShimmerLoading()
          : Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.refreshFeed,
                  child: ListView.builder(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    cacheExtent: 300,
                    itemCount: controller.feedItems.length + 3 + (controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return RepaintBoundary(
                          child: StoriesRow(
                            stories: controller.stories.toList().cast(),
                            liveStreams: controller.liveStoryStreams.toList(),
                          ),
                        );
                      }
                      if (index == 1) {
                        return const RepaintBoundary(child: CreatePostCard());
                      }
                      // if (index == 2) {
                      //   return const RepaintBoundary(child: FeedFilterBar());
                      // }
                      int itemIndex = index - 3;
                      if (itemIndex >= 0 && itemIndex < controller.feedItems.length) {
                        final item = controller.feedItems[itemIndex];
                        return RepaintBoundary(child: _buildFeedItem(item));
                      }
                      if (controller.isLoadingMore.value && index == (controller.feedItems.length + 3)) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                if (controller.hasNewPosts.value)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(child: _buildNewPostsBanner(controller.newPostsCount.value)),
                  ),
              ],
            ),
    ));
  }

  Widget _buildNewPostsBanner(int count) {
    return GestureDetector(
      onTap: controller.showNewPosts,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '$count ${'new_posts'.tr}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    switch (item.type) {
      case FeedItemType.post:
        return PostCard(post: item.post!,isSingleView: true,);
      case FeedItemType.ad:
        return AdCard(ad: item.ad!);
      case FeedItemType.suggestedGroups:
        return SuggestedSection(
          title: 'suggested_groups'.tr,
          type: 'groups',
          items: item.suggestions!
              .map(
                (g) => SuggestedItem(
                  name: g['name'] ?? '',
                  subtitle: '${g['member_count'] ?? 0} ${'members'.tr}',
                  imageUrl: g['avatar'],
                ),
              )
              .toList(),
        );
      case FeedItemType.suggestedPages:
        return SuggestedSection(
          title: 'Suggested Pages',
          type: 'pages',
          items: item.suggestions!
              .map(
                (p) => SuggestedItem(
                  id: p['id'],
                  slug: p['slug'],
                  name: p['name'] ?? '',
                  subtitle: '${p['category_name'] ?? 'Page'} • ${p['followers_count'] ?? 0} followers',
                  imageUrl: p['avatar'],
                  cta: 'Follow',
                ),
              )
              .toList(),
        );
      case FeedItemType.suggestedPeople:
        return SuggestedSection(
          title: 'people_you_may_know'.tr,
          type: 'people',
          items: item.suggestions!
              .map(
                (u) => SuggestedItem(
                  name: u['name'] ?? '',
                  subtitle: '${u['mutual_friends'] ?? 0} ${'mutual_friends'.tr}',
                  imageUrl: u['avatar'],
                  profileType: u['profile_type'],
                ),
              )
              .toList(),
        );
      case FeedItemType.suggestedProducts:
        return SuggestedSection(
          title: 'products_you_may_like'.tr,
          type: 'products',
          items: item.suggestions!
              .map(
                (p) => SuggestedItem(
                  id: p['id'],
                  name: p['title'] ?? '',
                  subtitle: '${p['currency'] ?? '\$'}${p['price'] ?? '0.00'}',
                  imageUrl: p['primary_image_url'],
                  cta: 'view'.tr,
                ),
              )
              .toList(),
        );
      case FeedItemType.suggestedLives:
        return SuggestedSection(
          title: '🔴 Live Streams Now',
          type: 'lives',
          items: item.suggestions!
              .map(
                (l) => SuggestedItem(
                  id: l['id'],
                  slug: l['uuid'],
                  name: l['title'] ?? 'Live Broadcast',
                  subtitle: '${l['broadcaster_name'] ?? 'Streamer'} • 👁 ${l['viewer_count'] ?? 0}',
                  imageUrl: l['thumbnail_url'],
                  cta: 'Watch Live',
                ),
              )
              .toList(),
        );
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: 5,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Stories Shimmer
          return Container(
            height: 160,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 6,
              itemBuilder: (context, _) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _shimmerBox(70, 100, isCircle: false, radius: 14),
              ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(44, 44, isCircle: true),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(140, 12),
                      const SizedBox(height: 6),
                      _shimmerBox(90, 10),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 14),
              const SizedBox(height: 8),
              _shimmerBox(double.infinity * 0.7, 14),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 220, radius: 14),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(60, 24, radius: 6),
                  _shimmerBox(60, 24, radius: 6),
                  _shimmerBox(60, 24, radius: 6),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(
    double width,
    double height, {
    bool isCircle = false,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}
