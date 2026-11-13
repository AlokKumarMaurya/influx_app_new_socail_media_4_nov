import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/campaign_controller.dart';
import '../../utils/app_theme.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/url_utils.dart';
import '../../data/models/campaign_model.dart';
import '../../widgets/common/custom_network_image.dart';
import 'campaign_create_page.dart';
import 'campaign_details_page.dart';

class MyCampaignsPage extends StatefulWidget {
  const MyCampaignsPage({super.key});

  @override
  State<MyCampaignsPage> createState() => _MyCampaignsPageState();
}

class _MyCampaignsPageState extends State<MyCampaignsPage> {
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
      controller.fetchMyCampaigns(isRefresh: true);
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
        controller.fetchMyCampaigns();
      }
    }
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
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text('my_campaigns'.tr, style: AppTextStyles.h3),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const CampaignCreatePage()),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.myCampaigns.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.myCampaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedMegaphone02, color: Colors.grey, size: 48),
                const SizedBox(height: 16),
                Text('no_campaigns_posted_yet'.tr, style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text('create_first_pitch_brand_deals'.tr, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Get.to(() => const CampaignCreatePage()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: Text('post_collab_pitch'.tr),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchMyCampaigns(isRefresh: true),
          color: AppColors.primary,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: controller.myCampaigns.length + (controller.isLoading.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.myCampaigns.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              final campaign = controller.myCampaigns[index];
              return _buildMyCampaignCard(campaign);
            },
          ),
        );
      }),
    );
  }

  Widget _buildMyCampaignCard(CampaignModel campaign) {
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
                        _buildStatusPill(campaign.status),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayBudget,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Edit Action Button
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                onPressed: () => Get.to(() => CampaignCreatePage(campaign: campaign)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color = Colors.grey;
    String label = status.toUpperCase();

    if (status == 'active') {
      color = Colors.green;
      label = 'active'.tr.toUpperCase();
    } else if (status == 'draft') {
      color = Colors.orange;
      label = 'draft'.tr.toUpperCase();
    } else if (status == 'closed') {
      color = Colors.red;
      label = 'closed'.tr.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
