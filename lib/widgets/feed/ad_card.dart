import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../utils/app_theme.dart';
import '../../pages/feed/single_post_page.dart';
import '../common/custom_network_image.dart';
import '../common/video_player_widget.dart';
import '../../data/models/feed_item.dart';
import '../../controllers/feed_controller.dart';
import 'post_card.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/marketplace_service.dart';
import '../../controllers/feature_controller.dart';

class AdCard extends StatelessWidget {
  final AdModel ad;

  const AdCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final bool isAdsEnabled = Get.isRegistered<FeatureController>()
        ? FeatureController.to.isFeatureEnabled('ads_system')
        : true;
    if (!isAdsEnabled) {
      return const SizedBox.shrink();
    }

    final isPostAd = ad.adType == 'post' && ad.postId != null;

    if (isPostAd) {
      return Obx(() {
        final post = Get.find<FeedController>().posts.firstWhereOrNull((p) => p.id == ad.postId);
        if (post == null) return const SizedBox.shrink();

        return VisibilityDetector(
          key: Key('ad_post_${ad.id}'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction > 0.5) {
              AnalyticsService().recordAdView(ad.id);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdLabel(),
              PostCard(post: post, isSingleView: false),
              _buildFooter(),
            ],
          ),
        );
      });
    }

    return VisibilityDetector(
      key: Key('ad_std_${ad.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          AnalyticsService().recordAdView(ad.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildContent(),
            if (ad.image != null) _buildMedia(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
             'sponsored_post'.tr,
             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.advertiserName ?? 'sponsored'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  'sponsored'.tr,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
            onPressed: () => _showReportDialog(context),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String selectedReason = 'spam';
    final detailsController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'report_advertisement'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'why_report_ad'.tr,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem(value: 'spam', child: Text('spam_or_unsolicited'.tr)),
                    DropdownMenuItem(value: 'fraud', child: Text('scam_or_fraudulent'.tr)),
                    DropdownMenuItem(value: 'misleading', child: Text('misleading_false_claims'.tr)),
                    DropdownMenuItem(value: 'inappropriate', child: Text('inappropriate_offensive'.tr)),
                    DropdownMenuItem(value: 'other', child: Text('other_issue'.tr)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'additional_details_optional'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await MarketplaceService().reportAd(
                          ad.id,
                          selectedReason,
                          details: detailsController.text.trim().isNotEmpty
                              ? detailsController.text.trim()
                              : null,
                        );
                        Get.back();
                        Get.snackbar(
                          'report_submitted'.tr,
                          'ad_flagged_moderation'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (e) {
                        Get.back();
                        Get.snackbar(
                          'notice'.tr,
                          'report_submitted'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('submit_report'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ad.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ad.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (ad.adType == 'slider' || ad.media.length > 1) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: CarouselSlider(
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            enableInfiniteScroll: ad.media.length > 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
          ),
          items: ad.media.map((m) {
            return Builder(
              builder: (BuildContext context) {
                return CustomNetworkImage(
                  imageUrl: m.fileUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            );
          }).toList(),
        ),
      );
    }

    final isVideo = ad.adType == 'video' || (ad.media.isNotEmpty && ad.media.first.type == 'video');
    if (isVideo) {
      final videoUrl = ad.media.isNotEmpty ? ad.media.first.fileUrl : ad.link;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          height: 250,
          width: double.infinity,
          child: VideoPlayerWidget(videoUrl: videoUrl),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      height: 250,
      child: CustomNetworkImage(
        imageUrl: ad.media.isNotEmpty ? ad.media.first.fileUrl : ad.image,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFooter() {
    String? host;
    try {
      if (ad.link != null) {
        host = Uri.parse(ad.link!).host;
      }
    } catch (e) {
      Get.log('Error parsing ad link: $e');
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (host != null)
            Expanded(
              child: Text(
                host,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              AnalyticsService().recordAdClick(ad.id);
              if (ad.adType == 'post' && ad.postId != null) {
                Get.to(() => SinglePostPage(postId: ad.postId!));
              } else if (ad.link != null) {
                final url = Uri.parse(ad.link!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            ),
            child: Text(
              ad.cta ?? 'learn_more'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
