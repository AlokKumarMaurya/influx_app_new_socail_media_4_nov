import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../controllers/groups_controller.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/feed/ad_card.dart';
import '../../data/models/feed_item.dart';
import '../../data/models/group_model.dart';
import './group_details_page.dart';
import './create_group_page.dart';
import './my_groups_page.dart';
import './suggested_groups_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late GroupsController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(GroupsController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      body: controller.isLoading.value
          ? _buildShimmerLoading()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: controller.refresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('groups'.tr, style: AppTextStyles.h2),
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),

                  // 2. Buttons Row
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildPillButton('your_groups'.tr, HugeIcons.strokeRoundedUserGroup, () {
                            Get.to(() => const MyGroupsPage());
                          }),
                          const SizedBox(width: 8),
                          _buildPillButton('discover'.tr, HugeIcons.strokeRoundedCompass01, () {
                            Get.to(() => const SuggestedGroupsPage());
                          }),
                          const SizedBox(width: 8),
                          _buildPillButton('create'.tr, HugeIcons.strokeRoundedAdd01, () async {
                            final result = await Get.to(() => const CreateGroupPage());
                            if (result == true) {
                              controller.refresh();
                            }
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: Divider(height: 1, thickness: 1)),

                  // 3. My Groups Horizontal List
                  if (controller.myGroups.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader('your_groups'.tr, () {}),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: controller.myGroups.length,
                          itemBuilder: (context, index) {
                            return _buildMyGroupItem(controller.myGroups[index]);
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],

                  // 4. Suggested Groups
                  if (controller.suggestedGroups.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader('suggested_for_you'.tr, () {}),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: controller.suggestedGroups.length,
                          itemBuilder: (context, index) {
                            return _buildSuggestedGroupCard(controller.suggestedGroups[index]);
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],

                  SliverToBoxAdapter(child: Divider(height: 8, thickness: 8, color: AppColors.background)),

                  // 5. Recent Activity Feed
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text('recent_activity'.tr, style: AppTextStyles.h3),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < controller.feedItems.length) {
                          final item = controller.feedItems[index];
                          if (item.type == FeedItemType.post) {
                            return PostCard(post: item.post!);
                          } else if (item.type == FeedItemType.ad) {
                            return AdCard(ad: item.ad!);
                          }
                        } else if (controller.isLoadingMore.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          );
                        }
                        return null;
                      },
                      childCount: controller.feedItems.length + (controller.isLoadingMore.value ? 1 : 0),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    ));
  }


  Widget _buildPillButton(String label, dynamic icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: AppColors.textMain, size: 18),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h3),
          TextButton(
            onPressed: onSeeAll,
            child: Text('see_all'.tr, style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMyGroupItem(GroupModel group) {
    return InkWell(
      onTap: () => Get.to(() => GroupDetailsPage(groupId: group.id)),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(group.avatar ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                group.name,
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedGroupCard(GroupModel group) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Get.isDarkMode ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: CachedNetworkImage(
              imageUrl: group.coverPhoto ?? '',
              height: 70,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[300]),
              errorWidget: (context, url, error) => Container(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              group.name,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            '${group.memberCount} ${'members'.tr}',
            style: AppTextStyles.bodySmall,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () => Get.to(() => GroupDetailsPage(groupId: group.id)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('join'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(5, (index) => _buildShimmerItem()),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerBox(44, 44, isCircle: true),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_shimmerBox(140, 12), const SizedBox(height: 6), _shimmerBox(90, 10)],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _shimmerBox(double.infinity, 14),
          const SizedBox(height: 8),
          _shimmerBox(double.infinity * 0.7, 14),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {bool isCircle = false, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}
