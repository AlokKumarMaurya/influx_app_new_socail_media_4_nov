import 'dart:io';
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../data/services/story_service.dart';
import '../../controllers/feed_controller.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final StoryService _storyService = StoryService();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedType = 'text'; // 'text', 'image', 'video'
  File? _selectedMedia;
  String? _videoThumbnail;
  final TextEditingController _textController = TextEditingController();
  String _selectedBgColor = '#3EAFFF';
  final String _selectedFontStyle = 'normal';
  bool _isUploading = false;

  final List<String> _bgColors = [
    '#3EAFFF', '#667eea', '#764ba2', '#ff6b6b', '#4ecdc4', '#45b649', '#f9d423', '#ff9a9e'
  ];

  Future<void> _pickMedia() async {
    final XFile? file = await _picker.pickMedia();
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
          maxWidth: 300,
          quality: 75,
        );
        setState(() {
          _videoThumbnail = thumbnail;
          _selectedMedia = File(path);
          _selectedType = 'video';
        });
      } else {
        setState(() {
          _selectedMedia = File(path);
          _selectedType = 'image';
          _videoThumbnail = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedType == 'text' && _textController.text.trim().isEmpty) return;
    if ((_selectedType == 'image' || _selectedType == 'video') && _selectedMedia == null) return;

    setState(() => _isUploading = true);
    try {
      await _storyService.createStory(
        type: _selectedType,
        media: _selectedMedia,
        content: _textController.text.trim(),
        bgColor: _selectedBgColor,
        fontStyle: _selectedFontStyle,
      );
      Get.find<FeedController>().refreshFeed();
      Get.back();
      Get.snackbar('success'.tr, 'story_posted_successfully'.tr, 
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      String errorMessage = 'failed_post_story'.tr;
      if (e is DioException) {
        final res = e.response;
        if (res?.data is Map && res?.data['message'] != null) {
          errorMessage = res!.data['message'].toString();
        } else if (res?.statusCode == 413) {
          errorMessage = 'file_too_large_upload'.tr;
        } else if (res?.statusCode == 401) {
          errorMessage = 'session_expired_login'.tr;
        }
      }
      Get.snackbar('error'.tr, errorMessage, 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedType == 'text' ? _parseColor(_selectedBgColor) : Colors.black,
      appBar: AppBar(
        title: Text('create_story'.tr),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _submit,
            child: _isUploading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('share'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          // Content
          Center(
            child: _selectedType == 'text' ? _buildTextInput() : _buildMediaPreview(),
          ),

          // Bottom Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedType == 'text') _buildBgColorPicker(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToolbarItem(HugeIcons.strokeRoundedNote01, 'text'.tr, _selectedType == 'text', () {
                        setState(() => _selectedType = 'text');
                      }),
                      const SizedBox(width: 20),
                      _buildToolbarItem(HugeIcons.strokeRoundedImage01, 'media'.tr, _selectedType == 'image', _pickMedia),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TextField(
        controller: _textController,
        textAlign: TextAlign.center,
        maxLines: null,
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: _selectedFontStyle == 'bold' ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: 'type_something'.tr,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildMediaPreview() {
    if (_selectedMedia == null) return const SizedBox.shrink();
    final isVideo = _videoThumbnail != null;
    final file = isVideo ? File(_videoThumbnail!) : _selectedMedia!;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient blurred background
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.45),
          ),
          // Main media scaled to full height / fit screen without side cuts
          Center(
            child: Image.file(
              file,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          if (isVideo)
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
            ),
        ],
      ),
    );
  }

  Widget _buildBgColorPicker() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _bgColors.length,
        itemBuilder: (context, index) {
          final color = _bgColors[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedBgColor = color),
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: _parseColor(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedBgColor == color ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  if (_selectedBgColor == color)
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbarItem(dynamic icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: isActive ? Colors.black : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
  }
}
