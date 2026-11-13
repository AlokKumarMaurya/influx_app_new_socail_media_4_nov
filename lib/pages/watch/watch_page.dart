import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';
import '../../controllers/watch_controller.dart';
import '../../widgets/watch/watch_video_card.dart';
import '../../widgets/feed/ad_card.dart';
import '../../widgets/feed/suggested_section.dart';
import '../../data/models/feed_item.dart';

class WatchPage extends StatefulWidget {
  const WatchPage({super.key});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  final ScrollController _scrollController = ScrollController();
  late WatchController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(WatchController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: AppColors.background,
        body: controller.isLoading.value
            ? _buildShimmerLoading()
            : controller.videos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tv_off_rounded,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_videos_yet'.tr,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'be_first_share_video'.tr,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.refreshVideos,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  cacheExtent: 800,
                  itemCount:
                      controller.feedItems.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.feedItems.length &&
                        controller.isLoadingMore.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final item = controller.feedItems[index];
                    switch (item.type) {
                      case FeedItemType.post:
                        final videoModel = controller.videos.firstWhereOrNull(
                          (v) => v.post.id == item.post?.id,
                        );
                        if (videoModel == null) return const SizedBox.shrink();
                        return WatchVideoCard(video: videoModel);
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
                                  subtitle:
                                      '${u['mutual_friends'] ?? 0} ${'mutual_friends'.tr}',
                                  imageUrl: u['avatar'],
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
                                  subtitle:
                                      '${p['currency'] ?? '\$'}${p['price'] ?? '0.00'}',
                                  imageUrl: p['primary_image_url'],
                                  cta: 'view'.tr,
                                ),
                              )
                              .toList(),
                        );
                      case FeedItemType.suggestedLives:
                        return SuggestedSection(
                          title: 'Live Now',
                          type: 'lives',
                          items: item.suggestions!
                              .map(
                                (l) => SuggestedItem(
                                  id: l['id'],
                                  slug: l['uuid'],
                                  name: l['title'] ?? 'Live Broadcast',
                                  subtitle: '${l['broadcaster_name'] ?? ''} • ${l['viewer_count'] ?? 0} watching',
                                  imageUrl: l['thumbnail_url'] ?? l['broadcaster_avatar'],
                                  cta: 'Watch Live',
                                ),
                              )
                              .toList(),
                        );
                    }
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: 3,
      itemBuilder: (context, index) {
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
              // User header shimmer
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
              // Caption shimmer
              _shimmerBox(double.infinity, 14),
              const SizedBox(height: 8),
              // Video player shimmer
              _shimmerBox(double.infinity, 250, radius: 14),
              const SizedBox(height: 16),
              // Stats bar shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerBox(80, 20),
                  _shimmerBox(80, 20),
                  _shimmerBox(80, 20),
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
