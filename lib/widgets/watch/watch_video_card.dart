import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../data/models/watch_video_model.dart';
import '../../data/models/comment_model.dart';
import '../../controllers/watch_controller.dart';
import '../../controllers/feed_controller.dart' as feed;
import '../common/video_player_widget.dart';
import '../common/custom_avatar.dart';
import '../common/professional_badge.dart';
import '../feed/reaction_picker.dart';
import '../../pages/feed/reactions_page.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../controllers/auth_controller.dart';
import '../../pages/user/profile_page.dart';
import '../../pages/fan_page/fan_page_profile_page.dart';
import '../../pages/feed/search_page.dart';
import 'package:url_launcher/url_launcher.dart';

class WatchVideoCard extends StatefulWidget {
  final WatchVideoModel video;
  const WatchVideoCard({super.key, required this.video});

  @override
  State<WatchVideoCard> createState() => _WatchVideoCardState();
}

class _WatchVideoCardState extends State<WatchVideoCard> {
  bool _showComments = false;
  final TextEditingController _commentController = TextEditingController();

  WatchController get controller => Get.find<WatchController>();
  OverlayEntry? _reactionOverlay;

  @override
  void dispose() {
    _commentController.dispose();
    _reactionOverlay?.remove();
    super.dispose();
  }

  void _showReactionPopup() {
    if (_reactionOverlay != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _reactionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideReactionPopup,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dx + 20,
            top: position.dy + (renderBox.size.height - 180), // Adjust based on button position
            child: Material(
              color: Colors.transparent,
              child: ReactionPicker(
                onReactionSelected: (type) {
                  controller.toggleReaction(widget.video.post.id, type);
                  _hideReactionPopup();
                },
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reactionOverlay!);
  }

  void _hideReactionPopup() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
  }
  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final post = video.post;
    final user = post.user;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user, post),
          if (post.content != null && post.content!.isNotEmpty) _buildCaption(post.content!),
          _buildVideoPlayer(video),
          _buildStatsBar(video, post),
          _buildActionBar(post),
          if (_showComments) _buildCommentsSection(post),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────
  Widget _buildHeader(UserModel? user, PostModel post) {
    final fanPage = post.fanPage;
    final isPagePost = fanPage != null;
    final rawAvatar = isPagePost ? fanPage.avatar : user?.avatar;
    final avatarUrl = (rawAvatar != null && rawAvatar.isNotEmpty)
        ? UrlUtils.getFullUrl(rawAvatar)
        : '';
    final displayName = isPagePost ? fanPage.name : (user?.name ?? 'User');
    final timeAgo = post.createdAt ?? '';
    final privacy = post.privacy;

    IconData privacyIcon = Icons.public;
    if (privacy == 'friends') privacyIcon = Icons.people;
    if (privacy == 'only_me') privacyIcon = Icons.lock;

    void navigateToAuthor() {
      if (isPagePost) {
        Get.to(() => FanPageProfilePage(slug: fanPage.slug, initialPage: fanPage));
      } else if (user != null) {
        Get.to(() => ProfilePage(userId: user.id));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: navigateToAuthor,
            child: CircleAvatar(
              radius: 22,
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Icon(isPagePost ? Icons.flag : Icons.person, size: 22)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: navigateToAuthor,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPagePost) ...[
                        if (fanPage.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 15, color: Colors.blue),
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
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ] else if (user?.profileType != null) ...[
                        ProfessionalBadge(profileType: user!.profileType, size: 14),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text('·', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    Icon(privacyIcon, size: 12, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
            onSelected: (value) {
              if (value == 'save') {
                controller.toggleSave(post.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'save', child: Row(children: [const Icon(Icons.bookmark_border, size: 18), const SizedBox(width: 8), Text('save_video'.tr)])),
              PopupMenuItem(value: 'report', child: Row(children: [const Icon(Icons.flag_outlined, size: 18, color: Colors.red), const SizedBox(width: 8), Text('report_video'.tr, style: const TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }

  // ─── CAPTION ──────────────────
  Widget _buildCaption(String content) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: HtmlWidget(
        content,
        textStyle: const TextStyle(fontSize: 14, height: 1.4),
        onTapUrl: (url) async {
          final cleanUrl = url.trim();
          if (cleanUrl.startsWith('mention://')) {
            final username = cleanUrl.replaceFirst('mention://', '').trim();
            if (username.isNotEmpty) {
              final asId = int.tryParse(username);
              if (asId != null) {
                Get.to(() => ProfilePage(userId: asId));
              } else {
                Get.to(() => ProfilePage(username: username));
              }
            }
            return true;
          }
          if (cleanUrl.startsWith('hashtag://')) {
            final tag = cleanUrl.replaceFirst('hashtag://', '');
            final query = tag.startsWith('#') ? tag : '#$tag';
            Get.to(() => SearchPage(initialQuery: query));
            return true;
          }
          if (cleanUrl.contains('/search') && cleanUrl.contains('q=')) {
            final uri = Uri.tryParse(cleanUrl);
            String tag = uri?.queryParameters['q'] ?? '';
            if (tag.isNotEmpty) {
              if (!tag.startsWith('#')) tag = '#$tag';
              Get.to(() => SearchPage(initialQuery: tag));
              return true;
            }
          }
          final uri = Uri.tryParse(cleanUrl);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return true;
          }
          return false;
        },
      ),
    );
  }

  // ─── VIDEO PLAYER ──────────────────
  Widget _buildVideoPlayer(WatchVideoModel video) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 250, maxHeight: 500),
      color: Colors.black,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 300,
            child: VideoPlayerWidget(
              videoUrl: video.videoUrl,
              mediaId: video.mediaId,
              autoPlay: true,
              looping: true,
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${video.viewsCount} ${'views'.tr}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS BAR ──────────────────
  Widget _buildStatsBar(WatchVideoModel video, PostModel post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reaction emojis + count
              GestureDetector(
                onTap: () => Get.to(() => ReactionsPage(
                      postId: post.id,
                      summary: post.reactionSummary,
                    )),
                child: Row(
                  children: [
                    ..._buildTopReactionIcons(post),
                    if (post.reactionsCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${post.reactionsCount}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              // Comments + shares
              if (post.commentsCount > 0 || post.sharesCount > 0)
                Row(
                  children: [
                    if (post.commentsCount > 0)
                      Text('${post.commentsCount} ${'comments'.tr}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (post.sharesCount > 0) ...[
                      const SizedBox(width: 10),
                      Text('${post.sharesCount} ${'shares'.tr}',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${video.viewsCount} ${'views'.tr}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopReactionIcons(PostModel post) {
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
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: colorMap[type] ?? AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBg, width: 1.5),
          ),
          child: Center(child: Text(emojiMap[type] ?? '👍', style: const TextStyle(fontSize: 10))),
        ),
      );
    }).toList();
  }

  // ─── ACTION BAR ──────────────────
  Widget _buildActionBar(PostModel post) {
    final hasReaction = post.userReaction != null;

    const emojiMap = {
      'like': '👍',
      'love': '❤️',
      'haha': '😂',
      'care': '🥰',
      'wow': '😮',
      'sad': '😢',
      'angry': '😡',
    };
    const colorMap = {
      'like': Color(0xFF548dff),
      'love': Color(0xFFf55064),
      'haha': Color(0xFFffda6a),
      'care': Color(0xFFffda6a),
      'wow': Color(0xFF38bdf8),
      'sad': Color(0xFF548dff),
      'angry': Color(0xFFd5234c),
    };

    String reactionLabel = 'like'.tr;
    Color reactionColor = AppColors.textSecondary;

    if (hasReaction) {
      reactionLabel = (post.userReaction ?? 'like').capitalize!;
      reactionColor = colorMap[post.userReaction] ?? AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.textMain.withAlpha(15)),
          bottom: BorderSide(color: AppColors.textMain.withAlpha(15)),
        ),
      ),
      child: Row(
        children: [
          // Like button
          Expanded(
            child: GestureDetector(
              onTap: () => controller.toggleReaction(post.id, hasReaction ? post.userReaction! : 'like'),
              onLongPress: _showReactionPopup,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasReaction)
                      Text(emojiMap[post.userReaction] ?? '👍', style: const TextStyle(fontSize: 18))
                    else
                      HugeIcon(icon: HugeIcons.strokeRoundedThumbsUp, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      reactionLabel,
                      style: TextStyle(
                        color: reactionColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Comment button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _showComments = !_showComments);
                if (_showComments) controller.loadComments(post.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedComment01, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 6),
                    Text('comment'.tr,
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          // Share button
          Expanded(
            child: GestureDetector(
              onTap: () => _showShareDialog(post),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedShare01, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 6),
                    Text('share'.tr,
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARE DIALOG ──────────────────
  void _showShareDialog(PostModel post) {
    final contentController = TextEditingController();
    String privacy = 'public';

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 20),
                    Text('share'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // User Row
                Row(
                  children: [
                    CustomAvatar(user: post.user, radius: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.user?.name ?? 'user'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (privacyCtx) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'select_privacy'.tr,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 12),
                                      ListTile(
                                        leading: const Icon(Icons.public, color: AppColors.primary),
                                        title: Text('public'.tr),
                                        subtitle: Text('anyone_on_or_off_influx'.tr),
                                        trailing: privacy == 'public' ? const Icon(Icons.check, color: AppColors.primary) : null,
                                        onTap: () {
                                          setModalState(() => privacy = 'public');
                                          Navigator.of(privacyCtx).pop();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.group_outlined, color: AppColors.primary),
                                        title: Text('friends'.tr),
                                        subtitle: Text('friends_on_influx'.tr),
                                        trailing: privacy == 'friends' ? const Icon(Icons.check, color: AppColors.primary) : null,
                                        onTap: () {
                                          setModalState(() => privacy = 'friends');
                                          Navigator.of(privacyCtx).pop();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                                        title: Text('only_me'.tr),
                                        subtitle: Text('only_you_can_see_this'.tr),
                                        trailing: privacy == 'only_me' ? const Icon(Icons.check, color: AppColors.primary) : null,
                                        onTap: () {
                                          setModalState(() => privacy = 'only_me');
                                          Navigator.of(privacyCtx).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  privacy == 'friends'
                                      ? Icons.group_outlined
                                      : (privacy == 'only_me' ? Icons.lock_outline : Icons.public),
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  privacy == 'friends' ? 'friends'.tr : (privacy == 'only_me' ? 'only_me'.tr : 'public'.tr),
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Input
                TextField(
                  controller: contentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'say_something_about_this'.tr,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 12),

                // Options List
                _buildShareOption(
                  icon: Icons.share,
                  title: 'share_now_public'.tr,
                  subtitle: 'instantly_sharing_feed'.tr,
                  onTap: () {
                    Get.find<feed.FeedController>().sharePost(post.id, contentController.text, 'public');
                    Get.back();
                  },
                ),
                _buildShareOption(
                  icon: Icons.link,
                  title: 'copy_link'.tr,
                  onTap: () {
                    final siteUrl = UrlUtils.getFullUrl('/').split('/storage/').first;
                    Clipboard.setData(ClipboardData(text: '$siteUrl/posts/${post.id}'));
                    Get.back();
                    Get.snackbar('success'.tr, 'link_copied_clipboard'.tr);
                  },
                ),
                _buildShareOption(
                  icon: Icons.more_horiz,
                  title: 'more_options'.tr,
                  onTap: () {
                    final siteUrl = UrlUtils.getFullUrl('/').split('/storage/').first;
                    Get.back();
                    SharePlus.instance.share(ShareParams(uri: Uri.parse('$siteUrl/posts/${post.id}')));
                  },
                ),

                const SizedBox(height: 20),
                // Main Button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.find<feed.FeedController>().sharePost(post.id, contentController.text, privacy);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('share_on_your_profile'.tr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildShareOption({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textMain, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  // ─── COMMENTS SECTION ──────────────────
  Widget _buildCommentsSection(PostModel post) {
    return Obx(() {
      final comments = controller.postComments[post.id] ?? <CommentModel>[].obs;
      final isLoading = controller.isCommentsLoading[post.id]?.value ?? false;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment Input
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'write_a_comment'.tr,
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_commentController.text.trim().isNotEmpty) {
                        controller.addComment(post.id, _commentController.text.trim());
                        _commentController.clear();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            // Comments List
            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
            else
              ...comments.map((c) => _buildCommentItem(c, post.id)),
          ],
        ),
      );
    });
  }

  Widget _buildCommentItem(CommentModel comment, int postId) {
    final commentUser = comment.user;
    final nameStr = commentUser?.name ?? 'user'.tr;
    final isLiked = comment.userReaction != null;
    final authController = Get.find<AuthController>();
    final isOwnComment = commentUser?.id == authController.user.value?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => commentUser != null ? Get.to(() => ProfilePage(userId: commentUser.id)) : null,
            child: CustomAvatar(user: commentUser, radius: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => commentUser != null ? Get.to(() => ProfilePage(userId: commentUser.id)) : null,
                        child: Row(
                          children: [
                            Text(nameStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            if (commentUser?.profileType != null) ProfessionalBadge(profileType: commentUser!.profileType, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      HtmlWidget(
                        comment.content ?? '',
                        textStyle: const TextStyle(fontSize: 13),
                        onTapUrl: (url) async {
                          final cleanUrl = url.trim();
                          if (cleanUrl.startsWith('mention://')) {
                            final username = cleanUrl.replaceFirst('mention://', '').trim();
                            if (username.isNotEmpty) {
                              final asId = int.tryParse(username);
                              if (asId != null) {
                                Get.to(() => ProfilePage(userId: asId));
                              } else {
                                Get.to(() => ProfilePage(username: username));
                              }
                            }
                            return true;
                          }
                          if (cleanUrl.startsWith('hashtag://')) {
                            final tag = cleanUrl.replaceFirst('hashtag://', '');
                            final query = tag.startsWith('#') ? tag : '#$tag';
                            Get.to(() => SearchPage(initialQuery: query));
                            return true;
                          }
                          if (cleanUrl.contains('/search') && cleanUrl.contains('q=')) {
                            final uri = Uri.tryParse(cleanUrl);
                            String tag = uri?.queryParameters['q'] ?? '';
                            if (tag.isNotEmpty) {
                              if (!tag.startsWith('#')) tag = '#$tag';
                              Get.to(() => SearchPage(initialQuery: tag));
                              return true;
                            }
                          }
                          final uri = Uri.tryParse(cleanUrl);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                            return true;
                          }
                          return false;
                        },
                      ),
                      if (comment.mediaUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              UrlUtils.getFullUrl(comment.mediaUrl!),
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Row(
                    children: [
                      Text(comment.createdAt ?? '', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => controller.toggleCommentReaction(postId, comment.id, isLiked ? comment.userReaction! : 'like'),
                        onLongPressStart: (details) {
                          _showCommentReactionPicker(context, details.globalPosition, (type) {
                            controller.toggleCommentReaction(postId, comment.id, type);
                          });
                        },
                        child: Text(
                          isLiked ? (comment.userReaction?.capitalizeFirst ?? 'like'.tr) : 'like'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isLiked ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          controller.setReplyTo(comment.id, nameStr);
                          _commentController.text = '@$nameStr ';
                        },
                        child: Text('reply'.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      ),
                      if (isOwnComment) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _confirmDeleteComment(postId, comment.id),
                          child: Text('delete'.tr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.withAlpha(180))),
                        ),
                      ],
                      if (comment.likesCount > 0) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Get.to(() => ReactionsPage(
                                postId: comment.id,
                                summary: comment.reactionSummary,
                                model: 'comment',
                              )),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.thumb_up, size: 8, color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesCount}',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Replies
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Column(
                      children: comment.replies.map((r) => _buildCommentItem(r, postId)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(int postId, int commentId) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_comment'.tr),
        content: Text('delete_comment_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteComment(postId, commentId);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCommentReactionPicker(BuildContext context, Offset position, Function(String) onSelected) {
    HapticFeedback.mediumImpact();
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => overlayEntry.remove(),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dx - 100 > 0 ? position.dx - 100 : 10,
            top: position.dy - 70,
            child: Material(
              color: Colors.transparent,
              child: ReactionPicker(
                onReactionSelected: (type) {
                  onSelected(type);
                  overlayEntry.remove();
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }
}
