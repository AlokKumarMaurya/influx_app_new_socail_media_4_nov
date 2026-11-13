import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../controllers/friends_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/professional_badge.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../data/models/friend_request_model.dart';
import '../../data/models/user_model.dart';
import 'profile_page.dart';

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FriendsController controller = Get.put(FriendsController());

    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('friends'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navigation Quick Links
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _buildQuickAction(
                      'requests'.tr,
                      controller.selectedTab.value == 'Requests',
                      () => controller.changeTab('Requests'),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      'suggestions'.tr,
                      controller.selectedTab.value == 'Suggestions',
                      () => controller.changeTab('Suggestions'),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickAction(
                      'your_friends'.tr,
                      controller.selectedTab.value == 'Your Friends',
                      () => controller.changeTab('Your Friends'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Friend Requests Section
              // Content Sections based on Selected Tab
              if (controller.selectedTab.value == 'Requests')
                _buildRequestsSection(controller)
              else if (controller.selectedTab.value == 'Suggestions')
                _buildSuggestionsSection(controller)
              else
                _buildFriendsSection(controller),
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildQuickAction(String label, bool isSelected, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : (AppColors.isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textMain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsSection(FriendsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('friend_requests'.tr, style: AppTextStyles.h3),
              Obx(
                () => Text(
                  '${controller.requests.length}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        if (controller.isLoadingRequests.value && controller.requests.isEmpty)
          _buildSkeletonList()
        else if (controller.requests.isEmpty)
          _buildEmptyState('no_pending_requests'.tr, Icons.person_add_disabled)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.requests.length,
            itemBuilder: (context, index) {
              final request = controller.requests[index];
              return _buildRequestItem(request, controller);
            },
          ),
      ],
    );
  }

  Widget _buildSuggestionsSection(FriendsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text('people_you_may_know'.tr, style: AppTextStyles.h3),
        ),
        if (controller.isLoadingSuggestions.value &&
            controller.suggestions.isEmpty)
          _buildSkeletonList()
        else if (controller.suggestions.isEmpty)
          _buildEmptyState('no_suggestions_available'.tr, Icons.people_outline)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.suggestions.length,
            itemBuilder: (context, index) {
              final user = controller.suggestions[index];
              return _buildSuggestionItem(user, controller);
            },
          ),
      ],
    );
  }

  Widget _buildFriendsSection(FriendsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('your_friends'.tr, style: AppTextStyles.h3),
              Obx(
                () => Text(
                  '${controller.friends.length}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        if (controller.isLoadingFriends.value && controller.friends.isEmpty)
          _buildSkeletonList()
        else if (controller.friends.isEmpty)
          _buildEmptyState('no_friends_yet'.tr, Icons.person_off)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.filteredFriends.length,
            itemBuilder: (context, index) {
              final user = controller.filteredFriends[index];
              return _buildFriendItem(user, controller);
            },
          ),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonLoader(width: 72, height: 72, shape: BoxShape.circle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: Get.width * 0.4,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: Get.width * 0.2,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(
    FriendRequestModel request,
    FriendsController controller,
  ) {
    return ListTile(
      onTap: () => Get.to(() => ProfilePage(userId: request.senderId)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: CustomAvatar(avatarUrl: request.senderAvatar, radius: 28),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    request.senderName,
                    style: AppTextStyles.h4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (request.senderProfileType != null &&
                    request.senderProfileType != 'user') ...[
                  const SizedBox(width: 4),
                  ProfessionalBadge(
                    profileType: request.senderProfileType,
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
          Text(request.timeAgo, style: AppTextStyles.bodySmall),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (request.type == 'group_join_request')
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '${'wants_to_join'.tr} ${request.groupName}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.acceptRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('confirm'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.rejectRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Get.isDarkMode
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      foregroundColor: AppColors.textMain,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('delete'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(UserModel user, FriendsController controller) {
    return ListTile(
      onTap: () => Get.to(() => ProfilePage(userId: user.id)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: CustomAvatar(avatarUrl: user.avatar, radius: 28),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.name,
              style: AppTextStyles.h4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.profileType != null && user.profileType != 'user') ...[
            const SizedBox(width: 4),
            ProfessionalBadge(profileType: user.profileType, size: 14),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => controller.sendRequest(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('add_friend'.tr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => controller.suggestions.remove(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  foregroundColor: AppColors.textMain,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('remove'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendItem(UserModel user, FriendsController controller) {
    return ListTile(
      onTap: () => Get.to(() => ProfilePage(userId: user.id)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CustomAvatar(avatarUrl: user.avatar, radius: 24),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.name,
              style: AppTextStyles.h4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.profileType != null && user.profileType != 'user') ...[
            const SizedBox(width: 4),
            ProfessionalBadge(profileType: user.profileType, size: 14),
          ],
        ],
      ),
      subtitle: user.username != null ? Text('@${user.username}') : null,
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () => _showFriendActionSheet(user, controller),
      ),
    );
  }

  void _showFriendActionSheet(UserModel user, FriendsController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: Text(
                '${'unfriend'.tr} ${user.name}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Get.back();
                controller.unfriend(user);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
