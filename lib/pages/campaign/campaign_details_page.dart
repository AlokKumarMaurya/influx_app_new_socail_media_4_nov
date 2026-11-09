import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:influx_app/utils/url_utils.dart';
import '../../controllers/campaign_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../data/models/campaign_model.dart';
import '../../data/models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';
import '../user/profile_page.dart';
import 'campaign_create_page.dart';

class CampaignDetailsPage extends StatefulWidget {
  final int campaignId;

  const CampaignDetailsPage({super.key, required this.campaignId});

  @override
  State<CampaignDetailsPage> createState() => _CampaignDetailsPageState();
}

class _CampaignDetailsPageState extends State<CampaignDetailsPage> {
  late CampaignController controller;
  late AuthController authController;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<CampaignController>()
        ? Get.find<CampaignController>()
        : Get.put(CampaignController());
    authController = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchCampaignDetails(widget.campaignId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textMain,
            size: 24,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text('campaign_details'.tr, style: AppTextStyles.h3),
        actions: [
          Obx(() {
            final campaign = controller.campaignDetails.value;
            if (campaign == null) return const SizedBox.shrink();

            final isOwner = campaign.userId == authController.user.value?.id;
            if (!isOwner) return const SizedBox.shrink();

            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Get.to(() => CampaignCreatePage(campaign: campaign));
                } else if (value == 'delete') {
                  _showDeleteConfirm(campaign.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text('edit_campaign'.tr),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final campaign = controller.campaignDetails.value;
        if (campaign == null) {
          return Center(
            child: Text(
              'failed_load_campaign_details'.tr,
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        final isOwner = campaign.userId == authController.user.value?.id;
        final hasMedia = campaign.media.isNotEmpty;

        final String symbol = Get.find<SettingsController>().currencySymbol.value;
        final displayBudget = campaign.budgetTo != null
            ? '$symbol${campaign.budgetFrom?.toInt() ?? 0} - $symbol${campaign.budgetTo?.toInt()}'
            : campaign.budgetFrom != null
            ? '$symbol${campaign.budgetFrom?.toInt()}'
            : 'collab_offer'.tr;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media Gallery (Carousel)
                    if (hasMedia)
                      Stack(
                        children: [
                          SizedBox(
                            height: 250,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemCount: campaign.media.length,
                              itemBuilder: (context, index) {
                                final item = campaign.media[index];
                                final isVideo = item.type == 'video';

                                if (isVideo) {
                                  return Container(
                                    color: Colors.black87,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ),
                                  );
                                }

                                return CustomNetworkImage(
                                  imageUrl: UrlUtils.getFullUrl(item.filePath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            ),
                          ),
                          if (campaign.media.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  campaign.media.length,
                                  (index) => Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == index
                                          ? AppColors.primary
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type Tag & Niche
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: campaign.type == 'campaign'
                                      ? Colors.lightBlue.shade100.withValues(
                                          alpha: 0.3,
                                        )
                                      : Colors.indigo.shade100.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  campaign.type == 'campaign'
                                      ? 'brand_campaign'.tr
                                      : campaign.type == 'portfolio'
                                      ? 'creator_pitch'.tr
                                      : 'collab'.tr,
                                  style: TextStyle(
                                    color: campaign.type == 'campaign'
                                        ? Colors.blue
                                        : Colors.indigo,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (campaign.niche != null)
                                Text(
                                  '#${campaign.niche}',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(campaign.title, style: AppTextStyles.h2),
                          const SizedBox(height: 12),

                          // Budget Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'estimated_budget'.tr,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayBudget,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Target Platforms
                          if (campaign.platforms.isNotEmpty) ...[
                            Text('target_platforms'.tr, style: AppTextStyles.h4),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: campaign.platforms
                                  .map((p) => _buildPlatformBadge(p))
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Description
                          if (campaign.description != null &&
                              campaign.description!.isNotEmpty) ...[
                            Text(
                              'description_details'.tr,
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              campaign.description!,
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Creator / Brand Profile Card
                          Text(
                            campaign.type == 'campaign'
                                ? 'brand_poster'.tr
                                : 'creator_profile'.tr,
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 8),
                          _buildProfileCard(campaign.user),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Send Message / CTA Button at bottom
            if (!isOwner && campaign.user != null)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _initiateChat(campaign),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMessage01,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'send_message_collab'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildPlatformBadge(String platform) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            platform.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel? user) {
    if (user == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Get.to(() => ProfilePage(userId: user.id)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                  ? NetworkImage(UrlUtils.getFullUrl(user.avatar))
                  : null,
              child: user.avatar == null || user.avatar!.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.bio ?? 'tap_to_view_profile'.tr,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(int id) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_campaign'.tr),
        content: Text(
          'delete_campaign_confirm'.tr,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteCampaign(id);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateChat(CampaignModel campaign) async {
    final chatController = Get.put(ChatController());
    final greeting = 'campaign_chat_greeting'.trParams({
      'name': campaign.user?.name ?? '',
      'title': campaign.title,
    });

    Get.showOverlay(
      asyncFunction: () => chatController.startConversationAndSendGreeting(
        campaign.userId,
        greeting,
      ),
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }
}
