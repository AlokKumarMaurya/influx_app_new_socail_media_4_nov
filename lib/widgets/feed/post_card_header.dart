import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../config/app_config.dart';
import '../../utils/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../pages/feed/single_post_page.dart';
import '../../pages/feed/create_post_page.dart';
import '../../pages/feed/group_details_page.dart';
import '../../pages/user/profile_page.dart';
import '../../pages/fan_page/fan_page_profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../common/custom_avatar.dart';
import '../common/professional_badge.dart';
import 'report_post_bottom_sheet.dart';

class PostCardHeader extends StatelessWidget {
  final PostModel post;
  final bool isSingleView;

  const PostCardHeader({
    super.key,
    required this.post,
    required this.isSingleView,
  });

  @override
  Widget build(BuildContext context) {
    final fanPage = post.fanPage;
    final isPagePost = fanPage != null;
    final user = post.user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
      child: GestureDetector(
        onTap: () {
          if (!isSingleView) {
            Get.to(() => SinglePostPage(postId: post.id, initialPost: post));
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            if (isPagePost)
              GestureDetector(
                onTap: () => Get.to(() => FanPageProfilePage(slug: fanPage.slug, initialPage: fanPage)),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (fanPage.avatar != null && fanPage.avatar!.isNotEmpty)
                      ? CachedNetworkImageProvider(fanPage.avatar!)
                      : null,
                  child: (fanPage.avatar == null || fanPage.avatar!.isEmpty)
                      ? const Icon(Icons.flag, size: 20, color: Colors.grey)
                      : null,
                ),
              )
            else
              GestureDetector(
                onTap: () => user != null ? Get.to(() => ProfilePage(userId: user.id)) : null,
                child: CustomAvatar(user: user, radius: 20),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPagePost) ...[
                        Flexible(
                          child: GestureDetector(
                            onTap: () => Get.to(() => FanPageProfilePage(slug: fanPage.slug, initialPage: fanPage)),
                            child: Text(
                              fanPage.name,
                              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (fanPage.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: Colors.blue),
                        ],
                        if (fanPage.category != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              fanPage.category!.name,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ] else ...[
                        Flexible(
                          child: GestureDetector(
                            onTap: () => user != null ? Get.to(() => ProfilePage(userId: user.id)) : null,
                            child: Text(
                              user?.name ?? 'User',
                              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        ProfessionalBadge(
                          profileType: user?.profileType,
                          badgeIconUrl: user?.badgeIconUrl,
                          customBadgeIconUrl: user?.customBadgeIconUrl,
                          isBadgePrivate: user?.isBadgePrivate ?? false,
                          size: 14,
                        ),
                      ],
                      if (post.tags.isNotEmpty) ...[
                        Text(
                          ' ${'with'.tr} ',
                          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Flexible(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final taggedUser = post.tags[0];
                              Get.to(() => ProfilePage(userId: taggedUser.id));
                            },
                            child: Text(
                              post.tags.length == 1
                                  ? post.tags[0].name
                                  : '${post.tags[0].name} ${'and'.tr} ${post.tags.length - 1} ${'others'.tr}',
                              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMain, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      if (post.groupName != null) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (post.groupId != null) {
                                Get.to(() => GroupDetailsPage(groupId: post.groupId!));
                              }
                            },
                            child: Text(
                              post.groupName ?? 'Group',
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        post.createdAt ?? 'just_now'.tr,
                        style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text('·', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(width: 4),
                      Icon(
                        post.privacy == 'friends'
                            ? Icons.people_outline
                            : post.privacy == 'only_me'
                                ? Icons.lock_outline
                                : Icons.public,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      if (post.feelingAction != null && post.feelingValue != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${post.feelingAction} ${post.feelingValue}',
                          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                      if (post.location != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            post.location ?? '',
                            style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _PostMoreMenu(post: post),
          ],
        ),
      ),
    );
  }
}

class _PostMoreMenu extends StatelessWidget {
  final PostModel post;

  const _PostMoreMenu({required this.post});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isOwner = post.userId == authController.user.value?.id;

    return PopupMenuButton<String>(
      icon: HugeIcon(icon: HugeIcons.strokeRoundedMoreHorizontal, color: AppColors.textSecondary, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardBg,
      onSelected: (value) {
        final feedController = Get.find<FeedController>();
        switch (value) {
          case 'save_post':
          case 'unsave_post':
            feedController.toggleSave(post.id);
            break;
          case 'edit_post':
            Get.to(() => CreatePostPage(editPost: post));
            break;
          case 'delete_post':
            _showDeleteConfirm(post.id);
            break;
          case 'hide_post':
            feedController.hidePost(post.id);
            break;
          case 'report_post':
            _showReportSheet(context, post.id);
            break;
          case 'copy_link':
            final webBaseUrl = AppConfig.baseUrl.replaceAll('/api', '');
            final postUrl = '$webBaseUrl/posts/${post.id}';
            Clipboard.setData(ClipboardData(text: postUrl));
            Get.snackbar(
              'link_copied'.tr,
              'post_link_copied_clipboard'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        _menuItem(post.isSaved ? Icons.bookmark : Icons.bookmark_border, post.isSaved ? 'unsave_post'.tr : 'save_post'.tr, valueKey: post.isSaved ? 'unsave_post' : 'save_post'),
        if (isOwner) ...[
          _menuItem(Icons.edit_outlined, 'edit_post'.tr, valueKey: 'edit_post'),
          _menuItem(Icons.delete_outline, 'delete_post'.tr, valueKey: 'delete_post', isDestructive: true),
        ],
        _menuItem(Icons.visibility_off_outlined, 'hide_post'.tr, valueKey: 'hide_post'),
        _menuItem(Icons.copy, 'copy_link'.tr, valueKey: 'copy_link'),
        const PopupMenuDivider(),
        _menuItem(Icons.warning_amber_rounded, 'report_post'.tr, valueKey: 'report_post', isDestructive: true),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(IconData icon, String label, {required String valueKey, bool isDestructive = false}) {
    return PopupMenuItem(
      value: valueKey,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? Colors.red : AppColors.textMain),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: isDestructive ? Colors.red : AppColors.textMain, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showDeleteConfirm(int postId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('delete_post'.tr),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text('delete_post_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              Get.find<FeedController>().deletePost(postId);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context, int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportPostBottomSheet(postId: postId),
    );
  }
}
