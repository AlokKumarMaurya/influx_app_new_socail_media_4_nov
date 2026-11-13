import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../pages/blog/blogs_page.dart';
import '../../pages/threads/threads_feed_page.dart';
import '../../utils/url_utils.dart';
import '../../utils/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../pages/feed/create_post_page.dart';
import '../../pages/live/go_live_setup_page.dart';

class CreatePostCard extends StatelessWidget {
  const CreatePostCard({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      // Ensure reactivity by accessing the observable theme state
      AppColors.isDark;
      final user = authController.user.value;

      return GestureDetector(
        onTap: () => Get.to(() => const CreatePostPage()),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
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
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        user?.avatar != null && user!.avatar!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            UrlUtils.getFullUrl(user.avatar!),
                          )
                        : null,
                    child: user?.avatar == null || user!.avatar!.isEmpty
                        ? Icon(Icons.person, color: AppColors.primary, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'whats_on_your_mind'.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.textMain.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        HugeIcons.strokeRoundedVideo02,
                        'Go Live',
                        const Color(0xFFEF4444),
                        onTap: () => Get.to(() => const GoLiveSetupPage()),
                      ),
                      _buildQuickAction(
                        HugeIcons.strokeRoundedAlignLeft,
                        'Thread',
                        const Color(0xFF1E3FE8),
                        onTap: () => Get.to(() => const ThreadsFeedPage()),
                      ),
                      _buildQuickAction(
                        HugeIcons.strokeRoundedNews,
                        'Blog',
                        const Color(0xFFF30668),
                        onTap: () => Get.to(() => const BlogsPage()),
                      ),
                      _buildQuickAction(
                        HugeIcons.strokeRoundedImage01,
                        'photo_video'.tr,
                        const Color(0xFF22C55E),
                        onTap: () => Get.to(() => const CreatePostPage()),
                      ),
                      _buildQuickAction(
                        HugeIcons.strokeRoundedPaintBoard,
                        'color_post'.tr,
                        const Color(0xFF9333EA),
                        onTap: () => Get.to(
                          () => const CreatePostPage(isColorPost: true),
                        ),
                      ),
                      _buildQuickAction(
                        HugeIcons.strokeRoundedSmileDizzy,
                        'feeling'.tr,
                        const Color(0xFFF59E0B),
                        onTap: () => Get.to(() => const CreatePostPage()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuickAction(
    dynamic icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () => Get.to(() => const CreatePostPage()),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
