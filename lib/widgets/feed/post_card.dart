import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../pages/feed/single_post_page.dart';
import '../../pages/feed/reactions_page.dart';
import '../../pages/user/profile_page.dart';
import '../common/custom_avatar.dart';
import '../common/custom_network_image.dart';
import '../common/professional_badge.dart';
import 'reaction_picker.dart';
import 'post_card_header.dart';
import 'post_card_content.dart';
import 'post_card_media.dart';
import 'post_card_shared.dart';
import 'post_card_stats.dart';
import 'post_card_action_bar.dart';
import '../../data/services/analytics_service.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart' hide ImageSource;
import 'package:url_launcher/url_launcher.dart';
import '../../pages/feed/search_page.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isSingleView;

  const PostCard({
    super.key,
    required this.post,
    this.isSingleView = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with AutomaticKeepAliveClientMixin {
  bool _showComments = false;
  bool _showEmojiPicker = false;
  File? _selectedCommentImage;
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      PostModel post = widget.post;
      try {
        if (Get.isRegistered<FeedController>()) {
          final feedController = Get.find<FeedController>();
          post = feedController.posts.firstWhereOrNull((p) => p.id == widget.post.id) ?? widget.post;
        }
      } catch (e) {
        // Fallback to widget.post
      }

      return RepaintBoundary(
        child: VisibilityDetector(
          key: Key('post_view_${post.id}'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction > 0.5) {
              AnalyticsService().recordPostView(post.id);
            }
          },
          child: Container(
            margin: widget.isSingleView
                ? const EdgeInsets.only(bottom: 6)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(widget.isSingleView ? 0 : 20),
            ),
            child: CommentToggleProvider(
              toggle: () => setState(() => _showComments = !_showComments),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostCardHeader(post: post, isSingleView: widget.isSingleView),
                  PostCardContent(post: post, isSingleView: widget.isSingleView),
                  PostCardMedia(post: post, isSingleView: widget.isSingleView),
                  if (post.sharedPost != null) PostCardShared(shared: post.sharedPost!),
                  PostCardStats(post: post),
                  PostCardActionBar(post: post, isSingleView: widget.isSingleView),
                  if (_showComments && !widget.isSingleView) _buildCommentsSection(post),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ─── COMMENTS SECTION ────────────────────────────────────────────────────────

  Widget _buildCommentsSection(PostModel post) {
    final controller = Get.find<FeedController>();
    final postId = post.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.postComments.containsKey(postId)) {
        controller.loadComments(postId);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Replying-To Banner
          Obx(() {
            final replyUser = controller.replyingToUserName.value;
            if (replyUser == null) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(25)),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${'replying_to'.tr} $replyUser',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  GestureDetector(
                    onTap: controller.clearReplyTo,
                    child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            );
          }),

          _buildCommentInput(),
          if (_selectedCommentImage != null) _buildImagePreview(),
          if (_showEmojiPicker) _buildEmojiPicker(),

          Obx(() {
            final isLoading = controller.isCommentsLoading[postId]?.value ?? true;
            final comments = controller.postComments[postId] ?? <CommentModel>[].obs;

            if (isLoading && comments.isEmpty) {
              return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            }
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text('no_comments_yet_be_first'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.commentsCount > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: GestureDetector(
                      onTap: () => Get.to(() => SinglePostPage(postId: widget.post.id, initialPost: widget.post)),
                      child: Text(
                        '${'view_all'.tr} ${widget.post.commentsCount} ${'comments'.tr}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ...comments.map((comment) => _buildCommentItem(comment)),
              ],
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withAlpha(25),
            child: const Icon(Icons.person, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 44,
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'write_a_comment'.tr,
                        hintStyle: TextStyle(color: AppColors.textSecondary.withAlpha(128), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(color: AppColors.textMain, fontSize: 13),
                    ),
                  ),
                  _buildCommentInputActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _pickCommentImage,
          child: Icon(Icons.camera_alt_outlined, size: 18,
              color: _selectedCommentImage != null ? AppColors.primary : AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() {
            _showEmojiPicker = !_showEmojiPicker;
            if (_showEmojiPicker) FocusScope.of(context).unfocus();
          }),
          child: Icon(Icons.emoji_emotions_outlined, size: 18,
              color: _showEmojiPicker ? AppColors.primary : AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            final text = _commentController.text.trim();
            if (text.isNotEmpty || _selectedCommentImage != null) {
              Get.find<FeedController>().addComment(widget.post.id, text, image: _selectedCommentImage);
              _commentController.clear();
              setState(() {
                _selectedCommentImage = null;
                _showEmojiPicker = false;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCommentImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedCommentImage = File(image.path));
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withAlpha(51)), borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_selectedCommentImage!, height: 100, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedCommentImage = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => _commentController.text += emoji.emoji,
        config: Config(
          height: 250,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(columns: 7, emojiSizeMax: 32, backgroundColor: AppColors.cardBg),
          categoryViewConfig: const CategoryViewConfig(),
          bottomActionBarConfig: const BottomActionBarConfig(),
          searchViewConfig: const SearchViewConfig(),
        ),
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    final controller = Get.find<FeedController>();
    final isLiked = comment.userReaction != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => comment.user != null ? Get.to(() => ProfilePage(userId: comment.user!.id)) : null,
            child: CustomAvatar(user: comment.user, radius: 14, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => comment.user != null ? Get.to(() => ProfilePage(userId: comment.user!.id)) : null,
                        child: Row(
                          children: [
                            Text(comment.user?.name ?? 'User',
                                style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMain)),
                            if (comment.user?.profileType != null)
                              ProfessionalBadge(profileType: comment.user!.profileType, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (comment.content != null && comment.content!.isNotEmpty)
                        HtmlWidget(
                          _formatCommentContent(comment.content!),
                          textStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: AppColors.textMain),
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
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: () => Get.toNamed('/media-viewer', arguments: {
                              'mediaUrl': comment.mediaUrl,
                              'isVideo': false,
                              'postId': widget.post.id.toString(),
                              'commentId': comment.id.toString()
                            }),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomNetworkImage(imageUrl: comment.mediaUrl!, height: 100, fit: BoxFit.cover),
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
                      GestureDetector(
                        onTap: () => controller.toggleCommentReaction(
                            widget.post.id, comment.id, isLiked ? (comment.userReaction ?? 'like') : 'like'),
                        onLongPressStart: (details) => _showReactionPickerAt(
                          context,
                          details.globalPosition,
                          (type) => controller.toggleCommentReaction(widget.post.id, comment.id, type),
                        ),
                        child: Text(
                          isLiked ? (comment.userReaction?.capitalizeFirst ?? 'like'.tr) : 'like'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: isLiked ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Get.to(() => ReactionsPage(postId: comment.id, summary: comment.reactionSummary, model: 'comment')),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.thumb_up, size: 8, color: Colors.white),
                              ),
                              const SizedBox(width: 2),
                              Text('${comment.likesCount}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => controller.setReplyTo(comment.id, comment.user?.name ?? 'User'),
                        child: Text('reply'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textSecondary)),
                      ),
                      Text(comment.createdAt ?? 'now', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (comment.user?.id == Get.find<AuthController>().user.value?.id) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _confirmDeleteComment(widget.post.id, comment.id),
                          child: Text('delete'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.red.withAlpha(178))),
                        ),
                      ],
                    ],
                  ),
                ),
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(children: comment.replies.map((r) => _buildCommentItem(r)).toList()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentContent(String text) {
    if (text.contains('<a ')) return text;
    final hashtagRegex = RegExp(r'(<a\b[^>]*>.*?<\/a>)|(?<![\w&])#([a-zA-Z0-9_\u0080-\uFFFF]+)');
    return text.replaceAllMapped(hashtagRegex, (match) {
      if (match.group(1) != null) return match.group(1)!;
      final hashtag = match.group(0)!;
      final tag = match.group(2)!;
      return '<a href="hashtag://$tag" style="color: #2563eb; font-weight: 600; text-decoration: none;">$hashtag</a>';
    });
  }

  void _confirmDeleteComment(int postId, int commentId) {
    Get.dialog(AlertDialog(
      title: Text('delete_comment'.tr),
      content: Text('delete_comment_confirm'.tr),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        TextButton(
          onPressed: () {
            Get.back();
            Get.find<FeedController>().deleteComment(postId, commentId);
          },
          child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  void _showReactionPickerAt(BuildContext context, Offset position, Function(String) onSelected) {
    HapticFeedback.mediumImpact();
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(onTap: () => overlayEntry.remove(), child: Container(color: Colors.transparent)),
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
