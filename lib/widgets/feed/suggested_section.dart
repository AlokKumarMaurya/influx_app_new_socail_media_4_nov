import 'package:material_ui/material_ui.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../common/professional_badge.dart';
import 'package:get/get.dart';
import '../../pages/marketplace/product_detail_page.dart';
import '../../pages/fan_page/fan_page_profile_page.dart';
import '../../pages/live/live_room_page.dart';
import '../../pages/live/live_streams_page.dart';

class SuggestedSection extends StatelessWidget {
  final String title;
  final List<SuggestedItem> items;
  final String type; // 'groups', 'pages', 'people', 'ads'

  const SuggestedSection({
    super.key,
    required this.title,
    required this.items,
    this.type = 'groups',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    if (type == 'ads') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'sponsored'.tr,
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (type == 'lives') {
                      Get.to(() => const LiveStreamsPage());
                    }
                  },
                  child: Text('see_all'.tr, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildCard(items[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(SuggestedItem item) {
    final isGroup = type == 'groups';
    final isAd = type == 'ads';

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: item.imageUrl != null
                  ? DecorationImage(image: CachedNetworkImageProvider(UrlUtils.getFullUrl(item.imageUrl!)), fit: BoxFit.cover)
                  : null,
            ),
            child: item.imageUrl == null
                ? Center(
                    child: HugeIcon(
                      icon: isGroup
                          ? HugeIcons.strokeRoundedUserGroup
                          : (type == 'pages'
                              ? HugeIcons.strokeRoundedFlag02
                              : (isAd ? HugeIcons.strokeRoundedAdvertisement : (type == 'products' ? HugeIcons.strokeRoundedStore01 : HugeIcons.strokeRoundedUser))),
                      color: AppColors.primary,
                      size: 32,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.profileType != null && item.profileType != 'user') ...[
                        const SizedBox(width: 4),
                        ProfessionalBadge(profileType: item.profileType, size: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {
                          if (type == 'lives' && item.slug != null) {
                            Get.to(() => LiveRoomPage(uuid: item.slug!));
                          } else if (type == 'products' && item.id != null) {
                            Get.to(() => ProductDetailPage(productId: item.id!), preventDuplicates: false);
                          } else if (type == 'pages' && item.slug != null) {
                            Get.to(() => FanPageProfilePage(slug: item.slug!));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAd ? Colors.grey[800] : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: Text(
                          isAd
                              ? (item.cta ?? 'learn_more'.tr)
                              : (isGroup
                                  ? 'join'.tr
                                  : (type == 'pages' || type == 'lives'
                                      ? (item.cta ?? 'Follow')
                                      : (type == 'products' ? (item.cta ?? 'view'.tr) : 'add_friend'.tr))),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SuggestedItem {
  final int? id;
  final String? slug;
  final String name;
  final String subtitle;
  final String? imageUrl;
  final String? profileType;
  final String? cta;

  SuggestedItem({
    this.id,
    this.slug,
    required this.name,
    required this.subtitle,
    this.imageUrl,
    this.profileType,
    this.cta,
  });
}
