import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/extra_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/feed/post_card.dart';

class HiddenPostsPage extends StatefulWidget {
  const HiddenPostsPage({super.key});

  @override
  State<HiddenPostsPage> createState() => _HiddenPostsPageState();
}

class _HiddenPostsPageState extends State<HiddenPostsPage> {
  final ExtraController controller = Get.put(ExtraController());

  @override
  void initState() {
    super.initState();
    controller.fetchHiddenPosts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('hidden_posts'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.hiddenPostsLoading.value && controller.hiddenPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hiddenPosts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchHiddenPosts(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                controller.fetchHiddenPosts();
              }
              return true;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: controller.hiddenPosts.length + (controller.hasMoreHiddenPosts.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.hiddenPosts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final post = controller.hiddenPosts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      PostCard(post: post),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: () => controller.unhidePost(post.id),
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedView, color: AppColors.primary, size: 18),
                          label: Text('unhide_post'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedViewOffSlash,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text('no_hidden_posts'.tr, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'posts_you_hide_appear_here'.tr,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
