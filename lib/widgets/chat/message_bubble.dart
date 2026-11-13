import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/call_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/story_model.dart';
import '../../data/models/user_model.dart';
import '../../pages/story/story_view_page.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import 'voice_note_player.dart';
import '../common/custom_avatar.dart';
import '../common/video_player_widget.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool showAvatar;
  final bool showSenderName;
  final VoidCallback? onImageTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeReply;
  final VoidCallback? onOpenViewOnce;
  final Color? themeColor;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showSenderName = false,
    this.onImageTap,
    this.onLongPress,
    this.onSwipeReply,
    this.onOpenViewOnce,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final color = themeColor ?? AppColors.primary;

    return Dismissible(
      key: ValueKey('swipe-${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onSwipeReply?.call();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Icon(Icons.reply_rounded, color: color),
      ),
      child: Opacity(
        opacity: message.isOptimistic ? 0.7 : 1.0,
        child: Padding(
          padding: EdgeInsets.only(
            left: isMine ? 60 : 0,
            right: isMine ? 0 : 60,
            top: showAvatar ? 6 : 2,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine && showSenderName && message.senderName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 36, bottom: 2),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              Row(
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar (theirs only)
              if (!isMine && showAvatar)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CustomAvatar(
                    avatarUrl: message.senderAvatar,
                    name: message.senderName,
                    radius: 14,
                  ),
                )
              else if (!isMine)
                const SizedBox(width: 36),

              // Bubble content
              Flexible(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: onLongPress,
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (message.replyTo != null &&
                          (message.body == null ||
                              message.body!.trim().isEmpty))
                        _buildReplyQuote(isMine, color),
                      if (message.isDeleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Message deleted',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else ...[
                        // Story reply card (Facebook style)
                        if (message.storyReply != null)
                          _buildStoryReplyCard(context),

                        // Call Log Card (Facebook style)
                        if (message.attachmentType == 'call')
                          _buildCallCard(context),

                        if (message.viewOnce &&
                            [
                              'image',
                              'video',
                              'voice',
                              'audio',
                            ].contains(message.attachmentType))
                          _buildViewOnceCard(),

                        if (message.attachmentType != 'call' &&
                            !message.viewOnce) ...[
                          // Image attachment
                          if (message.attachment != null &&
                              message.attachmentType == 'image')
                            _buildImageAttachment(context),

                          // Video attachment
                          if (message.attachment != null &&
                              message.attachmentType == 'video')
                            _buildVideoAttachment(context),

                          // File attachment
                          if (message.attachment != null &&
                              message.attachmentType == 'file')
                            _buildFileAttachment(context),

                          if (message.attachment != null &&
                              (message.attachmentType == 'voice' ||
                                  message.attachmentType == 'audio'))
                            VoiceNotePlayer(
                              url: message.attachment!,
                              isMine: message.isMine,
                              durationSeconds: _voiceDurationSeconds(
                                message.payload,
                              ),
                            ),

                          // Text bubble
                          if (message.body != null && message.body!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMine
                                    ? color.withValues(alpha: 0.12)
                                    : (AppColors.isDark
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                                  bottomRight: Radius.circular(isMine ? 4 : 18),
                                ),
                                border: isMine
                                    ? null
                                    : Border.all(
                                        color: AppColors.isDark
                                            ? Colors.white10
                                            : const Color(0xFFF1F5F9),
                                      ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (message.replyTo != null) ...[
                                    _buildReplyQuote(isMine, color),
                                    const SizedBox(height: 6),
                                  ],
                                  _buildMessageBody(color),
                                ],
                              ),
                            ),
                        ],
                        if (message.attachmentType == 'gift' &&
                            message.payload != null)
                          _buildGiftCard(),
                        if (message.attachmentType == 'location' &&
                            message.payload != null)
                          _buildLocationCard(),
                        if (message.reactions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              children: message.reactions
                                  .map(
                                    (r) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Text(
                                        '${r.emoji} ${r.count}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        if (showAvatar)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 3,
                              left: 8,
                              right: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: message.time == 'Failed'
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                if (message.editedAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      'edited'.tr,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                if (isMine && !message.isOptimistic) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isRead
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 14,
                                    color: message.isRead
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyQuote(bool isMine, Color color) {
    final reply = message.replyTo!;
    final preview = reply.isDeleted
        ? 'message_deleted'.tr
        : ((reply.body != null && reply.body!.trim().isNotEmpty)
              ? reply.body!.trim()
              : _replyKindLabel(reply.attachmentType));
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withValues(alpha: 0.78)
            : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reply.senderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  String _replyKindLabel(String? type) {
    switch (type) {
      case 'image':
        return 'photo'.tr;
      case 'video':
        return 'video'.tr;
      case 'voice':
      case 'audio':
        return 'voice_note'.tr;
      case 'location':
        return 'shared_location'.tr;
      case 'gift':
        return 'gift'.tr;
      case 'file':
        return 'file'.tr;
      default:
        return type ?? 'message'.tr;
    }
  }

  Widget _buildViewOnceCard() {
    final opened = message.viewOnceOpened && !message.isMine;
    final type = message.attachmentType ?? 'image';
    final label = type == 'video'
        ? 'view_once_video'.tr
        : (type == 'voice' || type == 'audio'
              ? 'view_once_voice'.tr
              : 'view_once_photo'.tr);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: message.isMine
            ? const Color(0xFFD9ECFF)
            : const Color(0xFFE8ECF4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: opened ? null : onOpenViewOnce,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type == 'video'
                      ? Icons.videocam_outlined
                      : (type == 'voice' || type == 'audio'
                            ? Icons.mic_none
                            : Icons.image_outlined),
                  color: const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      opened
                          ? 'view_once_opened'.tr
                          : (type == 'voice' || type == 'audio'
                                ? 'tap_to_listen'.tr
                                : 'view_once_media'.tr),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                if (!opened) ...[
                  const SizedBox(width: 12),
                  const Text(
                    '1',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? _voiceDurationSeconds(Map<String, dynamic>? payload) {
    if (payload == null) return null;
    final raw = payload['voice_duration'];
    if (raw is int) return raw;
    return int.tryParse('$raw');
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

  Widget _buildGiftCard() {
    final payload = message.payload!;
    final name = payload['name']?.toString() ?? 'gift'.tr;
    final image = payload['image']?.toString();
    final price = double.tryParse('${payload['price_paid'] ?? 0}') ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: message.isMine
            ? const Color(0xFFEEF2FF)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: message.isMine
              ? const Color(0xFFC7D2FE)
              : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image != null && image.isNotEmpty
                ? Image.network(image, width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56,
                    height: 56,
                    color: Colors.white,
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Color(0xFFEA580C),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'gift'.tr.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC2410C),
                  ),
                ),
                Text(
                  message.isMine ? 'gift_sent'.tr : 'gift_received'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  _giftMoney(price),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final lat = message.payload!['lat'];
    final lng = message.payload!['lng'];
    final label = message.payload!['label']?.toString() ?? 'shared_location'.tr;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => launchUrl(
          Uri.parse('https://maps.google.com/?q=$lat,$lng'),
          mode: LaunchMode.externalApplication,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 90,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [Color(0xFFDBEAFE), Color(0xFFDCFCE7)],
                  ),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF4F46E5),
                  size: 32,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '$lat, $lng',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'view_on_map'.tr,
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryReplyCard(BuildContext context) {
    final story = message.storyReply!;
    if (story.isExpired) {
      return Container(
        width: 220,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history_toggle_off,
              color: Colors.grey.shade500,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'story_expired'.tr,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Color bgColor = AppColors.primary;
    if (story.bgColor != null && story.bgColor!.isNotEmpty) {
      try {
        final hex = story.bgColor!.replaceFirst('#', '');
        bgColor = Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
      } catch (_) {}
    }

    final user = UserModel(id: story.userId, name: story.userName);

    final storyModel = StoryModel(
      id: story.id,
      userId: story.userId,
      mediaType: story.type,
      mediaUrl: story.mediaUrl,
      content: story.content,
      bgColor: story.bgColor,
      user: user,
    );

    final group = StoryGroup(user: user, stories: [storyModel]);

    return GestureDetector(
      onTap: () =>
          Get.to(() => StoryViewPage(groups: [group], initialGroupIndex: 0)),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.history_edu_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'replied_to_story'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty)
              SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  story.mediaUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: bgColor,
                child: Center(
                  child: Text(
                    story.content ?? 'Text Story',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBody(Color color) {
    final text = message.body!;
    final urlRegex = RegExp(r'(https?://[^\s<]+|www\.[^\s<]+)');
    final matches = urlRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14.5,
          color: message.isMine ? color : AppColors.textMain,
          height: 1.4,
        ),
      );
    }

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: TextStyle(
              fontSize: 14.5,
              color: message.isMine ? color : AppColors.textMain,
              height: 1.4,
            ),
          ),
        );
      }

      final urlText = match.group(0)!;
      spans.add(
        TextSpan(
          text: urlText,
          style: const TextStyle(
            fontSize: 14.5,
            color: Colors.blue,
            decoration: TextDecoration.underline,
            height: 1.4,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(
                urlText.startsWith('www.') ? 'http://$urlText' : urlText,
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: TextStyle(
            fontSize: 14.5,
            color: message.isMine ? color : AppColors.textMain,
            height: 1.4,
          ),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildImageAttachment(BuildContext context) {
    final isLocalFile = message.attachment!.startsWith('/');
    final imageUrl = isLocalFile
        ? message.attachment!
        : UrlUtils.getFullUrl(message.attachment!);

    return GestureDetector(
      onTap: onImageTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: const BoxConstraints(maxWidth: 250, maxHeight: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isLocalFile
              ? Image.file(
                  File(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _imagePlaceholder(),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _imagePlaceholder();
                  },
                  errorBuilder: (_, _, _) => _imagePlaceholder(),
                ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context) {
    final isLocalFile = message.attachment!.startsWith('/');
    final videoUrl = isLocalFile
        ? message.attachment!
        : UrlUtils.getFullUrl(message.attachment!);

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.65;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: BoxConstraints(maxWidth: maxBubbleWidth, maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isLocalFile
            ? Container(
                height: 160,
                color: Colors.black87,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              )
            : VideoPlayerWidget(
                videoUrl: videoUrl,
                autoPlay: false,
                looping: true,
              ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 200,
      height: 150,
      color: AppColors.isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(Icons.image, color: AppColors.textSecondary, size: 32),
      ),
    );
  }

  Widget _buildFileAttachment(BuildContext context) {
    final rawPath = message.attachment ?? '';
    final fileName = rawPath.split('/').last;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.65;

    return GestureDetector(
      onTap: () {
        if (message.attachment != null &&
            !message.attachment!.startsWith('/')) {
          _downloadFile(context, message.attachment!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.isDark
              ? const Color(0xFF2C2C2C)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName.isNotEmpty ? fileName : 'attachment'.tr,
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
                    'tap_to_download'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(
    BuildContext context,
    String attachmentPath,
  ) async {
    final fullUrl = UrlUtils.getFullUrl(attachmentPath);
    final fileName = attachmentPath.split('/').last;

    try {
      Get.showSnackbar(
        GetSnackBar(
          message: '${'downloading'.tr} $fileName...',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        ),
      );

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final savePath =
          '${dir?.path ?? (await getTemporaryDirectory()).path}/$fileName';

      await Dio().download(fullUrl, savePath);

      final ext = fileName.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        await Gal.putImage(savePath);
      } else if (['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'].contains(ext)) {
        await Gal.putVideo(savePath);
      }

      Get.showSnackbar(
        GetSnackBar(
          message: '${'downloaded_to_device'.tr}: $fileName',
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        ),
      );
    } catch (e) {
      debugPrint('Download error: $e');
      Get.showSnackbar(
        GetSnackBar(
          message: 'failed_to_download_file'.tr,
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.error,
          snackPosition: SnackPosition.BOTTOM,
        ),
      );
    }
  }

  Widget _buildCallCard(BuildContext context) {
    Map<String, dynamic> callData = {};
    if (message.attachment != null) {
      try {
        callData = jsonDecode(message.attachment!);
      } catch (_) {}
    }

    final isVideo =
        (callData['call_type'] ?? '').toString().toLowerCase() == 'video' ||
        (message.body ?? '').toLowerCase().contains('video');
    final isMissed =
        (callData['status'] ?? '').toString().toLowerCase() == 'rejected' ||
        (message.body ?? '').toLowerCase().contains('missed');
    String durationStr = (callData['formatted_duration'] ?? '').toString();
    if (durationStr.isEmpty && callData['duration_seconds'] != null) {
      final sec = int.tryParse(callData['duration_seconds'].toString()) ?? 0;
      if (sec > 0) {
        final m = sec ~/ 60;
        final s = sec % 60;
        durationStr = m > 0 ? '${m}m ${s}s' : '${s}s';
      }
    }
    if (durationStr.isEmpty && (message.body ?? '').contains('•')) {
      final parts = message.body!.split('•');
      if (parts.length > 1) {
        durationStr = parts.sublist(1).join('•').trim();
      }
    }

    return Container(
      width: 250,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMissed
              ? Colors.red.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMissed
                  ? Colors.red.withValues(alpha: 0.12)
                  : Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVideo
                  ? Icons.videocam_rounded
                  : (isMissed ? Icons.call_missed_rounded : Icons.call_rounded),
              color: isMissed ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMissed
                      ? (isVideo
                            ? 'missed_video_call'.tr
                            : 'missed_audio_call'.tr)
                      : (isVideo ? 'video_call'.tr : 'audio_call'.tr),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  durationStr.toString().isNotEmpty
                      ? '${message.time} • $durationStr'
                      : message.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              final CallController callCtrl = Get.put(
                CallController(),
                permanent: true,
              );
              callCtrl.initiateCall(
                receiverId: message.senderId,
                type: isVideo ? 'video' : 'voice',
              );
            },
            child: Text(
              'callback'.tr,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Date divider widget
class MessageDateDivider extends StatelessWidget {
  final String date;

  const MessageDateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
