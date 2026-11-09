import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/extra_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/feed/post_card.dart';

class MemoriesPage extends StatefulWidget {
  const MemoriesPage({super.key});

  @override
  State<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage> {
  final ExtraController controller = Get.put(ExtraController());

  @override
  void initState() {
    super.initState();
    controller.fetchMemories(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('memories'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.memoriesLoading.value && controller.memories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.memories.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchMemories(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                controller.fetchMemories();
              }
              return true;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: controller.hasMoreMemories.value 
                  ? controller.memories.length + 1 
                  : controller.memories.length,
              itemBuilder: (context, index) {
                if (index == controller.memories.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final post = controller.memories[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                           color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getYearsAgoText(post.createdAt ?? ''),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    PostCard(post: post),
                    const SizedBox(height: 16),
                  ],
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_memories_today'.tr,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'memories_empty_desc'.tr,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getYearsAgoText(String createdAt) {
    return 'from_this_day_in_previous_years'.tr;
  }
}
