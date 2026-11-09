import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/extra_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../../widgets/common/professional_badge.dart';
import '../user/profile_page.dart';

class CommonThingsPage extends StatefulWidget {
  const CommonThingsPage({super.key});

  @override
  State<CommonThingsPage> createState() => _CommonThingsPageState();
}

class _CommonThingsPageState extends State<CommonThingsPage> {
  final ExtraController controller = Get.put(ExtraController());

  @override
  void initState() {
    super.initState();
    controller.fetchCommonUsers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('common_things'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.commonLoading.value && controller.commonUsers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.commonUsers.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchCommonUsers(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                controller.fetchCommonUsers();
              }
              return true;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: controller.hasMoreCommon.value 
                  ? controller.commonUsers.length + 1 
                  : controller.commonUsers.length,
              itemBuilder: (context, index) {
                if (index == controller.commonUsers.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = controller.commonUsers[index];
                return _buildUserCard(user);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUserCard(dynamic user) {
    return GestureDetector(
      onTap: () => Get.to(() => ProfilePage(userId: user.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: user.avatar != null && user.avatar.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: UrlUtils.getFullUrl(user.avatar),
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 40),
                        )
                      : const Icon(Icons.person, size: 40),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.profileType != 'user') ...[
                          const SizedBox(width: 4),
                          ProfessionalBadge(profileType: user.profileType, size: 12),
                        ],
                      ],
                    ),
                    Text(
                      '${user.mutualFriendsCount} ${'mutual_friends'.tr}',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => controller.sendFriendRequest(user.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: Text(
                          'add_friend'.tr,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserGroup,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            size: 80,
          ),
          const SizedBox(height: 24),
          Text('no_suggestions_found'.tr, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Text(
            'no_common_connections_found'.tr,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
