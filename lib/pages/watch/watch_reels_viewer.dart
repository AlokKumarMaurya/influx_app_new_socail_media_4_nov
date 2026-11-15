import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../controllers/watch_controller.dart';
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
      _getVideoController(next).catchError((error) {
        debugPrint('Video preload failed: $error');
        throw error;
      });
    }
  }

  void _onPageChanged(int index) {
    final previous = _currentIndex;
    _getVideoController(previous).then((player) => player.pause());
    _getVideoController(index).then((player) => player.play());
    setState(() => _currentIndex = index);
    _preloadAround(index);
    if (index >= _controller.videos.length - 2) {
      _controller.loadMore();
    }
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
            final user = video.post.user;
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
                    );
                  },
                ),
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
                      if (user?.name != null)
                        Text(
                          user!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                          ),
                        ),
                      if (video.post.content?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          video.post.content!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${video.viewsCount} views',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 48,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: () => _controller.toggleReaction(
                          video.post.id,
                          video.post.userReaction ?? 'like',
                        ),
                        icon: Icon(
                          video.post.userReaction == null
                              ? Icons.favorite_border
                              : Icons.favorite,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      Text(
                        '${video.post.reactionsCount}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      Text(
                        '${index + 1}/${videos.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
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
