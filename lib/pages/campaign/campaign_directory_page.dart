import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/campaign_controller.dart';
import '../../utils/app_theme.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/url_utils.dart';
import '../../data/models/campaign_model.dart';
import '../../widgets/common/custom_network_image.dart';
import 'campaign_details_page.dart';

class CampaignDirectoryPage extends StatefulWidget {
  const CampaignDirectoryPage({super.key});

  @override
  State<CampaignDirectoryPage> createState() => _CampaignDirectoryPageState();
}

class _CampaignDirectoryPageState extends State<CampaignDirectoryPage> {
  late CampaignController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<CampaignController>()
        ? Get.find<CampaignController>()
        : Get.put(CampaignController());
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchCampaigns(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (controller.hasMore.value && !controller.isLoading.value) {
        controller.fetchCampaigns();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> niches = [
      {'key': 'All', 'label': 'all'.tr},
      {'key': 'Fashion', 'label': 'fashion'.tr},
      {'key': 'Tech', 'label': 'tech'.tr},
      {'key': 'Food', 'label': 'food'.tr},
      {'key': 'Travel', 'label': 'travel'.tr},
      {'key': 'Fitness', 'label': 'fitness'.tr},
      {'key': 'Beauty', 'label': 'beauty'.tr},
      {'key': 'Finance', 'label': 'finance'.tr},
    ];

    final List<String> types = [
      'All',
      'campaign',
      'portfolio',
      'collab',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text('campaign_directory'.tr, style: AppTextStyles.h3),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) {
                controller.searchQuery.value = val;
                controller.fetchCampaigns(isRefresh: true);
              },
              decoration: InputDecoration(
                hintText: 'search_campaigns'.tr,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.searchQuery.value = '';
                          controller.fetchCampaigns(isRefresh: true);
                        },
                      )
                    : const SizedBox.shrink()),
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.isDark ? Colors.white10 : Colors.black12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
              ),
            ),
          ),

          // Filters Tab/Choice section
          Container(
            height: 35,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: types.length,
              itemBuilder: (context, index) {
                final type = types[index];
                final displayLabel = type == 'campaign'
                    ? 'brand_campaigns'.tr
                    : type == 'portfolio'
                        ? 'influencer_pitches'.tr
                        : type == 'collab'
                            ? 'collabs'.tr
                            : 'all_types'.tr;
                return Obx(() {
                  final isSelected = controller.selectedType.value == type;
                  return GestureDetector(
                    onTap: () {
                      controller.selectedType.value = type;
                      controller.fetchCampaigns(isRefresh: true);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          displayLabel,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textMain,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),

          // Niche Choice row
          Container(
            height: 35,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: niches.length,
              itemBuilder: (context, index) {
                 final niche = niches[index];
                 final key = niche['key']!;
                 final label = niche['label']!;
                 return Obx(() {
                   final isSelected = controller.selectedNiche.value == key;
                   return GestureDetector(
                     onTap: () {
                       controller.selectedNiche.value = key;
                       controller.fetchCampaigns(isRefresh: true);
                     },
                     child: Container(
                       margin: const EdgeInsets.only(right: 8),
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                       decoration: BoxDecoration(
                         color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(
                           color: isSelected ? AppColors.primary : Colors.transparent,
                         ),
                       ),
                       child: Center(
                         child: Text(
                           label,
                           style: TextStyle(
                             color: isSelected ? AppColors.primary : AppColors.textSecondary,
                             fontSize: 11,
                             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                           ),
                         ),
                       ),
                     ),
                   );
                 });
              },
            ),
          ),

          // Campaigns List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.campaigns.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (controller.campaigns.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, color: Colors.grey, size: 48),
                      const SizedBox(height: 16),
                      Text('no_campaigns_found'.tr, style: AppTextStyles.h3),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchCampaigns(isRefresh: true),
                color: AppColors.primary,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: controller.campaigns.length + (controller.isLoading.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= controller.campaigns.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      );
                    }
                    return _buildCampaignCard(controller.campaigns[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(CampaignModel campaign) {
    final hasMedia = campaign.media.isNotEmpty;
    final String symbol = Get.find<SettingsController>().currencySymbol.value;
    final displayBudget = campaign.budgetTo != null
        ? '$symbol${campaign.budgetFrom?.toInt() ?? 0} - $symbol${campaign.budgetTo?.toInt()}'
        : campaign.budgetFrom != null
            ? '$symbol${campaign.budgetFrom?.toInt()}'
            : 'collab_offer'.tr;

    return GestureDetector(
      onTap: () => Get.to(() => CampaignDetailsPage(campaignId: campaign.id)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: hasMedia
                      ? CustomNetworkImage(
                          imageUrl: UrlUtils.getFullUrl(campaign.media.first.filePath),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Center(
                            child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: AppColors.primary, size: 24),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Campaign Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: campaign.type == 'campaign'
                                ? Colors.lightBlue.shade100.withValues(alpha: 0.3)
                                : Colors.indigo.shade100.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            campaign.type == 'campaign'
                                ? 'brand_campaign'.tr
                                : campaign.type == 'portfolio'
                                    ? 'creator_pitch'.tr
                                    : 'collab'.tr,
                            style: TextStyle(
                              color: campaign.type == 'campaign' ? Colors.blue : Colors.indigo,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (campaign.niche != null)
                          Text(
                            '#${campaign.niche}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      campaign.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayBudget,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        _buildPlatformIcons(campaign.platforms),
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
          child: Icon(iconData, size: 14, color: color),
        ));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }
}
