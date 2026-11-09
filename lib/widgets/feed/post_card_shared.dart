import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../pages/feed/single_post_page.dart';
import '../../pages/user/profile_page.dart';
import '../common/custom_avatar.dart';
import '../common/professional_badge.dart';
import './post_card_media.dart';
import './post_card_content.dart';

class PostCardShared extends StatelessWidget {
  final PostModel shared;
  final int depth;

  const PostCardShared({
    super.key,
    required this.shared,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (depth > 2) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(depth == 0 ? 16 : 0, 8, depth == 0 ? 16 : 0, 4),
      padding: EdgeInsets.all(depth == 0 ? 12 : 8),
      decoration: BoxDecoration(
        color: depth > 0 ? AppColors.background.withAlpha(128) : null,
        border: Border.all(color: AppColors.textMain.withAlpha(25)),
        borderRadius: BorderRadius.circular(depth == 0 ? 16 : 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SharedHeader(shared: shared),
          PostCardContent(
            post: shared,
            isSingleView: false,
            isSharedNested: true,
          ),
          PostCardMedia(post: shared, isShared: true),
          if (shared.sharedPost != null)
            PostCardShared(shared: shared.sharedPost!, depth: depth + 1),
        ],
      ),
    );
  }
}

class _SharedHeader extends StatelessWidget {
  final PostModel shared;

  const _SharedHeader({required this.shared});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => shared.user != null ? Get.to(() => ProfilePage(userId: shared.user!.id)) : null,
          child: CustomAvatar(user: shared.user, radius: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => Get.to(() => SinglePostPage(postId: shared.id, initialPost: shared)),
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => shared.user != null ? Get.to(() => ProfilePage(userId: shared.user!.id)) : null,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          shared.user?.name ?? 'User',
                          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shared.user?.profileType != null && shared.user?.profileType != 'user') ...[
                        const SizedBox(width: 4),
                        ProfessionalBadge(profileType: shared.user!.profileType, size: 12),
                      ],
                    ],
                  ),
                ),
                Text(
                  shared.createdAt ?? 'Shared post',
                  style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary.withAlpha(128)),
      ],
    );
  }
}
