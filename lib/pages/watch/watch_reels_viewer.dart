import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../controllers/watch_controller.dart';
import '../../data/models/watch_video_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../pages/user/profile_page.dart';
import '../../utils/url_utils.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/video_player_widget.dart';

class WatchReelsViewer extends StatefulWidget {
  final int initialIndex;
  final VideoPlayerController? initialVideoController;

  const WatchReelsViewer({super.key, required this.initialIndex, this.initialVideoController});

  @override
  State<WatchReelsViewer> createState() => _WatchReelsViewerState();
}

class _WatchReelsViewerState extends State<WatchReelsViewer> {
  late final PageController _pageController;
  late final WatchController _controller;
  int _currentIndex = 0;
  bool _showControls = false;
  final Map<int, Future<VideoPlayerController>> _preloadedControllers = {};
  final Set<int> _ownedControllerIds = {};

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WatchController>();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _preloadAround(widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final mediaId in _ownedControllerIds) {
      _preloadedControllers[mediaId]?.then((player) => player.dispose());
    }
    super.dispose();
  }

  Future<VideoPlayerController> _getVideoController(int index) async {
    final video = _controller.videos[index];
    if (index == widget.initialIndex && widget.initialVideoController != null) return widget.initialVideoController!;
    return _preloadedControllers.putIfAbsent(video.mediaId, () async {
      final player = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
      _ownedControllerIds.add(video.mediaId);
      await player.initialize();
      return player;
    });
  }

  void _preloadAround(int index) {
    for (var next = index + 1; next <= index + 2 && next < _controller.videos.length; next++) {
      _getVideoController(next).then<void>(
        (_) {},
        onError: (Object error) => debugPrint('Video preload failed: $error'),
      );
    }
  }

  void _onPageChanged(int index) {
    final previous = _currentIndex;
    _getVideoController(previous).then((player) => player.pause());
    _getVideoController(index).then((player) => player.play());
    setState(() {
      _currentIndex = index;
      _showControls = false;
    });
    _preloadAround(index);
    if (index >= _controller.videos.length - 2) {
      _controller.loadMore();
    }
  }


  ProfileController _profileControllerFor(int userId) {
    final tag = 'profile_$userId';
    final controller = Get.isRegistered<ProfileController>(tag: tag)
        ? Get.find<ProfileController>(tag: tag)
        : Get.put(ProfileController(), tag: tag);
    if (controller.profile.value == null && !controller.isProfileFetching) {
      controller.loadProfile(userId);
    }
    return controller;
  }

  Widget _buildCreator(WatchVideoModel video) {
    final user = video.post.user;
    if (user == null) return const SizedBox.shrink();
    final isOwnProfile = Get.find<AuthController>().user.value?.id == user.id;
    final profileController = isOwnProfile ? null : _profileControllerFor(user.id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => Get.to(() => ProfilePage(userId: user.id)),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: Colors.white24,
            backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                ? NetworkImage(UrlUtils.getFullUrl(user.avatar!))
                : null,
            child: user.avatar == null || user.avatar!.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: GestureDetector(
            onTap: () => Get.to(() => ProfilePage(userId: user.id)),
            child: Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
          ),
        ),
        if (!isOwnProfile && profileController != null)
          Obx(() {
            final profile = profileController.profile.value;
            if (profile == null || profile.relation != 'none') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: OutlinedButton(
                onPressed: profileController.toggleFriendAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildVideoControls(int index) {
    if (!_showControls) return const SizedBox.shrink();

    return FutureBuilder<VideoPlayerController>(
      future: _getVideoController(index),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final player = snapshot.data!;
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: player,
          builder: (context, value, _) {
            final durationMs = value.duration.inMilliseconds;
            final positionMs = value.position.inMilliseconds.clamp(0, durationMs > 0 ? durationMs : 0);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: SizedBox.expand(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.28),
                  child: SafeArea(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 38,
                              color: Colors.white,
                              onPressed: () {
                                final target = value.position - const Duration(seconds: 10);
                                player.seekTo(target < Duration.zero ? Duration.zero : target);
                              },
                              icon: const Icon(Icons.replay_10),
                            ),
                            const SizedBox(width: 28),
                            IconButton(
                              iconSize: 54,
                              color: Colors.white,
                              onPressed: () {
                                if (value.isPlaying) {
                                  player.pause();
                                  setState(() => _showControls = true);
                                } else {
                                  player.play();
                                  setState(() => _showControls = false);
                                }
                              },
                              icon: Icon(value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                            ),
                            const SizedBox(width: 28),
                            IconButton(
                              iconSize: 38,
                              color: Colors.white,
                              onPressed: () {
                                final target = value.position + const Duration(seconds: 10);
                                player.seekTo(target > value.duration ? value.duration : target);
                              },
                              icon: const Icon(Icons.forward_10),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 8,
                        child: Row(
                          children: [
                            Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            Expanded(
                              child: Slider(
                                min: 0,
                                max: durationMs > 0 ? durationMs.toDouble() : 1,
                                value: durationMs > 0 ? positionMs.toDouble() : 0,
                                activeColor: AppColors.primary,
                                inactiveColor: Colors.white54,
                                onChanged: durationMs == 0 ? null : (v) => player.seekTo(Duration(milliseconds: v.round())),
                              ),
                            ),
                            Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            IconButton(
                              color: Colors.white,
                              onPressed: () {
                                player.setVolume(value.volume > 0 ? 0 : 1);
                              },
                              icon: Icon(value.volume > 0 ? Icons.volume_up : Icons.volume_off),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final videos = _controller.videos;
        if (videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<VideoPlayerController>(
                  future: _getVideoController(index),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    return VideoPlayerWidget(
                      key: ValueKey(video.mediaId),
                      videoUrl: video.videoUrl,
                      mediaId: video.mediaId,
                      autoPlay: index == _currentIndex,
                      looping: true,
                      enableFullScreen: false,
                      sharedController: snapshot.data,
                      hideControls: true,
                      onTap: () {
                        if (snapshot.data!.value.isPlaying) snapshot.data!.pause();
                        setState(() => _showControls = true);
                      },
                    );
                  },
                ),
                _buildVideoControls(index),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 88,
                  bottom: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCreator(video),
                      if (video.post.content?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(video.post.content!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 8, color: Colors.black)])),
                      ],
                      const SizedBox(height: 8),
                      Text('${video.viewsCount} views', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 48,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () => _controller.toggleReaction(video.post.id, video.post.userReaction ?? 'like'),
                        icon: Icon(
                          video.post.userReaction == null ? Icons.favorite_border : Icons.favorite,
                          color: video.post.userReaction == null ? Colors.white : Colors.red,
                          size: 30,
                        ),
                      ),
                      Text('${video.post.reactionsCount}', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 18),
                      Text('${index + 1}/${videos.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
