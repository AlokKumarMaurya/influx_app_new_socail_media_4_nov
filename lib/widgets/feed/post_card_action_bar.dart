import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../controllers/feed_controller.dart';
import '../common/custom_avatar.dart';
import './reaction_picker.dart';

class PostCardActionBar extends StatefulWidget {
  final PostModel post;
  final bool isSingleView;

  const PostCardActionBar({
    super.key,
    required this.post,
    required this.isSingleView,
  });

  @override
  State<PostCardActionBar> createState() => _PostCardActionBarState();
}

class _PostCardActionBarState extends State<PostCardActionBar> {
  OverlayEntry? _reactionOverlay;
  final LayerLink _reactionLayerLink = LayerLink();

  static const _emojiMap = {
    'like': '👍', 'love': '❤️', 'haha': '😂', 'care': '🥰', 'wow': '😮', 'sad': '😢', 'angry': '😡',
  };
  static const _colorMap = {
    'like': Color(0xFF548dff), 'love': Color(0xFFf55064), 'haha': Color(0xFFffda6a),
    'care': Color(0xFFffda6a), 'wow': Color(0xFF38bdf8), 'sad': Color(0xFF548dff), 'angry': Color(0xFFd5234c),
  };

  void _showReactionPopup() {
    if (_reactionOverlay != null) return;

    _reactionOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideReactionPopup,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _reactionLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, -60),
              child: Material(
                elevation: 8,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                child: ReactionPicker(
                  onReactionSelected: (type) {
                    Get.find<FeedController>().toggleReaction(widget.post.id, type);
                    _hideReactionPopup();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_reactionOverlay!);
    setState(() {});
  }

  void _hideReactionPopup() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
    setState(() {});
  }

  @override
  void dispose() {
    _reactionOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final hasReaction = post.userReaction != null;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.textMain.withAlpha(15))),
          ),
          child: CompositedTransformTarget(
            link: _reactionLayerLink,
            child: Row(
              children: [
                // Like button
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.find<FeedController>().toggleReaction(post.id, 'like'),
                    onLongPress: _showReactionPopup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasReaction)
                            Text(_emojiMap[post.userReaction] ?? '👍', style: const TextStyle(fontSize: 18))
                          else
                            HugeIcon(icon: HugeIcons.strokeRoundedThumbsUp, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            hasReaction ? (post.userReaction ?? 'like'.tr).capitalize! : 'like'.tr,
                            style: TextStyle(
                              color: hasReaction ? (_colorMap[post.userReaction] ?? AppColors.primary) : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Comment button — handled by parent via onCommentTap
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Parent's setState will toggle _showComments; we expose this via a key or callback.
                      // We use a simple approach: publish to the nearest ancestor via context.
                      final fn = _CommentToggleScope.of(context);
                      fn?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedComment01, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 6),
                          Text('comment'.tr, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Share button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showShareDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedShare01, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 6),
                          Text('share'.tr, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showShareDialog(BuildContext context) {
    final contentController = TextEditingController();
    String privacy = 'public';

    Get.bottomSheet(
      Obx(() {
        AppColors.isDark; // Reactivity trigger
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 20),
                      Text('share'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      IconButton(onPressed: () => Get.back(), icon: Icon(Icons.close, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CustomAvatar(user: widget.post.user, radius: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post.user?.name ?? 'User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
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
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
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
                  TextField(
                    controller: contentController,
                    maxLines: 2,
                    style: TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'say_something_about_this'.tr,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ShareOption(
                    icon: HugeIcons.strokeRoundedShare01,
                    title: 'share_now_public'.tr,
                    subtitle: 'instantly_sharing_feed'.tr,
                    onTap: () {
                      Get.find<FeedController>().sharePost(widget.post.id, contentController.text, 'public');
                      Get.back();
                    },
                  ),
                  _ShareOption(
                    icon: HugeIcons.strokeRoundedBubbleChat,
                    title: 'send_in_messenger'.tr,
                    onTap: () {
                      Get.back();
                      Get.snackbar('coming_soon'.tr, 'messenger_sharing_not_implemented'.tr);
                    },
                  ),
                  _ShareOption(
                    icon: HugeIcons.strokeRoundedLink01,
                    title: 'copy_link'.tr,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: 'https://influx.com/posts/${widget.post.id}'));
                      Get.back();
                      Get.snackbar('success'.tr, 'link_copied_clipboard'.tr);
                    },
                  ),
                  _ShareOption(
                    icon: HugeIcons.strokeRoundedMenu01,
                    title: 'more_options'.tr,
                    onTap: () {
                      Get.back();
                      SharePlus.instance.share(ShareParams(uri: Uri.parse('https://influx.com/posts/${widget.post.id}')));
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.find<FeedController>().sharePost(widget.post.id, contentController.text, privacy);
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('share_on_your_profile'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
          },
        );
      }),
      isScrollControlled: true,
    );
  }
}

class _ShareOption extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ShareOption({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
        child: HugeIcon(icon: icon, color: AppColors.textMain, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMain)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

/// Inherited widget to pass the "toggle comments" callback down the tree.
class _CommentToggleScope extends InheritedWidget {
  final VoidCallback toggle;

  const _CommentToggleScope({required this.toggle, required super.child});

  static VoidCallback? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_CommentToggleScope>()?.toggle;
  }

  @override
  bool updateShouldNotify(_CommentToggleScope old) => toggle != old.toggle;
}

/// Wrap your PostCardActionBar with this to supply the callback.
class CommentToggleProvider extends StatelessWidget {
  final VoidCallback toggle;
  final Widget child;

  const CommentToggleProvider({super.key, required this.toggle, required this.child});

  @override
  Widget build(BuildContext context) {
    return _CommentToggleScope(toggle: toggle, child: child);
  }
}
