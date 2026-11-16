import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../data/models/post_model.dart';
import '../../pages/user/profile_page.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';

class FeedReelsViewer extends StatefulWidget {
  final List<PostModel> posts;
  final int initialPostId;
  final int initialMediaId;
  const FeedReelsViewer({super.key, required this.posts, required this.initialPostId, required this.initialMediaId});
  @override
  State<FeedReelsViewer> createState() => _FeedReelsViewerState();
}
class _FeedVideo {
  final PostModel post;
  final PostMediaModel media;
  const _FeedVideo(this.post, this.media);
}
class _FeedReelsViewerState extends State<FeedReelsViewer> {
  late final List<_FeedVideo> _videos;
  late final PageController _pageController;
  final Map<int, Future<VideoPlayerController>> _players = {};
  final Set<int> _ownedPlayerIds = {};
  final Map<int, ProfileController> _profileControllers = {};
  int _currentIndex = 0;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _videos = [for (final post in widget.posts) for (final media in post.media.where((item) => item.fileType == 'video')) _FeedVideo(post, media)];
    final initial = _videos.indexWhere((item) => item.post.id == widget.initialPostId && item.media.id == widget.initialMediaId);
    _currentIndex = initial < 0 ? 0 : initial;
    _pageController = PageController(initialPage: _currentIndex);
    _loadPlayer(_currentIndex).then((player) => player.play());
    _preloadAround(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final id in _ownedPlayerIds) {
      _players[id]?.then((player) => player.dispose());
    }
    super.dispose();
  }

  Future<VideoPlayerController> _loadPlayer(int index) async {
    final media = _videos[index].media;
    return _players.putIfAbsent(media.id, () async {
      final player = VideoPlayerController.networkUrl(Uri.parse(UrlUtils.getFullUrl(media.filePath)));
      _ownedPlayerIds.add(media.id);
      await player.initialize();
      await player.setLooping(true);
      return player;
    });
  }

  void _preloadAround(int index) {
    for (var next = index + 1; next <= index + 2 && next < _videos.length; next++) {
      _loadPlayer(next).then<void>((_) {}, onError: (Object error) => debugPrint('Home video preload failed: $error'));
    }
  }

  void _onPageChanged(int index) {
    final previous = _currentIndex;
    _loadPlayer(previous).then((player) => player.pause());
    setState(() { _currentIndex = index; _showControls = false; });
    _loadPlayer(index).then((player) => player.play());
    _preloadAround(index);
  }

  void _onVideoSurfaceTap(VideoPlayerController player) {
    if (player.value.isPlaying) player.pause();
    setState(() => _showControls = true);
  }

  ProfileController _profileControllerFor(int userId) {
    return _profileControllers.putIfAbsent(userId, () {
      final tag = 'profile_$userId';
      final controller = Get.isRegistered<ProfileController>(tag: tag)
          ? Get.find<ProfileController>(tag: tag)
          : Get.put(ProfileController(), tag: tag);
      if (controller.profile.value == null && !controller.isProfileFetching) controller.loadProfile(userId);
      return controller;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildControls(VideoPlayerController player) {
    if (!_showControls) return const SizedBox.shrink();
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: player,
      builder: (context, value, _) {
        final durationMs = value.duration.inMilliseconds;
        final positionMs = value.position.inMilliseconds.clamp(0, durationMs > 0 ? durationMs : 0);
        return Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.30),
            child: SafeArea(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(iconSize: 38, color: Colors.white, onPressed: () {
                          final target = value.position - const Duration(seconds: 10);
                          player.seekTo(target < Duration.zero ? Duration.zero : target);
                        }, icon: const Icon(Icons.replay_10)),
                        const SizedBox(width: 24),
                        IconButton(iconSize: 58, color: Colors.white, onPressed: () {
                          if (value.isPlaying) {
                            player.pause();
                            setState(() => _showControls = true);
                          } else {
                            player.play();
                            setState(() => _showControls = false);
                          }
                        }, icon: Icon(value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled)),
                        const SizedBox(width: 24),
                        IconButton(iconSize: 38, color: Colors.white, onPressed: () {
                          final target = value.position + const Duration(seconds: 10);
                          player.seekTo(target > value.duration ? value.duration : target);
                        }, icon: const Icon(Icons.forward_10)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 14, right: 14, bottom: 8,
                    child: Row(children: [
                      Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      Expanded(child: Slider(
                        min: 0, max: durationMs > 0 ? durationMs.toDouble() : 1,
                        value: durationMs > 0 ? positionMs.toDouble() : 0,
                        activeColor: AppColors.primary, inactiveColor: Colors.white54,
                        onChanged: durationMs == 0 ? null : (v) => player.seekTo(Duration(milliseconds: v.round())),
                      )),
                      Text(_formatDuration(value.duration), style: const TextStyle(color: Colors.white, fontSize: 11)),
                      IconButton(color: Colors.white, onPressed: () => player.setVolume(value.volume > 0 ? 0 : 1), icon: Icon(value.volume > 0 ? Icons.volume_up : Icons.volume_off)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreator(_FeedVideo item) {
    final user = item.post.user;
    if (user == null) return const SizedBox.shrink();
    final isOwnProfile = Get.find<AuthController>().user.value?.id == user.id;
    final profileController = isOwnProfile ? null : _profileControllerFor(user.id);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () => Get.to(() => ProfilePage(userId: user.id)),
        child: CircleAvatar(radius: 19, backgroundColor: Colors.white24,
          backgroundImage: user.avatar != null && user.avatar!.isNotEmpty ? NetworkImage(UrlUtils.getFullUrl(user.avatar!)) : null,
          child: user.avatar == null || user.avatar!.isEmpty ? const Icon(Icons.person, color: Colors.white) : null),
      ),
      const SizedBox(width: 9),
      Flexible(child: GestureDetector(
        onTap: () => Get.to(() => ProfilePage(userId: user.id)),
        child: Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 8, color: Colors.black)])),
      )),
      if (!isOwnProfile && profileController != null)
        Obx(() {
          final profile = profileController.profile.value;
          if (profile == null || profile.relation != 'none') return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(left: 10), child: OutlinedButton(
            onPressed: profileController.toggleFriendAction,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Follow', style: TextStyle(fontWeight: FontWeight.bold)),
          ));
        }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_videos.isEmpty) return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('No videos found', style: TextStyle(color: Colors.white))));
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController, scrollDirection: Axis.vertical, itemCount: _videos.length, onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final item = _videos[index];
          return FutureBuilder<VideoPlayerController>(
            future: _loadPlayer(index),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final player = snapshot.data!;
              return Stack(fit: StackFit.expand, children: [
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _onVideoSurfaceTap(player),
                  child: Center(child: AspectRatio(aspectRatio: player.value.aspectRatio > 0 ? player.value.aspectRatio : 9 / 16, child: VideoPlayer(player)))),
                _buildControls(player),
                SafeArea(child: Align(alignment: Alignment.topLeft, child: IconButton(onPressed: Get.back, icon: const Icon(Icons.arrow_back, color: Colors.white)))),
                Positioned(left: 16, right: 82, bottom: 36, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  _buildCreator(item),
                  if (item.post.content?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(item.post.content!, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 8, color: Colors.black)])),
                  ],
                ])),
                Positioned(right: 12, bottom: 42, child: Column(children: [
                  IconButton(onPressed: () => Get.find<FeedController>().toggleReaction(item.post.id, item.post.userReaction ?? 'like'),
                    icon: Icon(item.post.userReaction == null ? Icons.favorite_border : Icons.favorite, color: item.post.userReaction == null ? Colors.white : Colors.red, size: 30)),
                  Text('${item.post.reactionsCount}', style: const TextStyle(color: Colors.white)),
                ])),
              ]);
            },
          );
        },
      ),
    );
  }
}
