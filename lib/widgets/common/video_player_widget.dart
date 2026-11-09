import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../utils/app_theme.dart';
import '../../data/services/analytics_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final int? mediaId;
  final bool autoPlay;
  final bool looping;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.mediaId,
    this.autoPlay = false,
    this.looping = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white.withValues(alpha: 0.5),
        ),
      );

      if (widget.mediaId != null) {
        AnalyticsService().recordVideoView(widget.mediaId!);
      }

      setState(() {});
    } catch (e) {
      debugPrint('Video Player error: $e');
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final visibleFraction = info.visibleFraction;
    final isVisible = visibleFraction > 0.5; // Pause if more than 50% hidden

    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      if (!_isVisible) {
        if (_videoPlayerController.value.isPlaying) {
          _videoPlayerController.pause();
        }
      } else if (widget.autoPlay && !_videoPlayerController.value.isPlaying) {
        _videoPlayerController.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return VisibilityDetector(
        key: Key(widget.videoUrl),
        onVisibilityChanged: _handleVisibilityChanged,
        child: Stack(
          children: [
            Chewie(controller: _chewieController!),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _chewieController?.enterFullScreen();
                  _chewieController?.play();
                },
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
  }
}
