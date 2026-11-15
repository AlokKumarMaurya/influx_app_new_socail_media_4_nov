import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../controllers/watch_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/video_player_widget.dart';

class WatchReelsViewer extends StatefulWidget {
  final int initialIndex;

  const WatchReelsViewer({super.key, required this.initialIndex});

  @override
  State<WatchReelsViewer> createState() => _WatchReelsViewerState();
}

class _WatchReelsViewerState extends State<WatchReelsViewer> {
  late final PageController _pageController;
  late final WatchController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WatchController>();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
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
                VideoPlayerWidget(
                  key: ValueKey(video.mediaId),
                  videoUrl: video.videoUrl,
                  mediaId: video.mediaId,
                  autoPlay: index == _currentIndex,
                  looping: true,
                  enableFullScreen: false,
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
