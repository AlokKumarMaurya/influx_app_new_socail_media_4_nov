import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/discover_feed_controller.dart';
import '../../controllers/campaign_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../../widgets/common/professional_badge.dart';
import '../../widgets/common/custom_network_image.dart';
import '../../widgets/feed/stories_row.dart';
import '../../widgets/feed/post_card.dart';
import '../user/profile_page.dart';
import '../blog/blog_detail_page.dart';
import '../events/event_detail_page.dart';
import '../../data/models/campaign_model.dart';
import '../../data/models/creator_model.dart';
import '../../data/models/blog_model.dart';
import '../../data/models/event_model.dart';
import '../campaign/campaign_details_page.dart';
import '../campaign/campaign_directory_page.dart';
import '../campaign/my_campaigns_page.dart';
import '../../controllers/auth_controller.dart';
import 'discover_creators_page.dart';
import '../blog/blogs_page.dart';
import '../../controllers/feature_controller.dart';

class DiscoverHomePage extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const DiscoverHomePage({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiscoverFeedController());
    final campaignController = Get.put(CampaignController());
    final authController = Get.find<AuthController>();

    final List<String> niches = [
      'For You',
      'Trending',
      'Fashion',
      'Tech',
      'Food',
      'Travel',
      'Fitness',
      'Beauty',
      'Finance',
    ];

    return Obx(() {
      final bool isCreatorCampaignsEnabled = Get.isRegistered<FeatureController>()
          ? FeatureController.to.isFeatureEnabled('creator_campaigns')
          : true;

      if (!isCreatorCampaignsEnabled) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('creator_campaigns'.tr),
            backgroundColor: AppColors.cardBg,
            elevation: 0,
            leading: onMenuTap != null
                ? IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedMenu01,
                      color: AppColors.textMain,
                      size: 24,
                    ),
                    onPressed: onMenuTap,
                  )
                : null,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMegaphone02,
                    color: AppColors.textSecondary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'feature_unavailable'.tr,
                    style: AppTextStyles.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'feature_unavailable_desc'.tr,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: controller.isLoading.value && controller.trendingCreators.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Stories Row
                      if (controller.stories.isNotEmpty)
                        StoriesRow(stories: controller.stories.toList().cast()),

                      // 2. Sticky Category Filter Bar
                      Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: niches.length,
                          itemBuilder: (context, index) {
                            final niche = niches[index];
                            final isSelected = controller.activeNiche.value == niche;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(niche),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    controller.changeNiche(niche);
                                  }
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                                backgroundColor: AppColors.cardBg,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textMain,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // 3. Stats Bar
                      _buildStatsBar(controller.stats),

                      // 4. Create Campaign Promo Banner (for Business profiles) or Manage campaigns (for Creators)
                      _buildPromoBanner(authController),

                      // 5. Trending Creators
                      if (controller.trendingCreators.isNotEmpty) ...[
                        _buildSectionHeader('trending_creators'.tr, () => Get.to(() => const DiscoverCreatorsPage())),
                        _buildTrendingCreatorsList(controller.trendingCreators),
                      ],

                      // 6. Open Brand Campaigns
                      if (controller.openCampaigns.isNotEmpty) ...[
                        _buildSectionHeader('open_brand_campaigns'.tr, () {
                          campaignController.selectedType.value = 'campaign';
                          Get.to(() => const CampaignDirectoryPage());
                        }),
                        _buildOpenCampaignsList(controller.openCampaigns),
                      ],

                      // 7. Creator Pitches
                      if (controller.creatorPitches.isNotEmpty) ...[
                        _buildSectionHeader('influencer_pitches'.tr, () {
                          campaignController.selectedType.value = 'portfolio';
                          Get.to(() => const CampaignDirectoryPage());
                        }),
                        _buildCreatorPitchesList(controller.creatorPitches),
                      ],

                      // 8. Creator Academy & Resources
                      if (controller.blogs.isNotEmpty) ...[
                        _buildSectionHeader('creator_academy'.tr, () => Get.to(() => const BlogsPage())),
                        _buildAcademyList(controller.blogs),
                      ],

                      // 9. Upcoming Creator Events
                      if (controller.events.isNotEmpty) ...[
                        _buildSectionHeader('upcoming_webinars_events'.tr, null),
                        _buildEventsList(controller.events),
                      ],

                      // 10. Creator Community Feed
                      if (controller.creatorPosts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text('creator_community_feed'.tr, style: AppTextStyles.h2),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.creatorPosts.length,
                          itemBuilder: (context, index) {
                            return PostCard(post: controller.creatorPosts[index]);
                          },
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h3),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'see_all'.tr,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(Map<String, dynamic> stats) {
    final creatorsCount = stats['creators'] ?? 0;
    final campaignsCount = stats['campaigns'] ?? 0;
    final dealsVal = stats['deals'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$creatorsCount', 'Creators'),
          _buildStatItem('$campaignsCount', 'Open Campaigns'),
          _buildStatItem('${Get.find<SettingsController>().currencySymbol.value}$dealsVal', 'Deals Done'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPromoBanner(AuthController authController) {
    final isCreator = authController.user.value?.profileType == 'creator';
    final isBusiness = authController.user.value?.profileType == 'business';

    if (isCreator) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'promote_your_portfolio'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'promote_portfolio_desc'.tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.to(() => const MyCampaignsPage()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('manage_my_pitches'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
            const HugeIcon(icon: HugeIcons.strokeRoundedMegaphone02, color: Colors.white, size: 48),
          ],
        ),
      );
    } else if (isBusiness) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'looking_for_influencers'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'post_brand_campaign_desc'.tr,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.to(() => const MyCampaignsPage()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.lightBlue.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('manage_campaigns'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
            const HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, color: Colors.white, size: 48),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTrendingCreatorsList(List<CreatorModel> creators) {
    return SizedBox(
      height: 175,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: creators.length,
        itemBuilder: (context, index) {
          final creator = creators[index];
          return GestureDetector(
            onTap: () => Get.to(() => ProfilePage(userId: creator.id)),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: creator.avatar != null && creator.avatar!.isNotEmpty
                        ? NetworkImage(UrlUtils.getFullUrl(creator.avatar))
                        : null,
                    child: creator.avatar == null || creator.avatar!.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          creator.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const ProfessionalBadge(profileType: 'creator', size: 12),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    creator.bio ?? 'Creator',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${creator.stats.followersCount} Fans',
                    style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOpenCampaignsList(List<CampaignModel> campaigns) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          final brand = campaign.user;
          return GestureDetector(
            onTap: () => Get.to(() => CampaignDetailsPage(campaignId: campaign.id)),
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPlatformIcons(campaign.platforms),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          campaign.niche != null ? campaign.niche!.toUpperCase() : 'COLLAB',
                          style: const TextStyle(
                            color: AppColors.primary, 
                            fontSize: 9, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      campaign.title,
                      style: AppTextStyles.h4.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        campaign.budgetTo != null 
                            ? '${Get.find<SettingsController>().currencySymbol.value}${campaign.budgetFrom?.toInt() ?? 0} - ${Get.find<SettingsController>().currencySymbol.value}${campaign.budgetTo?.toInt()}' 
                            : 'Collab',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: brand?.avatar != null && brand!.avatar!.isNotEmpty
                            ? NetworkImage(UrlUtils.getFullUrl(brand.avatar))
                            : null,
                        child: brand?.avatar == null || brand!.avatar!.isEmpty
                            ? const Icon(Icons.person, size: 10)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          brand?.name ?? 'Brand Partner',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreatorPitchesList(List<CampaignModel> pitches) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pitches.length,
        itemBuilder: (context, index) {
          final pitch = pitches[index];
          final hasMedia = pitch.media.isNotEmpty;

          return GestureDetector(
            onTap: () => Get.to(() => CampaignDetailsPage(campaignId: pitch.id)),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: hasMedia
                          ? CustomNetworkImage(
                              imageUrl: UrlUtils.getFullUrl(pitch.media.first.filePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pitch.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pitch.user?.name ?? 'Creator',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                pitch.budgetFrom != null ? '${Get.find<SettingsController>().currencySymbol.value}${pitch.budgetFrom?.toInt()}' : 'Collab',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAcademyList(List<BlogModel> blogs) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          final blog = blogs[index];
          final hasImage = blog.featuredImage != null && blog.featuredImage!.isNotEmpty;

          return GestureDetector(
            onTap: () {
              try {
                Get.to(() => BlogDetailPage(slug: blog.slug));
              } catch (e) {
                Get.log('Error navigating to blog detail page: $e');
              }
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: hasImage
                          ? CustomNetworkImage(
                              imageUrl: UrlUtils.getFullUrl(blog.featuredImage),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Center(
                                child: Icon(Icons.menu_book, color: AppColors.primary, size: 36),
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                blog.category?.toUpperCase() ?? 'CREATOR',
                                style: const TextStyle(
                                  color: AppColors.primary, 
                                  fontSize: 9, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                                '${blog.readingTime} min read',
                                style: TextStyle(
                                  color: AppColors.textSecondary, 
                                  fontSize: 9
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              blog.title,
                              style: AppTextStyles.h4.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundImage: blog.author?.avatar != null && blog.author!.avatar!.isNotEmpty
                                    ? NetworkImage(UrlUtils.getFullUrl(blog.author!.avatar))
                                    : null,
                                child: blog.author?.avatar == null || blog.author!.avatar!.isEmpty
                                    ? const Icon(Icons.person, size: 8)
                                    : null,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  blog.author?.name ?? 'Academy Coach',
                                  style: TextStyle(
                                    fontSize: 9, 
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsList(List<EventModel> events) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
          color: AppColors.cardBg,
          child: ListTile(
            onTap: () {
              try {
                Get.to(() => EventDetailPage(eventId: event.id));
              } catch (e) {
                Get.log('Error navigating to event detail page: $e');
              }
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${event.startDate.day}',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _getMonthAbbr(event.startDate.month),
                    style: TextStyle(color: AppColors.primary, fontSize: 10),
                  ),
                ],
              ),
            ),
            title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(event.location ?? 'Online Webinar', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          ),
        );
      },
    );
  }

  Widget _buildPlatformIcons(List<String> platforms) {
    final icons = <Widget>[];
    for (var platform in platforms) {
      IconData? iconData;
      Color color = Colors.grey;

      switch (platform.toLowerCase()) {
        case 'instagram':
          iconData = Icons.camera_alt_outlined;
          color = const Color(0xFFE4405F);
          break;
        case 'tiktok':
          iconData = Icons.music_note;
          color = Colors.black;
          break;
        case 'youtube':
          iconData = Icons.play_arrow_outlined;
          color = Colors.red;
          break;
        case 'twitter':
          iconData = Icons.alternate_email;
          color = const Color(0xFF1DA1F2);
          break;
        case 'facebook':
          iconData = Icons.facebook;
          color = const Color(0xFF1877F2);
          break;
      }

      if (iconData != null) {
        icons.add(Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(iconData, size: 12, color: color),
        ));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'JAN';
  }
}
