import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../utils/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/story_controller.dart';
import '../../data/models/story_model.dart';
import '../../data/services/story_service.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/custom_network_image.dart';
import '../../widgets/common/professional_badge.dart';
import 'dart:async';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import '../../utils/url_utils.dart';
import '../../widgets/story/floating_reaction_overlay.dart';


class StoryViewPage extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  const StoryViewPage({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> {
  late StoryController controller;
  Timer? _timer;
  double _progress = 0.0;
  int _storyDurationSeconds = 5;
  bool _isPaused = false;
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;
  final TextEditingController _replyController = TextEditingController();
  final FloatingReactionController _floatingReactionController = FloatingReactionController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(StoryController());
    controller.initViewer(widget.groups, widget.initialGroupIndex);
    _handleStoryChange();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _progress = 0.0;
    _isPaused = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused || _isVideoLoading) return;
      
      setState(() {
        _progress += 0.05 / _storyDurationSeconds;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _nextStory();
        }
      });
    });
  }

  void _handleStoryChange() {
    final story = controller.currentStory;
    _videoController?.dispose();
    _videoController = null;
    _isVideoLoading = false;

    if (story.mediaType == 'video' && story.mediaUrl != null) {
      _initVideo(story.mediaUrl!);
    } else {
      _storyDurationSeconds = 5;
      _startTimer();
    }
  }

  Future<void> _initVideo(String url) async {
    setState(() {
      _isVideoLoading = true;
      _isPaused = true;
    });

    final fullUrl = UrlUtils.getFullUrl(url);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(fullUrl));

    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(false);
      await _videoController!.play();
      
      if (mounted) {
        setState(() {
          _storyDurationSeconds = _videoController!.value.duration.inSeconds;
          if (_storyDurationSeconds == 0) _storyDurationSeconds = 5; // Fallback
          _isVideoLoading = false;
          _isPaused = false;
          _startTimer();
        });
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _storyDurationSeconds = 5;
          _startTimer();
        });
      }
    }
  }

  void _nextStory() {
    controller.nextStory();
    _handleStoryChange();
  }

  void _previousStory() {
    controller.previousStory();
    _handleStoryChange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPaused = true);
          _videoController?.pause();
        },
        onTapCancel: () {
          setState(() => _isPaused = false);
          _videoController?.play();
        },
        onTapUp: (details) {
          setState(() => _isPaused = false);
          _videoController?.play();
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
            Get.back();
          }
        },
        child: Stack(
          children: [
            // Story Content
            Obx(() => _buildStoryContent(controller.currentStory)),

            // Top Gradient
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Top Controls
            SafeArea(
              child: Column(
                children: [
                  // Progress Bars
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Obx(() {
                      final group = controller.currentGroup;
                      return Row(
                        children: List.generate(group.stories.length, (index) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: LinearProgressIndicator(
                                value: index < controller.currentStoryIndex.value
                                    ? 1.0
                                    : (index == controller.currentStoryIndex.value ? _progress : 0.0),
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 2,
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),

                  // User Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Obx(() {
                          final user = controller.currentGroup.user;
                          return Row(
                            children: [
                              CustomAvatar(
                                user: null,
                                avatarUrl: user.avatar,
                                name: user.name,
                                radius: 18,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        user.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      ProfessionalBadge(profileType: user.profileType, size: 12),
                                    ],
                                  ),
                                  Obx(() => Text(
                                    controller.currentStory.createdAt ?? '',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                                  )),
                                ],
                              ),
                            ],
                          );
                        }),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Actions (Viewers/Reactions)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Obx(() {
                      final isOwnStory = controller.currentStory.userId == Get.find<AuthController>().user.value?.id;
                      
                      if (isOwnStory) {
                        return _buildOwnStoryActions(controller.currentStory);
                      }

                      return _buildStoryReplyInput();
                    }),
                  ),
                ),
              ),
            ),

            // Floating Story Reactions Animation Layer
            Positioned.fill(
              child: FloatingReactionOverlay(
                controller: _floatingReactionController,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryReplyInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildReactionItem('👍', 'like'),
            _buildReactionItem('❤️', 'love'),
            _buildReactionItem('😂', 'haha'),
            _buildReactionItem('😮', 'wow'),
            _buildReactionItem('😢', 'sad'),
            _buildReactionItem('😡', 'angry'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _replyController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onTap: () {
                    setState(() {
                      _isPaused = true;
                    });
                  },
                  onSubmitted: (_) => _sendStoryReply(),
                  decoration: InputDecoration(
                    hintText: 'send_message'.tr,
                    hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              onPressed: _sendStoryReply,
            ),
          ],
        ),
      ],
    );
  }

  void _sendStoryReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    _replyController.clear();
    FocusScope.of(context).unfocus();
    _isPaused = false;

    final story = controller.currentStory;
    try {
      final StoryService storyService = StoryService();
      await storyService.sendStoryReply(story.id, body: text);
      Get.snackbar(
        'reply_sent'.tr,
        'message_sent'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_send_reply'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  void _reactToStory(int storyId, String reaction, {Offset? tapPosition, String? emoji}) {
    if (emoji != null) {
      _floatingReactionController.trigger(emoji, origin: tapPosition);
    }

    final StoryService storyService = StoryService();
    storyService.sendStoryReply(storyId, reaction: reaction).catchError((_) {
      return storyService.reactToStory(storyId, reaction).then((_) => <String, dynamic>{});
    });
  }

  Widget _buildReactionItem(String emoji, String reaction) {
    return _AnimatedReactionButton(
      key: ValueKey('reaction_btn_$reaction'),
      emoji: emoji,
      reaction: reaction,
      onTap: (position) {
        _reactToStory(
          controller.currentStory.id,
          reaction,
          tapPosition: position,
          emoji: emoji,
        );
      },
    );
  }

  Widget _buildOwnStoryActions(StoryModel story) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _showViewersList(story.id),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('viewers'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () => _confirmDelete(story.id),
        ),
      ],
    );
  }

  void _showViewersList(int storyId) async {
    _isPaused = true;
    final StoryService storyService = StoryService();
    try {
      final viewers = await storyService.getViewers(storyId);
      Get.bottomSheet(
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('story_viewers'.tr, style: AppTextStyles.h3),
                  const SizedBox(height: 20),
                  Expanded(
                    child: viewers.isEmpty 
                      ? Center(child: Text('no_viewers_yet'.tr))
                      : ListView.builder(
                          itemCount: viewers.length,
                          itemBuilder: (context, index) {
                            final viewer = viewers[index];
                            final reaction = viewer['reaction'];
                            return ListTile(
                              leading: CustomAvatar(
                                user: null, 
                                avatarUrl: viewer['avatar'], 
                                name: viewer['name'], 
                                radius: 18,
                              ),
                              title: Row(
                                children: [
                                  Text(viewer['name']),
                                  if (viewer['profile_type'] != null) ProfessionalBadge(profileType: viewer['profile_type'], size: 12),
                                ],
                              ),
                              subtitle: Text(viewer['viewed_at'] ?? ''),
                              trailing: reaction != null ? Text(_getEmojiForReaction(reaction), style: const TextStyle(fontSize: 20)) : null,
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).then((_) => _isPaused = false);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_load_viewers'.tr);
      _isPaused = false;
    }
  }

  void _confirmDelete(int storyId) {
    _isPaused = true;
    Get.dialog(
      AlertDialog(
        title: Text('delete_story_question'.tr),
        content: Text('delete_story_confirm'.tr),
        actions: [
          TextButton(onPressed: () { Get.back(); _isPaused = false; }, child: Text('cancel'.tr)),
          TextButton(
            onPressed: () async {
              await controller.deleteStory(storyId);
              Get.back(); // close dialog
              Get.back(); // close story viewer
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (story.mediaType == 'text') {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: _parseColor(story.bgColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              story.content ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: _getFontWeight(story.fontStyle),
              ),
            ),
          ),
        ),
      );
    }

    if (story.mediaUrl != null) {
      if (story.mediaType == 'video') {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: _videoController != null && _videoController!.value.isInitialized
            ? Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      }

      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient blurred backdrop for wide/narrow aspect ratio images
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: CustomNetworkImage(
                imageUrl: story.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
            // Main image scaled to full height / screen fit without cutting any sides
            Center(
              child: CustomNetworkImage(
                imageUrl: story.mediaUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }


  Color _parseColor(String? colorStr) {
    if (colorStr == null) return AppColors.primary;
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      return Color(int.parse(colorStr));
    } catch (_) {
      return AppColors.primary;
    }
  }

  FontWeight _getFontWeight(String? style) {
    switch (style) {
      case 'bold':
        return FontWeight.bold;
      case 'modern':
        return FontWeight.w300;
      default:
        return FontWeight.normal;
    }
  }

  String _getEmojiForReaction(String reaction) {
    switch (reaction) {
      case 'like': return '👍';
      case 'love': return '❤️';
      case 'haha': return '😂';
      case 'wow': return '😮';
      case 'sad': return '😢';
      case 'angry': return '😡';
      default: return '';
    }
  }
}

class _AnimatedReactionButton extends StatefulWidget {
  final String emoji;
  final String reaction;
  final void Function(Offset position) onTap;

  const _AnimatedReactionButton({
    super.key,
    required this.emoji,
    required this.reaction,
    required this.onTap,
  });

  @override
  State<_AnimatedReactionButton> createState() => _AnimatedReactionButtonState();
}

class _AnimatedReactionButtonState extends State<_AnimatedReactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.8), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward(from: 0.0);
    Offset? position;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final globalOffset = renderBox.localToGlobal(Offset.zero);
      position = Offset(globalOffset.dx + size.width / 2, globalOffset.dy);
    }
    widget.onTap(position ?? Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
