import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../data/services/chat_service.dart';
import '../../utils/app_theme.dart';

class ChatInput extends StatefulWidget {
  final void Function(
    String? body,
    File? attachment, {
    bool viewOnce,
    bool isVoiceNote,
    int? voiceDuration,
  })
  onSend;
  final VoidCallback? onEmojiTap;
  final String quickEmoji;
  final bool showGifts;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onEmojiTap,
    this.quickEmoji = '👍',
    this.showGifts = true,
  });

  @override
  State<ChatInput> createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  final TextEditingController textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  File? _attachmentFile;
  bool _hasText = false;
  bool _viewOnce = false;
  bool _recording = false;
  bool _voiceSendBusy = false;
  int _recordSeconds = 0;
  String? _recordPath;
  Timer? _recordTimer;
  final AudioRecorder _recorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    textController.addListener(() {
      final hasText = textController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
      if (hasText) {
        Get.find<ChatController>().notifyTyping();
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void insertEmoji(String emoji) {
    final text = textController.text;
    final selection = textController.selection;
    final start = selection.baseOffset >= 0
        ? selection.baseOffset
        : text.length;
    final end = selection.extentOffset >= 0
        ? selection.extentOffset
        : text.length;
    final newText = text.replaceRange(start, end, emoji);
    textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    _focusNode.requestFocus();
  }

  void _handleSend() {
    final body = textController.text.trim();
    if (body.isEmpty && _attachmentFile == null) return;

    widget.onSend(
      body.isEmpty ? null : body,
      _attachmentFile,
      viewOnce: _viewOnce && _attachmentFile != null,
    );
    textController.clear();
    setState(() {
      _attachmentFile = null;
      _hasText = false;
      _viewOnce = false;
    });
  }

  void _openTools() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _toolChip(
                    label: 'photo'.tr,
                    icon: Icons.image_outlined,
                    bg: const Color(0xFFECFDF5),
                    fg: const Color(0xFF059669),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage();
                    },
                  ),
                  _toolChip(
                    label: 'video'.tr,
                    icon: Icons.videocam_outlined,
                    bg: const Color(0xFFEFF6FF),
                    fg: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickVideo();
                    },
                  ),
                  _toolChip(
                    label: 'file'.tr,
                    icon: Icons.attach_file,
                    bg: const Color(0xFFFFF1F2),
                    fg: const Color(0xFFE11D48),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickFile();
                    },
                  ),
                  _toolChip(
                    label: 'voice_note'.tr,
                    icon: Icons.mic_none,
                    bg: const Color(0xFFEDE9FE),
                    fg: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.pop(ctx);
                      _startRecording();
                    },
                  ),
                  _toolChip(
                    label: 'location'.tr,
                    icon: Icons.location_on_outlined,
                    bg: const Color(0xFFFEF3C7),
                    fg: const Color(0xFFD97706),
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendLocation();
                    },
                  ),
                  if (widget.showGifts)
                    _toolChip(
                      label: 'gift'.tr,
                      icon: Icons.card_giftcard,
                      bg: const Color(0xFFFAE8FF),
                      fg: const Color(0xFFA21CAF),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openGifts();
                      },
                    ),
                  _toolChip(
                    label: 'View Once',
                    icon: Icons.visibility_off_outlined,
                    bg: _viewOnce
                        ? const Color(0xFFE0E7FF)
                        : const Color(0xFFF1F5F9),
                    fg: const Color(0xFF475569),
                    active: _viewOnce,
                    onTap: () {
                      setState(() => _viewOnce = !_viewOnce);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolChip({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: active
              ? Border.all(color: const Color(0xFF6366F1), width: 2)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _giftMoney(num amount) {
    if (amount <= 0) return 'gift_free'.tr;
    final symbol = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>().currencySymbol.value
        : '\$';
    final value = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$symbol$value';
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        Get.snackbar(
          'voice_note'.tr,
          'Allow microphone access to record a voice note.',
        );
        return;
      }
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _recordPath = path;
      _recordTimer?.cancel();
      setState(() {
        _recording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_recording) return;
        setState(() => _recordSeconds += 1);
        if (_recordSeconds >= 120) _sendRecording();
      });
    } catch (e) {
      Get.snackbar('voice_note'.tr, 'Could not start recording.');
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}
    _recordPath = null;
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _sendRecording() async {
    if (_voiceSendBusy) return;
    _voiceSendBusy = true;
    _recordTimer?.cancel();
    final seconds = _recordSeconds < 1 ? 1 : _recordSeconds;
    String? path = _recordPath;
    try {
      final stopped = await _recorder.stop();
      if (stopped != null && stopped.isNotEmpty) path = stopped;
    } catch (_) {}
    _recordPath = null;
    if (!mounted) {
      _voiceSendBusy = false;
      return;
    }
    setState(() => _recording = false);
    final file = path == null ? null : File(path);
    if (file == null || !file.existsSync() || file.lengthSync() < 32) {
      _voiceSendBusy = false;
      Get.snackbar(
        'voice_note'.tr,
        'Voice note was empty. Record again and tap send.',
      );
      return;
    }
    widget.onSend(
      null,
      file,
      isVoiceNote: true,
      voiceDuration: seconds,
      viewOnce: _viewOnce,
    );
    setState(() => _viewOnce = false);
    _voiceSendBusy = false;
  }

  Future<void> _sendLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        Get.snackbar(
          'location'.tr,
          'Turn on location services, then try again.',
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('location'.tr, 'location_permission_hint'.tr);
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        Get.snackbar('location'.tr, 'location_permission_hint'.tr);
        return;
      }
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 25),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        Get.snackbar('location'.tr, 'location_unavailable_hint'.tr);
        return;
      }
      await Get.find<ChatController>().sendMessage(
        latitude: pos.latitude,
        longitude: pos.longitude,
        locationLabel: 'shared_location'.tr,
      );
    } catch (e) {
      Get.snackbar('location'.tr, 'location_unavailable_hint'.tr);
    }
  }

  Future<void> _openGifts() async {
    final gifts = await ChatService().getGifts();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'send_gift'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              if (gifts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('no_gifts_available'.tr),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, i) {
                    final g = gifts[i];
                    final price = double.tryParse('${g['price'] ?? 0}') ?? 0;
                    final image = g['image']?.toString();
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        final id = g['id'];
                        if (id is int) Get.find<ChatController>().sendGift(id);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: image != null && image.isNotEmpty
                                  ? Image.network(image, fit: BoxFit.contain)
                                  : const Icon(
                                      Icons.card_giftcard,
                                      color: Color(0xFFA21CAF),
                                      size: 36,
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              g['name']?.toString() ?? 'gift'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _giftMoney(price),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendQuickEmoji() {
    widget.onSend(widget.quickEmoji, null);
  }

  bool _validateFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes > 25 * 1024 * 1024) {
      Get.snackbar(
        'file_too_large'.tr,
        'file_exceeds_size_limit'.tr,
        backgroundColor: AppColors.error.withValues(alpha: 0.1),
        colorText: AppColors.error,
      );
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      final file = File(picked.path);
      if (_validateFileSize(file)) {
        setState(() {
          _attachmentFile = file;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (picked != null) {
      final file = File(picked.path);
      if (_validateFileSize(file)) {
        setState(() {
          _attachmentFile = file;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (_validateFileSize(file)) {
        setState(() {
          _attachmentFile = file;
        });
      }
    }
  }

  void _clearAttachment() {
    setState(() {
      _attachmentFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(
            color: AppColors.isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment preview bar
            Obx(() {
              final reply = Get.find<ChatController>().replyTo.value;
              if (reply == null) return const SizedBox.shrink();
              final preview =
                  (reply.body != null && reply.body!.trim().isNotEmpty)
                  ? reply.body!.trim()
                  : (reply.attachmentType ?? 'message'.tr);
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                reply.senderName.isNotEmpty
                                    ? reply.senderName
                                    : 'reply'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: Get.find<ChatController>().clearReply,
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_viewOnce)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'view_once'.tr,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (_recording)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text('recording'.tr),
                    const Spacer(),
                    Text('$_recordSeconds s'),
                    TextButton(
                      onPressed: _cancelRecording,
                      child: Text('cancel'.tr),
                    ),
                    TextButton(
                      onPressed: _sendRecording,
                      child: Text('send_message'.tr),
                    ),
                  ],
                ),
              ),
            if (_attachmentFile != null) _buildAttachmentPreview(),

            // Input bar row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBadgeButton(
                    icon: Icons.add_rounded,
                    bg: _viewOnce
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (AppColors.isDark
                              ? const Color(0xFF2C2C2C)
                              : const Color(0xFFF1F5F9)),
                    iconColor: AppColors.primary,
                    onTap: _openTools,
                  ),
                  const SizedBox(width: 4),

                  // Pill text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppColors.isDark
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: textController,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textMain,
                        ),
                        decoration: InputDecoration(
                          hintText: 'type_a_message'.tr,
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 14.5,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Emoji picker toggle badge (Soft Yellow)
                  _buildBadgeButton(
                    icon: Icons.sentiment_satisfied_alt_outlined,
                    bg: AppColors.isDark
                        ? const Color(0xFF3B331A)
                        : const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFEAB308),
                    onTap: widget.onEmojiTap ?? () {},
                  ),

                  // Send button or Quick Emoji button
                  if (_hasText || _attachmentFile != null)
                    _buildSendButton()
                  else
                    _buildQuickEmojiButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    final isImage = _isImageFile(_attachmentFile!);
    final isVideo = _isVideoFile(_attachmentFile!);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _attachmentFile!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          else if (isVideo)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _attachmentFile!.path.split('/').last,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isImage
                      ? 'photo_attachment'.tr
                      : (isVideo
                            ? 'video_attachment'.tr
                            : 'file_attachment'.tr),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _clearAttachment,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeButton({
    required IconData icon,
    required Color bg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _handleSend,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, size: 17, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickEmojiButton() {
    return GestureDetector(
      onTap: _sendQuickEmoji,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Text(widget.quickEmoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  bool _isImageFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext);
  }

  bool _isVideoFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'flv'].contains(ext);
  }
}
