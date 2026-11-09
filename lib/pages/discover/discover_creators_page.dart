import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/discover_controller.dart';
import '../../data/models/creator_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/professional_badge.dart';
import '../user/profile_page.dart';

class DiscoverCreatorsPage extends StatelessWidget {
  const DiscoverCreatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DiscoverController());

    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('discover_creators'.tr, style: AppTextStyles.h3),
            Text('discover_creators_subtitle'.tr,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
      ),
      body: controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : controller.creators.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedStar,
                          color: AppColors.textSecondary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('no_creators_found'.tr, style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text('no_creators_found_desc'.tr,
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: controller.refreshCreators,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: controller.creators.length + (controller.isLoadingMore.value ? 2 : 0),
                      itemBuilder: (context, index) {
                        if (index >= controller.creators.length) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        return _CreatorCard(
                          creator: controller.creators[index],
                          controller: controller,
                        );
                      },
                    ),
                  ),
                ),
    ));
  }
}

class _CreatorCard extends StatelessWidget {
  final CreatorModel creator;
  final DiscoverController controller;

  const _CreatorCard({required this.creator, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ProfilePage(userId: creator.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cover
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: creator.cover != null
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        creator.cover!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, i1, i2) => const SizedBox(),
                      ),
                    )
                  : null,
            ),
            // Avatar overlapping cover
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.background,
                  backgroundImage:
                      creator.avatar != null ? NetworkImage(creator.avatar!) : null,
                  child: creator.avatar == null
                      ? HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          color: AppColors.textSecondary,
                          size: 24,
                        )
                      : null,
                ),
              ),
            ),
            // Info (negative margin to compensate avatar offset)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Transform.translate(
                  offset: const Offset(0, -16),
                  child: Column(
                    children: [
                      // Name + badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              creator.name,
                              style: AppTextStyles.h4.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 3),
                          ProfessionalBadge(profileType: 'creator', size: 14),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        creator.work ?? creator.bio ?? 'creator'.tr,
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      // Social links
                      _buildSocialLinks(),
                      const SizedBox(height: 6),
                      // Stats
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.textSecondary.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat('${creator.stats.followersCount}', 'follower'.tr),
                            _buildStat('${creator.stats.followingCount}', 'following'.tr),
                            _buildStat('${creator.stats.postsCount}', 'posts'.tr),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Action button
                      _buildActionButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    final links = <Widget>[];
    if (creator.socialLinks['facebook'] != null) {
      links.add(_socialIcon(Icons.facebook, creator.socialLinks['facebook']!, const Color(0xFF1877F2)));
    }
    if (creator.socialLinks['instagram'] != null) {
      links.add(_socialIcon(Icons.camera_alt_outlined, creator.socialLinks['instagram']!, const Color(0xFFE4405F)));
    }
    if (creator.socialLinks['twitter'] != null) {
      links.add(_socialIcon(Icons.alternate_email, creator.socialLinks['twitter']!, const Color(0xFF1DA1F2)));
    }
    if (creator.socialLinks['linkedin'] != null) {
      links.add(_socialIcon(Icons.work_outline, creator.socialLinks['linkedin']!, const Color(0xFF0A66C2)));
    }

    if (links.isEmpty) {
      return Text('no_social_links'.tr, style: AppTextStyles.bodySmall.copyWith(fontSize: 9));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: links,
    );
  }

  Widget _socialIcon(IconData icon, String url, Color color) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain)),
        Text(label,
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildActionButton() {
    switch (creator.relation) {
      case 'friends':
        return SizedBox(
          width: double.infinity,
          height: 28,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: AppColors.primary),
            ),
            child: Text('friends'.tr, style: TextStyle(fontSize: 11, color: AppColors.primary)),
          ),
        );
      case 'pending_sent':
        return SizedBox(
          width: double.infinity,
          height: 28,
          child: OutlinedButton(
            onPressed: () => controller.cancelFriendRequest(creator.id),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: AppColors.textSecondary),
            ),
            child: Text('cancel_request'.tr, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ),
        );
      case 'pending_received':
        return SizedBox(
          width: double.infinity,
          height: 28,
          child: ElevatedButton(
            onPressed: () {}, // Accept logic handled in profile
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('accept'.tr, style: const TextStyle(fontSize: 11, color: Colors.white)),
          ),
        );
      default:
        return SizedBox(
          width: double.infinity,
          height: 28,
          child: ElevatedButton(
            onPressed: () => controller.sendFriendRequest(creator.id),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('add_friend'.tr, style: const TextStyle(fontSize: 11, color: Colors.white)),
          ),
        );
    }
  }
}
