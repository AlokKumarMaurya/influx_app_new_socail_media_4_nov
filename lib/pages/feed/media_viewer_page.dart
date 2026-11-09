import 'dart:io';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/post_model.dart';
import '../../widgets/common/video_player_widget.dart';
import '../../utils/url_utils.dart';

class MediaViewerPage extends StatefulWidget {
  final List<PostMediaModel> media;
  final int initialIndex;
  final String? heroTagPrefix;

  const MediaViewerPage({
    super.key,
    required this.media,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Lock to orientations that allow full screen feel but reset on exit
    // Typically for immersive viewer we might allow landscape but want to be sure it resets
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Force reset to portrait when leaving the viewer
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _saveMedia() async {
    final media = widget.media[_currentIndex];
    final url = UrlUtils.getFullUrl(media.filePath);
    
    try {
      Get.showSnackbar(GetSnackBar(
        message: 'starting_download'.tr,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      ));

      final tempDir = await getTemporaryDirectory();
      final extension = media.fileType == 'video' ? 'mp4' : 'jpg';
      final path = '${tempDir.path}/downloaded_media_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await Dio().download(url, path);

      if (media.fileType == 'video') {
          await Gal.putVideo(path);
      } else {
          await Gal.putImage(path);
      }
      
      // Clean up temp file
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      Get.showSnackbar(GetSnackBar(
        message: 'saved_to_gallery'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      ));
    } catch (e) {
      debugPrint('Error saving media: $e');
      Get.showSnackbar(GetSnackBar(
        message: 'failed_to_save_media'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 500) Get.back();
            },
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                final item = widget.media[index];
                if (item.fileType == 'video') {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: Center(
                      child: GestureDetector(
                        // Translucent behavior allows gestures to pass to the gallery for swiping
                        behavior: HitTestBehavior.translucent,
                        child: VideoPlayerWidget(
                          videoUrl: UrlUtils.getFullUrl(item.filePath),
                          mediaId: item.id,
                          autoPlay: true,
                          looping: true,
                        ),
                      ),
                    ),
                    heroAttributes: widget.heroTagPrefix != null 
                        ? PhotoViewHeroAttributes(tag: '${widget.heroTagPrefix}_${item.id}')
                        : null,
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 1.1,
                  );
                }
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(UrlUtils.getFullUrl(item.filePath)),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  heroAttributes: widget.heroTagPrefix != null 
                    ? PhotoViewHeroAttributes(tag: '${widget.heroTagPrefix}_${item.id}')
                    : PhotoViewHeroAttributes(tag: item.id),
                );
              },
              itemCount: widget.media.length,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              pageController: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
            ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_currentIndex + 1} / ${widget.media.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          if (widget.media[_currentIndex].fileType == 'video') ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.play_arrow, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.media[_currentIndex].viewsCount} views',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download_rounded, color: Colors.white, size: 26),
                          onPressed: _saveMedia,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Safe Area indicator (optional visual or just spacing)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: const SizedBox(height: 20),
            ),
          ),
        ],
      ),
    );
  }
}
