import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../utils/url_utils.dart';
import '../../utils/app_theme.dart';
import '../../utils/string_utils.dart';
import '../../config/app_config.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/professional_badge.dart';
import '../../data/models/fan_page_model.dart';
import '../live/go_live_setup_page.dart';

class CreatePostPage extends StatefulWidget {
  final int? groupId;
  final int? fanPageId;
  final FanPageModel? fanPage;
  final bool isColorPost;
  final PostModel? editPost;
  const CreatePostPage({super.key, this.groupId, this.fanPageId, this.fanPage, this.isColorPost = false, this.editPost});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final FeedController feedController = Get.find<FeedController>();
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _showAddToPost = true;

  bool get _isEditing => widget.editPost != null;

  @override
  void initState() {
    super.initState();
    if (widget.isColorPost) {
      _selectedBgColor = _bgColors[1];
    }
    // Prefill for edit mode
    if (_isEditing) {
      final post = widget.editPost!;
      _textController.text = post.content ?? '';
      _privacy = post.privacy;
      _selectedBgColor = post.bgColor;
      _location = post.location;
      if (post.feelingAction != null && post.feelingValue != null) {
        _selectedFeeling = {'label': post.feelingValue!};
      }
      // Load existing media for display
      _existingMedia = List.from(post.media);
    }
  }

  final List<File> _selectedMedia = [];
  final Map<String, String> _videoThumbnails = {};
  String _privacy = 'public';
  String? _selectedBgColor;
  Map<String, String>? _selectedFeeling;
  String? _location;
  List<UserModel> _taggedUsers = [];
  // Edit mode: existing server-side media & IDs to remove
  List<PostMediaModel> _existingMedia = [];
  final List<int> _removeMediaIds = [];
  Map<String, dynamic>? _linkMeta;
  bool _isFetchingLinkMeta = false;
  String? _lastDetectedUrl;
  bool _linkPreviewDismissed = false;

  void _onTextChanged(String val) {
    if (_linkPreviewDismissed) return;
    final urlRegex = RegExp(r'https?://[^\s<]+', caseSensitive: false);
    final match = urlRegex.firstMatch(val);

    if (match != null) {
      final detectedUrl = match.group(0);
      if (detectedUrl != null && detectedUrl != _lastDetectedUrl && _selectedMedia.isEmpty) {
        _lastDetectedUrl = detectedUrl;
        _fetchLinkMetadata(detectedUrl);
      }
    } else if (_lastDetectedUrl != null) {
      setState(() {
        _lastDetectedUrl = null;
        _linkMeta = null;
      });
    }
  }

  Future<void> _fetchLinkMetadata(String url) async {
    setState(() {
      _isFetchingLinkMeta = true;
    });

    final meta = await feedController.fetchLinkMeta(url);

    if (mounted) {
      setState(() {
        _isFetchingLinkMeta = false;
        if (meta != null) {
          _linkMeta = meta;
        }
      });
    }
  }

  final List<String> _bgColors = [
    '#FFFFFF',
    '#FF5252',
    '#FF4081',
    '#E040FB',
    '#7C4DFF',
    '#536DFE',
    '#448AFF',
    '#40C4FF',
    '#18FFFF',
    '#64FFDA',
    '#69F0AE',
    '#B2FF59',
    '#EEFF41',
    '#FFFF00',
    '#FFD740',
    '#FFAB40',
    '#FF6E40',
  ];

  final List<Map<String, String>> _feelings = [
    {'icon': '😊', 'label': 'Happy'},
    {'icon': '😇', 'label': 'Blessed'},
    {'icon': '🥰', 'label': 'Loved'},
    {'icon': '😔', 'label': 'Sad'},
    {'icon': '😮', 'label': 'Surprised'},
    {'icon': '😡', 'label': 'Angry'},
    {'icon': '😴', 'label': 'Tired'},
    {'icon': '🤩', 'label': 'Excited'},
  ];

  Future<void> _pickMedia() async {
    final List<XFile> pickedFiles = await _picker.pickMultipleMedia();
    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        final path = file.path;
        if (path.toLowerCase().endsWith('.mp4') || 
            path.toLowerCase().endsWith('.mov') || 
            path.toLowerCase().endsWith('.avi')) {
          _generateThumbnail(path);
        }
      }
      setState(() {
        _selectedMedia.addAll(pickedFiles.map((xfile) => File(xfile.path)));
        _selectedBgColor = null; // Background colors only for text posts
      });
    }
  }

  Future<void> _generateThumbnail(String videoPath) async {
    if (_videoThumbnails.containsKey(videoPath)) return;
    
    try {
      final String? thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 75,
      );

      if (thumbPath != null && thumbPath.isNotEmpty) {
        setState(() {
          _videoThumbnails[videoPath] = thumbPath;
        });
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
    }
  }

  bool _isVideo(int index) {
    if (index >= _selectedMedia.length) return false;
    final path = _selectedMedia[index].path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
  }

  Widget _buildMediaPreview(int index) {
    final file = _selectedMedia[index];
    if (_isVideo(index)) {
      final thumbnailPath = _videoThumbnails[file.path];
      if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
        return Image.file(
          File(thumbnailPath), 
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackMediaPreview(),
        );
      }
      return Container(
        color: AppColors.cardBg,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      );
    }
    return Image.file(
      file, 
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallbackMediaPreview(),
    );
  }

  Widget _fallbackMediaPreview() {
    return Container(
      color: AppColors.cardBg,
      child: Center(child: Icon(Icons.image_not_supported, color: AppColors.textSecondary)),
    );
  }

  void _submitPost() {
    final hasExistingMedia = _existingMedia.isNotEmpty;
    if (_textController.text.trim().isEmpty && _selectedMedia.isEmpty && !hasExistingMedia) {
      Get.snackbar('error'.tr, 'post_cannot_be_empty'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String postType = 'text';
    if (_selectedMedia.isNotEmpty || hasExistingMedia) {
      postType = 'image'; // Backend will auto-correct to video if needed
    } else if (_selectedBgColor != null && _selectedBgColor != '#FFFFFF') {
      postType = 'color';
    }

    if (_isEditing) {
      feedController.updatePostWithMedia(
        widget.editPost!.id,
        content: _textController.text.trim(),
        privacy: _privacy,
        postType: postType,
        bgColor: _selectedBgColor,
        feelingAction: _selectedFeeling != null ? 'feeling' : null,
        feelingValue: _selectedFeeling?['label'],
        location: _location,
        newMedia: _selectedMedia.isNotEmpty ? _selectedMedia : null,
        removeMediaIds: _removeMediaIds.isNotEmpty ? _removeMediaIds : null,
      );
    } else {
      feedController.createPost(
        content: _textController.text.trim(),
        postType: postType,
        bgColor: _selectedBgColor,
        feelingAction: _selectedFeeling != null ? 'feeling' : null,
        feelingValue: _selectedFeeling?['label'],
        location: _location,
        privacy: (widget.groupId != null || widget.fanPageId != null) ? 'public' : _privacy,
        linkUrl: _linkMeta?['link_url'],
        linkTitle: _linkMeta?['link_title'],
        linkDescription: _linkMeta?['link_description'],
        linkImage: _linkMeta?['link_image'],
        linkDomain: _linkMeta?['link_domain'],
        ignoreLinkPreview: _linkPreviewDismissed || _linkMeta == null,
        media: _selectedMedia,
        tags: _taggedUsers.map((u) => u.id).toList(),
        groupId: widget.groupId,
        fanPageId: widget.fanPageId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.user.value;
    final bool hasContent = _textController.text.trim().isNotEmpty || _selectedMedia.isNotEmpty || _existingMedia.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.close, size: 26, color: AppColors.textMain),
        ),
        title: Text(
          _isEditing ? 'edit_post'.tr : 'create_post'.tr,
          style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: feedController.isLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : TextButton(
                        onPressed: hasContent ? _submitPost : null,
                        style: TextButton.styleFrom(
                          backgroundColor: hasContent ? AppColors.primary : Colors.grey.shade200,
                          foregroundColor: hasContent ? Colors.white : Colors.grey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          minimumSize: const Size(0, 34),
                        ),
                        child: Text(
                          'post'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: hasContent ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
              )),
        ],
      ),
      body: Column(
        children: [
          // Top thin divider
          Divider(height: 1, color: Colors.grey.shade200),

          // Main scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: (widget.fanPage != null && widget.fanPage!.avatarUrl != null)
                              ? CachedNetworkImageProvider(UrlUtils.getFullUrl(widget.fanPage!.avatarUrl!))
                              : (user?.avatar != null ? CachedNetworkImageProvider(UrlUtils.getFullUrl(user!.avatar!)) : null),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: (widget.fanPage != null && widget.fanPage!.avatarUrl == null)
                              ? const Icon(Icons.flag, color: AppColors.primary, size: 22)
                              : (user?.avatar == null && widget.fanPage == null ? const Icon(Icons.person, color: AppColors.primary, size: 22) : null),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.fanPage != null ? widget.fanPage!.name : (user?.name ?? 'User'),
                                style: AppTextStyles.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              if (widget.fanPage != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Posting as Page', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                )
                              else if (widget.groupId == null) ...[
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: _showPrivacyPicker,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getPrivacyIcon(), size: 13, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        _privacy.tr,
                                        style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ] else
                                Text(
                                  'posting_in_group'.tr,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Feeling / location / tags meta
                  if (_selectedFeeling != null || _location != null || _taggedUsers.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                                children: [
                                  if (_selectedFeeling != null) ...[
                                    const TextSpan(text: 'is '),
                                    TextSpan(text: '${_selectedFeeling!['icon']} ', style: const TextStyle(fontSize: 16)),
                                    const TextSpan(text: 'feeling '),
                                    TextSpan(text: _selectedFeeling!['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                  if (_taggedUsers.isNotEmpty) ...[
                                    const TextSpan(text: ' with '),
                                    TextSpan(
                                      text: _taggedUsers.length == 1 
                                        ? _taggedUsers[0].name 
                                        : '${_taggedUsers[0].name} and ${_taggedUsers.length - 1} others',
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                  if (_location != null) ...[
                                    const TextSpan(text: ' at '),
                                    TextSpan(text: _location!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFeeling = null;
                                _location = null;
                                _taggedUsers = [];
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Text input area
                  Container(
                    constraints: const BoxConstraints(minHeight: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: _selectedBgColor != null && _selectedBgColor != '#FFFFFF'
                        ? BoxDecoration(color: _hexToColor(_selectedBgColor!))
                        : null,
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: (_selectedBgColor != null && _selectedBgColor != '#FFFFFF') ? 22 : 16,
                        height: 1.5,
                        color: (_selectedBgColor != null && _selectedBgColor != '#FFFFFF') ? Colors.white : AppColors.textMain,
                      ),
                      decoration: InputDecoration(
                        hintText: 'whats_on_your_mind'.tr,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: (_selectedBgColor != null && _selectedBgColor != '#FFFFFF')
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {});
                        _onTextChanged(val);
                        if (val.length > 50 && _selectedBgColor != null) {
                          setState(() => _selectedBgColor = null);
                        }
                      },
                    ),
                  ),
                  _buildLiveLinkPreview(),
                  // Media preview grid
                  if (_existingMedia.isNotEmpty || _selectedMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _existingMedia.length + _selectedMedia.length,
                        itemBuilder: (context, index) {
                          if (index < _existingMedia.length) {
                            final item = _existingMedia[index];
                            final isVid = item.fileType == 'video';
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: item.filePath,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: AppColors.cardBg),
                                      errorWidget: (context, url, error) => _fallbackMediaPreview(),
                                    ),
                                  ),
                                ),
                                if (isVid)
                                  const IgnorePointer(
                                    child: Center(
                                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _removeMediaIds.add(item.id);
                                        _existingMedia.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            final fileIndex = index - _existingMedia.length;
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildMediaPreview(fileIndex),
                                  ),
                                ),
                                if (_isVideo(fileIndex))
                                  const IgnorePointer(
                                    child: Center(
                                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMedia.removeAt(fileIndex);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                  // Background color picker (only for text posts)
                  if (_selectedMedia.isEmpty && _textController.text.length < 50)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _bgColors.length,
                          itemBuilder: (context, index) {
                            final colorHex = _bgColors[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBgColor = colorHex == '#FFFFFF' ? null : colorHex;
                                  if (_selectedBgColor != null) _selectedMedia.clear();
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _hexToColor(colorHex),
                                  shape: BoxShape.circle,
                                  border: _selectedBgColor == colorHex
                                      ? Border.all(color: AppColors.primary, width: 2.5)
                                      : Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                                ),
                                child: colorHex == '#FFFFFF'
                                    ? const Icon(Icons.block, size: 16, color: Colors.grey)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // "Add to your post" expandable section
                  if (_showAddToPost) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'add_to_your_post'.tr,
                        style: AppTextStyles.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.8,
                        children: [
                          _buildGridActionCard(
                            icon: HugeIcons.strokeRoundedImage01,
                            label: 'photo_video'.tr,
                            color: const Color(0xFF22C55E),
                            bgColor: const Color(0xFFDCFCE7),
                            onTap: _pickMedia,
                          ),
                          _buildGridActionCard(
                            icon: HugeIcons.strokeRoundedSmileDizzy,
                            label: 'feeling'.tr,
                            color: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFEF3C7),
                            onTap: _showFeelingPicker,
                          ),
                          _buildGridActionCard(
                            icon: HugeIcons.strokeRoundedLocation01,
                            label: 'check_in'.tr,
                            color: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEE2E2),
                            onTap: _showLocationInput,
                          ),
                          _buildGridActionCard(
                            icon: HugeIcons.strokeRoundedUserGroup,
                            label: 'tag_friends'.tr,
                            color: AppColors.primary,
                            bgColor: AppColors.primary.withValues(alpha: 0.1),
                            onTap: _showTagFriendsSheet,
                          ),
                          _buildGridActionCard(
                            icon: HugeIcons.strokeRoundedVideo02,
                            label: 'Go Live',
                            color: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEE2E2),
                            onTap: () => Get.to(() => GoLiveSetupPage(initialFanPageId: widget.fanPageId)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action bar (always visible)
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: EdgeInsets.only(
              left: 16, right: 8, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                _buildBottomIcon(
                  HugeIcons.strokeRoundedVideo02,
                  const Color(0xFFEF4444),
                  () => Get.to(() => GoLiveSetupPage(initialFanPageId: widget.fanPageId)),
                ),
                _buildBottomIcon(HugeIcons.strokeRoundedImage01, const Color(0xFF22C55E), _pickMedia),
                _buildBottomIcon(HugeIcons.strokeRoundedSmileDizzy, const Color(0xFFF59E0B), _showFeelingPicker),
                _buildBottomIcon(HugeIcons.strokeRoundedLocation01, const Color(0xFFEF4444), _showLocationInput),
                _buildBottomIcon(HugeIcons.strokeRoundedUserGroup, AppColors.primary, _showTagFriendsSheet),
                const Spacer(),
                // Expand / collapse chevron
                GestureDetector(
                  onTap: () => setState(() => _showAddToPost = !_showAddToPost),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _showAddToPost ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomIcon(dynamic icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: HugeIcon(icon: icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildGridActionCard({
    required dynamic icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: HugeIcon(icon: icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.add, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showTagFriendsSheet() {
    List<UserModel> tempSelected = List.from(_taggedUsers);
    final searchController = TextEditingController();
    final results = <UserModel>[].obs;
    final isSearching = false.obs;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('tag_friends'.tr, style: AppTextStyles.h3),
                  TextButton(
                    onPressed: () {
                      setState(() => _taggedUsers = tempSelected);
                      Get.back();
                    },
                    child: Text('done'.tr, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'search_friends'.tr,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  fillColor: AppColors.cardBg,
                  filled: true,
                ),
                onChanged: (val) async {
                  if (val.isEmpty) {
                    results.clear();
                    return;
                  }
                  isSearching.value = true;
                  final searchResults = await feedController.searchUsers(val);
                  results.value = searchResults;
                  isSearching.value = false;
                },
              ),
            ),
            Expanded(
              child: Obx(() {
                if (isSearching.value) return const Center(child: CircularProgressIndicator());
                
                final listToShow = results.isEmpty && searchController.text.isEmpty ? tempSelected : results;

                if (listToShow.isEmpty && searchController.text.isNotEmpty) {
                  return Center(child: Text('no_users_found'.tr));
                }

                return ListView.builder(
                  itemCount: listToShow.length,
                  itemBuilder: (context, index) {
                    final user = listToShow[index];
                    final isSelected = tempSelected.any((u) => u.id == user.id);
                    return ListTile(
                      leading: CustomAvatar(user: user, radius: 20),
                      title: Row(
                        children: [
                          Flexible(child: Text(user.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                          if (user.profileType != null && user.profileType != 'user') ...[
                            const SizedBox(width: 4),
                            ProfessionalBadge(profileType: user.profileType, size: 14),
                          ],
                        ],
                      ),
                      subtitle: user.username != null ? Text('@${user.username}', style: AppTextStyles.bodySmall) : null,
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val == true) {
                            if (!tempSelected.any((u) => u.id == user.id)) {
                              tempSelected.add(user);
                            }
                          } else {
                            tempSelected.removeWhere((u) => u.id == user.id);
                          }
                          // Since Obx is watching results, we need an artificial trigger if we're showing tempSelected
                          if (results.isEmpty) results.refresh();
                          results.refresh();
                        },
                      ),
                      onTap: () {
                        if (isSelected) {
                          tempSelected.removeWhere((u) => u.id == user.id);
                        } else {
                          if (!tempSelected.any((u) => u.id == user.id)) {
                            tempSelected.add(user);
                          }
                        }
                        results.refresh();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  IconData _getPrivacyIcon() {
    switch (_privacy) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.people;
      case 'only_me':
        return Icons.lock;
      default:
        return Icons.public;
    }
  }

  void _showPrivacyPicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('who_can_see_your_post'.tr, style: AppTextStyles.h3),
            const SizedBox(height: 20),
            _buildPrivacyOption('public', 'public'.tr, 'public_privacy_desc'.tr, Icons.public),
            _buildPrivacyOption('friends', 'friends'.tr, 'friends_privacy_desc'.tr, Icons.people),
            _buildPrivacyOption('only_me', 'only_me'.tr, 'only_me_desc'.tr, Icons.lock),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(String value, String title, String subtitle, IconData icon) {
    return ListTile(
      onTap: () {
        setState(() => _privacy = value);
        Get.back();
      },
      leading: Icon(icon, color: AppColors.textMain),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: _privacy == value ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
    );
  }

  void _showFeelingPicker() {
    Get.bottomSheet(
      Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Text('how_are_you_feeling'.tr, style: AppTextStyles.h3),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3),
                itemCount: _feelings.length,
                itemBuilder: (context, index) {
                  final feeling = _feelings[index];
                  return ListTile(
                    onTap: () {
                      setState(() => _selectedFeeling = feeling);
                      Get.back();
                    },
                    leading: Text(feeling['icon']!, style: const TextStyle(fontSize: 24)),
                    title: Text(feeling['label']!, style: AppTextStyles.bodyMedium),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationInput() {
    final TextEditingController locCtrl = TextEditingController(text: _location);
    Timer? searchDebounce;
    List<String> suggestions = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void performSearch(String query) {
              searchDebounce?.cancel();
              final cleanQuery = query.trim();
              if (cleanQuery.length < 2) {
                setModalState(() {
                  suggestions = [];
                  isSearching = false;
                });
                return;
              }

              setModalState(() {
                isSearching = true;
              });

              searchDebounce = Timer(const Duration(milliseconds: 300), () async {
                final Set<String> results = {};
                final dio = Dio();

                // 1. Try Nominatim API
                try {
                  final response = await dio.get(
                    'https://nominatim.openstreetmap.org/search',
                    queryParameters: {
                      'format': 'json',
                      'q': cleanQuery,
                      'addressdetails': 1,
                      'limit': 5,
                    },
                    options: Options(
                      headers: {
                        'User-Agent': 'InfluxApp/1.0 (com.hme.company)',
                        'Accept-Language': 'en',
                      },
                    ),
                  );

                  if (response.statusCode == 200 && response.data is List) {
                    for (final item in response.data) {
                      final address = item['address'] as Map<String, dynamic>? ?? {};
                      final List<String> parts = [];

                      final name = item['name']?.toString() ?? address['town']?.toString() ?? address['city']?.toString() ?? address['village']?.toString();
                      if (name != null && name.isNotEmpty) parts.add(name);

                      final city = address['city']?.toString() ?? address['town']?.toString() ?? address['village']?.toString() ?? address['county']?.toString();
                      if (city != null && city.isNotEmpty && !parts.contains(city)) parts.add(city);

                      final state = address['state']?.toString();
                      if (state != null && state.isNotEmpty && !parts.contains(state)) parts.add(state);

                      final country = address['country']?.toString();
                      if (country != null && country.isNotEmpty && !parts.contains(country)) parts.add(country);

                      final formatted = parts.join(', ');
                      if (formatted.isNotEmpty) {
                        results.add(formatted);
                      } else if (item['display_name'] != null) {
                        results.add(item['display_name'].toString());
                      }
                    }
                  }
                } catch (_) {}

                // 2. Fallback to Photon API if Nominatim returns empty
                if (results.isEmpty) {
                  try {
                    final response = await dio.get(
                      'https://photon.komoot.io/api/',
                      queryParameters: {'q': cleanQuery, 'limit': 5},
                      options: Options(
                        headers: {
                          'User-Agent': 'InfluxApp/1.0 (com.hme.company)',
                        },
                      ),
                    );

                    if (response.statusCode == 200 && response.data != null) {
                      final List features = response.data['features'] ?? [];
                      for (final f in features) {
                        final props = f['properties'] as Map<String, dynamic>? ?? {};
                        final List<String> parts = [];

                        if (props['name'] != null) parts.add(props['name'].toString());
                        if (props['city'] != null) {
                          parts.add(props['city'].toString());
                        } else if (props['town'] != null) {
                          parts.add(props['town'].toString());
                        } else if (props['village'] != null) {
                          parts.add(props['village'].toString());
                        }
                        if (props['state'] != null) parts.add(props['state'].toString());
                        if (props['country'] != null) parts.add(props['country'].toString());

                        final uniqueParts = <String>[];
                        for (final p in parts) {
                          if (!uniqueParts.contains(p)) uniqueParts.add(p);
                        }
                        final String formatted = uniqueParts.join(', ');
                        if (formatted.isNotEmpty) {
                          results.add(formatted);
                        }
                      }
                    }
                  } catch (_) {}
                }

                setModalState(() {
                  suggestions = results.toList();
                  isSearching = false;
                });
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'check_in'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locCtrl,
                    autofocus: true,
                    style: TextStyle(fontSize: 14, color: AppColors.textMain),
                    onChanged: (val) {
                      setModalState(() {});
                      performSearch(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'search_location_hint'.tr,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (locCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    locCtrl.clear();
                                    setModalState(() {
                                      suggestions = [];
                                      isSearching = false;
                                    });
                                  },
                                )
                              : null),
                      fillColor: AppColors.cardBg,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        if (isSearching)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'searching_locations'.tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (locCtrl.text.trim().isNotEmpty) ...[
                          ListTile(
                            leading: Icon(Icons.edit_location_alt_outlined, size: 20, color: AppColors.primary),
                            title: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'use_custom_location'.tr),
                                  TextSpan(
                                    text: '"${locCtrl.text.trim()}"',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              style: TextStyle(fontSize: 14, color: AppColors.primary),
                            ),
                            onTap: () {
                              setState(() {
                                _location = locCtrl.text.trim();
                              });
                              Navigator.pop(context);
                            },
                          ),
                          const Divider(height: 1),
                        ],
                        ...suggestions.map((item) => ListTile(
                              leading: Icon(Icons.location_on_outlined, size: 20, color: AppColors.textSecondary),
                              title: Text(
                                item,
                                style: TextStyle(fontSize: 14, color: AppColors.textMain),
                              ),
                              onTap: () {
                                setState(() {
                                  _location = item;
                                });
                                Navigator.pop(context);
                              },
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildLiveLinkPreview() {
    if (_isFetchingLinkMeta) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('fetching_link_preview'.tr, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (_linkMeta == null) return const SizedBox.shrink();

    final linkTitle = _linkMeta!['link_title'] ?? _linkMeta!['link_url'] ?? '';
    final linkDesc = _linkMeta!['link_description'];
    final linkImage = _linkMeta!['link_image'];
    final linkDomain = _linkMeta!['link_domain'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (linkImage != null && linkImage.toString().isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: linkImage.toString(),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (linkDomain != null && linkDomain.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          linkDomain.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      linkTitle.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    if (linkDesc != null && linkDesc.toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          linkDesc.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _linkMeta = null;
                  _lastDetectedUrl = null;
                  _linkPreviewDismissed = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
