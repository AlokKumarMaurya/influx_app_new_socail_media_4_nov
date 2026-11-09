import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../pages/feed/reactions_page.dart';

class PostCardStats extends StatelessWidget {
  final PostModel post;

  const PostCardStats({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.to(() => ReactionsPage(postId: post.id, summary: post.reactionSummary)),
            child: Row(
              children: [
                ..._buildTopReactionIcons(),
                if (post.reactionsCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${post.reactionsCount}',
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              if (post.commentsCount > 0)
                Text('${post.commentsCount} ${'comments'.tr}',
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 12)),
              if (post.sharesCount > 0) ...[
                const SizedBox(width: 10),
                Text('${post.sharesCount} ${'shares'.tr}',
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopReactionIcons() {
    final summary = post.reactionSummary;
    if (summary.isEmpty) return [];

    const emojiMap = {
      'like': '👍', 'love': '❤️', 'haha': '😂', 'care': '🥰', 'wow': '😮', 'sad': '😢', 'angry': '😡',
    };
    const colorMap = {
      'like': Color(0xFF548dff), 'love': Color(0xFFf55064), 'haha': Color(0xFFffda6a),
      'care': Color(0xFFffda6a), 'wow': Color(0xFF38bdf8), 'sad': Color(0xFF548dff), 'angry': Color(0xFFd5234c),
    };

    final sorted = summary.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3);

    return top.toList().asMap().entries.map((entry) {
      final type = entry.value.key;
      return Container(
        transform: Matrix4.translationValues(entry.key > 0 ? -entry.key * 6.0 : 0, 0, 0),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: colorMap[type] ?? AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBg, width: 1.5),
          ),
          child: Center(child: Text(emojiMap[type] ?? '👍', style: const TextStyle(fontSize: 12))),
        ),
      );
    }).toList();
  }
}
