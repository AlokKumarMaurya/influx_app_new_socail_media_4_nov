import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/post_service.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/custom_network_image.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/feed/reaction_picker.dart';
import 'package:flutter/services.dart';
import '../../pages/feed/reactions_page.dart';
import '../../utils/app_theme.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart' hide ImageSource;
import 'package:url_launcher/url_launcher.dart';
import 'search_page.dart';
import '../marketplace/marketplace_page.dart';
import '../user/profile_page.dart';

class SinglePostPage extends StatefulWidget {
  final int postId;
  final PostModel? initialPost;

  const SinglePostPage({
    super.key,
    required this.postId,
    this.initialPost,
  });

  @override
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  PostModel? _post;
  List<CommentModel> _comments = [];
  bool _loadingPost = true;
  bool _loadingComments = false;
  bool _hasMoreComments = true;
  int _currentCommentPage = 1;
  File? _selectedCommentMedia;
  String? _commentVideoThumbnail;
  int? _replyingToCommentId;
  String? _replyingToUserName;

  List<UserModel> _mentionSearchResults = [];
  bool _isSearchingMentions = false;
  int? _mentionStartIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _loadingPost = false;
    }
    _loadPost();
    _loadComments();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        if (!_loadingComments && _hasMoreComments) {
          _loadComments();
        }
      }
    });

    _commentController.addListener(_onCommentChanged);
  }

  void _onCommentChanged() {
    final text = _commentController.text;
    final selection = _commentController.selection;
    if (selection.baseOffset <= 0) {
      if (_isSearchingMentions) setState(() => _isSearchingMentions = false);
      return;
    }

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final lastAtSymbol = textBeforeCursor.lastIndexOf('@');

    if (lastAtSymbol != -1) {
      // Check if there's a space or it's the start
      final isStartOrAfterSpace = lastAtSymbol == 0 || textBeforeCursor[lastAtSymbol - 1] == ' ' || textBeforeCursor[lastAtSymbol - 1] == '\n';
      
      if (isStartOrAfterSpace) {
        final query = textBeforeCursor.substring(lastAtSymbol + 1);
        // Only trigger if no space in the query
        if (!query.contains(' ')) {
          setState(() {
            _isSearchingMentions = true;
            _mentionStartIndex = lastAtSymbol;
          });
          _searchUsers(query);
          return;
        }
      }
    }

    if (_isSearchingMentions) {
      setState(() => _isSearchingMentions = false);
    }
  }

  Timer? _searchTimer;
  void _searchUsers(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!_isSearchingMentions) return;
      final results = await Get.find<FeedController>().searchUsers(query);
      if (mounted && _isSearchingMentions) {
        setState(() {
          _mentionSearchResults = results;
        });
      }
    });
  }

  void _selectMention(UserModel user) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    
    if (_mentionStartIndex != null) {
      final textBefore = text.substring(0, _mentionStartIndex!);
      final textAfter = text.substring(selection.baseOffset);
      final newText = '$textBefore@${user.username ?? user.name.replaceAll(' ', '_').toLowerCase()} $textAfter';
      
      _commentController.text = newText;
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: textBefore.length + (user.username?.length ?? user.name.length) + 2)
      );
      
      setState(() {
        _isSearchingMentions = false;
        _mentionSearchResults = [];
      });
    }
  }

  Future<void> _loadPost({bool showSkeleton = false}) async {
    if (showSkeleton) setState(() => _loadingPost = true);
    try {
      final post = await _postService.getPostDetails(widget.postId);
      if (mounted) {
        setState(() {
          _post = post;
          _loadingPost = false;
        });

        // Sync with global FeedController if present there, or add it if not
        final feedController = Get.find<FeedController>();
        final index = feedController.posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          feedController.posts[index] = post;
        } else {
          feedController.posts.add(post);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPost = false);
        if (_post == null) {
          Get.snackbar('error'.tr, 'failed_load_post'.tr);
          Get.back();
        }
      }
    }
  }

  Future<void> _loadComments() async {
    if (_loadingComments || !_hasMoreComments) return;

    setState(() => _loadingComments = true);

    try {
      final result = await _postService.getComments(widget.postId, _currentCommentPage);
      final List<CommentModel> newComments = result['comments'];
      
      setState(() {
        _comments.addAll(newComments);
        _currentCommentPage++;
        _hasMoreComments = result['nextPageUrl'] != null;
        _loadingComments = false;
      });
    } catch (e) {
      setState(() => _loadingComments = false);
      Get.snackbar('error'.tr, 'failed_load_comments'.tr);
    }
  }

  Future<void> _pickCommentMedia() async {
    final XFile? file = await _imagePicker.pickMedia();
    if (file != null) {
      final path = file.path;
      final isVideo = path.toLowerCase().endsWith('.mp4') || 
                      path.toLowerCase().endsWith('.mov') || 
                      path.toLowerCase().endsWith('.avi');
      
      if (isVideo) {
        final thumbnail = await VideoThumbnail.thumbnailFile(
          video: path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 200,
          quality: 75,
        );
        setState(() {
          _commentVideoThumbnail = thumbnail;
          _selectedCommentMedia = File(path);
        });
      } else {
        setState(() {
          _selectedCommentMedia = File(path);
          _commentVideoThumbnail = null;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedCommentMedia == null) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      final newComment = await _postService.addComment(
        widget.postId, 
        text,
        image: _selectedCommentMedia,
        parentId: _replyingToCommentId,
      );
      
      setState(() {
        if (_replyingToCommentId == null) {
          _comments.insert(0, newComment);
        } else {
          _addReplyToCommentRecursively(_comments, _replyingToCommentId!, newComment);
        }
        _selectedCommentMedia = null;
        _commentVideoThumbnail = null;
        _replyingToCommentId = null;
        _replyingToUserName = null;

        if (_post != null) {
          _post = _post!.copyWith(commentsCount: _post!.commentsCount + 1);
        }
      });
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_add_comment'.tr);
    }
  }

  bool _addReplyToCommentRecursively(List<CommentModel> comments, int parentId, CommentModel reply) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == parentId) {
        comments[i] = comments[i].copyWith(
          replies: [...comments[i].replies, reply],
        );
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        final found = _addReplyToCommentRecursively(comments[i].replies, parentId, reply);
        if (found) {
          comments[i] = comments[i].copyWith(replies: comments[i].replies);
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _toggleCommentReaction(int commentId, String type) async {
    setState(() {
      _toggleCommentReactionOptimistic(_comments, commentId, type);
    });

    try {
      final result = await _postService.toggleReaction(commentId, type, model: 'comment');
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _updateCommentReactionFromServer(
              _comments,
              commentId,
              result['current_type'],
              result['total_count'],
              result['summary'] != null ? Map<String, int>.from(result['summary']) : null,
            );
          });
        }
      }
    } catch (e) {
      // Optimistic revert could be implemented here
    }
  }

  bool _toggleCommentReactionOptimistic(List<CommentModel> comments, int commentId, String type) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        final comment = comments[i];
        final wasReacted = comment.userReaction != null;
        final sameType = comment.userReaction == type;

        comments[i] = comment.copyWith(
          userReactionValue: sameType ? null : type,
          likesCount: sameType
              ? (comment.likesCount - 1)
              : (wasReacted ? comment.likesCount : comment.likesCount + 1),
        );
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        final found = _toggleCommentReactionOptimistic(comments[i].replies, commentId, type);
        if (found) {
          comments[i] = comments[i].copyWith(replies: comments[i].replies);
          return true;
        }
      }
    }
    return false;
  }

  bool _updateCommentReactionFromServer(List<CommentModel> comments, int commentId, String? currentType, int? totalCount, Map<String, int>? summary) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentId) {
        comments[i] = comments[i].copyWith(
          userReactionValue: currentType,
          likesCount: totalCount ?? comments[i].likesCount,
          reactionSummary: summary ?? comments[i].reactionSummary,
        );
        return true;
      }
      if (comments[i].replies.isNotEmpty) {
        final found = _updateCommentReactionFromServer(comments[i].replies, commentId, currentType, totalCount, summary);
        if (found) {
          comments[i] = comments[i].copyWith(replies: comments[i].replies);
          return true;
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      AppColors.isDark; // Reactivity trigger
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('post'.tr, style: AppTextStyles.h3.copyWith(color: AppColors.textMain)),
          backgroundColor: AppColors.cardBg,
          elevation: 0.5,
          foregroundColor: AppColors.textMain,
          iconTheme: IconThemeData(color: AppColors.textMain),
        ),
        body: Column(
          children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _comments = [];
                  _currentCommentPage = 1;
                  _hasMoreComments = true;
                });
                await Future.wait([_loadPost(), _loadComments()]);
              },
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_loadingPost && _post == null)
                    _buildPostSkeleton()
                  else if (_post != null)
                    Obx(() {
                      final feedController = Get.find<FeedController>();
                      final updatedPost = feedController.posts.firstWhereOrNull((p) => p.id == _post!.id);
                      final displayPost = updatedPost ?? _post!;
                      
                      return PostCard(post: displayPost, isSingleView: true);
                    }),
                  
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${'comments'.tr} (${_post?.commentsCount ?? 0})',
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMain),
                    ),
                  ),

                  if (_comments.isEmpty && !_loadingComments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('no_comments_yet_be_first'.tr, style: const TextStyle(color: Colors.grey)),
                      ),
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),

                  if (_loadingComments && _comments.isEmpty)
                    _buildCommentsSkeleton(),
                  
                  if (_loadingComments && _comments.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  
                  if (!_hasMoreComments && _comments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('no_more_comments'.tr, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                    ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isSearchingMentions && _mentionSearchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2))),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _mentionSearchResults.length,
                itemBuilder: (context, index) {
                  final user = _mentionSearchResults[index];
                  return ListTile(
                    dense: true,
                    leading: CustomAvatar(user: user, radius: 14, fontSize: 10),
                    title: Text(
                      user.name, 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain)
                    ),
                    onTap: () => _selectMention(user),
                  );
                },
              ),
            ),
          _buildCommentInput(),
        ],
      ),
    );
    });
  }

  Widget _buildCommentItem(CommentModel comment) {
    final isLiked = comment.userReaction != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomAvatar(user: comment.user, radius: 16, fontSize: 13),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user?.name ?? 'User',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain),
                      ),
                      const SizedBox(height: 4),
                      if (comment.content != null)
                        HtmlWidget(
                          comment.content!,
                          textStyle: AppTextStyles.bodyMedium.copyWith(fontSize: 14, color: AppColors.textMain),
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
                            if (cleanUrl.startsWith('marketplace://') ||
                                (cleanUrl.contains('/marketplace') && cleanUrl.contains('q='))) {
                              final uri = Uri.tryParse(cleanUrl);
                              String tag = uri?.queryParameters['q'] ?? cleanUrl.replaceFirst('marketplace://', '');
                              if (tag.isNotEmpty) {
                                if (!tag.startsWith('#')) tag = '#$tag';
                                Get.to(() => MarketplacePage(initialSearchQuery: tag));
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
                          child: GestureDetector(
                            onTap: () => Get.toNamed('/media-viewer', arguments: {'mediaUrl': comment.mediaUrl, 'isVideo': false}),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CustomNetworkImage(imageUrl: comment.mediaUrl!, height: 120, fit: BoxFit.cover),
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
                      Text(comment.createdAt ?? 'now', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _toggleCommentReaction(comment.id, isLiked ? comment.userReaction! : 'like'),
                        onLongPressStart: (details) {
                          _showReactionPickerAt(
                            context,
                            details.globalPosition,
                            (type) => _toggleCommentReaction(comment.id, type),
                          );
                        },
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
                              const SizedBox(width: 2),
                              Text('${comment.likesCount}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _replyingToCommentId = comment.id;
                            _replyingToUserName = comment.user?.name ?? 'User';
                          });
                        },
                        child: Text('reply'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textSecondary)),
                      ),
                      if (comment.user?.id == Get.find<AuthController>().user.value?.id) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _confirmDeleteComment(comment.id),
                          child: Text('delete'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.red.withValues(alpha: 0.7))),
                        ),
                      ],
                    ],
                  ),
                ),
                if (comment.replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: comment.replies.map((r) => _buildCommentItem(r)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 10, 
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUserName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${'replying_to'.tr} $_replyingToUserName',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                    onTap: () => setState(() {
                      _replyingToCommentId = null;
                      _replyingToUserName = null;
                    }),
                  ),
                ],
              ),
            ),
          
          if (_selectedCommentMedia != null)
            Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _commentVideoThumbnail != null
                      ? Image.file(File(_commentVideoThumbnail!), fit: BoxFit.cover, width: double.infinity, height: 100)
                      : Image.file(_selectedCommentMedia!, fit: BoxFit.cover, width: double.infinity, height: 100),
                  ),
                  if (_commentVideoThumbnail != null)
                    const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40)),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedCommentMedia = null;
                        _commentVideoThumbnail = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              const CustomAvatar(user: null, radius: 18), 
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickCommentMedia,
                        child: Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: AppColors.textMain),
                          decoration: InputDecoration(
                            hintText: 'write_a_comment'.tr,
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addComment,
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedSent, color: AppColors.primary, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
  void _confirmDeleteComment(int commentId) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_comment'.tr),
        content: Text('delete_comment_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              final feedController = Get.find<FeedController>();
              feedController.deleteComment(widget.postId, commentId).then((_) {
                setState(() {
                  _comments.removeWhere((c) => c.id == commentId);
                  for (var i = 0; i < _comments.length; i++) {
                    if (_comments[i].replies.any((r) => r.id == commentId)) {
                      final newReplies = _comments[i].replies.where((r) => r.id != commentId).toList();
                      _comments[i] = _comments[i].copyWith(replies: newReplies);
                    }
                  }
                });
              });
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReactionPickerAt(BuildContext context, Offset position, Function(String) onSelected) {
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

  Widget _buildPostSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoader(width: 40, height: 40, shape: BoxShape.circle),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 120, height: 12, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 6),
                  SkeletonLoader(width: 80, height: 10, borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonLoader(width: double.infinity, height: 14, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          SkeletonLoader(width: Get.width * 0.6, height: 14, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 16),
          SkeletonLoader(width: double.infinity, height: 200, borderRadius: BorderRadius.circular(12)),
        ],
      ),
    );
  }

  Widget _buildCommentsSkeleton() {
    return Column(
      children: List.generate(3, (index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 32, height: 32, shape: BoxShape.circle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(width: 80, height: 10, borderRadius: BorderRadius.circular(4)),
                        const SizedBox(height: 8),
                        SkeletonLoader(width: double.infinity, height: 12, borderRadius: BorderRadius.circular(4)),
                        const SizedBox(height: 4),
                        SkeletonLoader(width: Get.width * 0.4, height: 12, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}
