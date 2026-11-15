import 'package:material_ui/material_ui.dart';
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
  final bool enableFullScreen;
  final VoidCallback? onTap;
  final VideoPlayerController? sharedController;
  final ValueChanged<VideoPlayerController>? onControllerReady;
  final bool hideControls;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.mediaId,
    this.autoPlay = false,
    this.looping = false,
    this.enableFullScreen = true,
    this.onTap,
    this.sharedController,
    this.onControllerReady,
    this.hideControls = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVisible = false;
  bool _ownsController = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _ownsController = widget.sharedController == null;
      _videoPlayerController = widget.sharedController ?? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      if (!_videoPlayerController.value.isInitialized) await _videoPlayerController.initialize();
      widget.onControllerReady?.call(_videoPlayerController);

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
    _chewieController?.dispose();
    if (_ownsController) _videoPlayerController.dispose();
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
        child: widget.hideControls
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: VideoPlayer(_videoPlayerController),
              )
            : Stack(
                children: [
                  Chewie(controller: _chewieController!),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (widget.onTap != null) {
                          widget.onTap!();
                        } else if (widget.enableFullScreen) {
                          _chewieController?.enterFullScreen();
                          _chewieController?.play();
                        } else {
                          final controller = _chewieController?.videoPlayerController;
                          if (controller == null) return;
                          controller.value.isPlaying ? controller.pause() : controller.play();
                        }
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
