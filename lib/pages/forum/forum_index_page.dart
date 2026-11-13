import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/forum_controller.dart';
import '../../data/models/forum_model.dart';
import '../../utils/app_theme.dart';
import 'forum_topic_detail_page.dart';
import 'forum_create_topic_page.dart';

class ForumIndexPage extends StatelessWidget {
  const ForumIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForumController());

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('community_forum'.tr, style: AppTextStyles.h3),
            Text('ask_questions_share_knowledge'.tr, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.primary, size: 24),
            onPressed: () => Get.to(() => const ForumCreateTopicPage()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.to(() => const ForumCreateTopicPage()),
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white, size: 20),
        label: Text('new_topic'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadForumFeed(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner & Search
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'join_community_discussions'.tr,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'forum_header_subtitle'.tr,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      // Search TextField Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          onSubmitted: (val) => controller.searchTopics(val),
                          onChanged: (val) {
                            if (val.isEmpty) {
                              controller.clearSearch();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'search_forum_discussions'.tr,
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.primary, size: 20),
                            ),
                            suffixIcon: controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                    onPressed: () => controller.clearSearch(),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Categories Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('categories'.tr, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    if (controller.selectedCategoryId.value != null)
                      TextButton(
                        onPressed: () => controller.filterByCategory(null),
                        child: Text('show_all'.tr, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final cat = controller.categories[index];
                      final isSelected = controller.selectedCategoryId.value == cat.id;
                      return InkWell(
                        onTap: () {
                          if (isSelected) {
                            controller.filterByCategory(null);
                          } else {
                            controller.filterByCategory(cat.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.15),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const HugeIcon(icon: HugeIcons.strokeRoundedBubbleChatDelay, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(height: 8),
                              Text(cat.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${cat.topicsCount} ${'topics'.tr}', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Subcategory Filter Chips (If Category Selected)
                if (controller.selectedCategoryId.value != null) ...[
                  const SizedBox(height: 14),
                  Builder(builder: (context) {
                    final selectedCat = controller.categories.firstWhereOrNull((c) => c.id == controller.selectedCategoryId.value);
                    if (selectedCat == null || selectedCat.subcategories.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedCat.subcategories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            final isAll = controller.selectedSubcategoryId.value == null;
                            return ChoiceChip(
                              label: Text('all_subcategories'.tr, style: const TextStyle(fontSize: 12)),
                              selected: isAll,
                              selectedColor: AppColors.primary.withOpacity(0.15),
                              onSelected: (_) => controller.filterByCategory(selectedCat.id, subcategoryId: null),
                            );
                          }
                          final sub = selectedCat.subcategories[index - 1];
                          final isSubSelected = controller.selectedSubcategoryId.value == sub.id;
                          return ChoiceChip(
                            label: Text('↳ ${sub.name}', style: const TextStyle(fontSize: 12)),
                            selected: isSubSelected,
                            selectedColor: AppColors.primary.withOpacity(0.15),
                            onSelected: (_) => controller.filterByCategory(selectedCat.id, subcategoryId: sub.id),
                          );
                        },
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),

                // Recent Topics Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('recent_discussions'.tr, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    Text('${controller.recentTopics.length} ${'topics'.tr}', style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),

                if (controller.recentTopics.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedBubbleChatDelay, color: Colors.grey, size: 48),
                          const SizedBox(height: 12),
                          Text('no_discussions_found_section'.tr, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.recentTopics.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final topic = controller.recentTopics[index];
                      return _buildTopicCard(context, topic);
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopicCard(BuildContext context, ForumTopicModel topic) {
    return InkWell(
      onTap: () => Get.to(() => ForumTopicDetailPage(slug: topic.slug)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (topic.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      topic.category!.name,
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (topic.subcategory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '↳ ${topic.subcategory!.name}',
                      style: TextStyle(color: Colors.grey[800], fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (topic.isSolved)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'solved'.tr,
                      style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(topic.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: topic.authorAvatar != null ? NetworkImage(topic.authorAvatar!) : null,
                  child: topic.authorAvatar == null ? const Icon(Icons.person, size: 12) : null,
                ),
                const SizedBox(width: 6),
                Text(topic.authorName ?? 'user'.tr, style: AppTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                const HugeIcon(icon: HugeIcons.strokeRoundedEye, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text('${topic.viewsCount}', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                const SizedBox(width: 12),
                const HugeIcon(icon: HugeIcons.strokeRoundedComment01, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text('${topic.repliesCount}', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
