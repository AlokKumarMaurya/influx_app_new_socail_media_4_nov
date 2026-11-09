// ignore_for_file: use_null_aware_elements
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/call_controller.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/chat_service.dart';
import '../../widgets/common/video_player_widget.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../widgets/chat/emoji_picker_sheet.dart';
import '../../widgets/chat/image_lightbox.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/professional_badge.dart';
import 'chat_info_sheet.dart';
import 'room_info_sheet.dart';

class ChatPage extends StatefulWidget {
  final int conversationId;
  final ChatUser user;
  final ConversationModel? conversation;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.user,
    this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController _chatController = Get.find<ChatController>();
  final GlobalKey<ChatInputState> _inputKey = GlobalKey<ChatInputState>();
  bool _showMessageSearch = false;
  final TextEditingController _messageSearchController = TextEditingController();
  ConversationModel? _cachedConv;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _cachedConv = widget.conversation;
    _chatController.openConversation(
      widget.conversationId,
      widget.user,
      conversation: widget.conversation ?? _cachedConv,
    );

    // Scroll-up pagination
    _chatController.messagesScrollController.addListener(_onScroll);
  }

  ConversationModel? get _currentConversation {
    return _chatController.conversations
            .firstWhereOrNull((c) => c.id == widget.conversationId) ??
        _cachedConv;
  }

  bool get _isPendingRequest {
    final conv = _currentConversation;
    if (conv == null) return false;
    final myId = _chatController.currentUserId;
    if (conv.status == 'requests' || conv.status == 'spam') {
      return (conv.requestedToUserId == null || conv.requestedToUserId == myId) ||
          conv.isPendingRequest ||
          conv.isSpam;
    }
    return false;
  }

  bool get _isSpamRequest {
    final conv = _currentConversation;
    return conv?.status == 'spam' || conv?.isSpam == true;
  }

  Future<void> _handleAccept() async {
    setState(() => _isActionInProgress = true);
    final success = await _chatController.acceptRequest(widget.conversationId);
    if (mounted) {
      setState(() {
        _isActionInProgress = false;
        if (success && _cachedConv != null) {
          _cachedConv = _cachedConv!.copyWith(
            status: 'inbox',
            isPendingRequest: false,
            isSpam: false,
          );
        }
      });
      if (success) {
        Get.snackbar(
          'request_accepted'.tr,
          'you_can_now_chat'.tr,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isActionInProgress = true);
    final success = await _chatController.declineRequest(widget.conversationId);
    if (mounted) {
      setState(() => _isActionInProgress = false);
      if (success) {
        Get.back();
      }
    }
  }

  Future<void> _handleBlock() async {
    setState(() => _isActionInProgress = true);
    await _chatController.updateSetting(widget.conversationId, {'block': true});
    if (mounted) {
      setState(() => _isActionInProgress = false);
      Get.back();
    }
  }

  @override
  void dispose() {
    _chatController.stopMessagePolling();
    _chatController.messagesScrollController.removeListener(_onScroll);
    _messageSearchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final controller = _chatController.messagesScrollController;
    if (controller.hasClients && controller.position.pixels <= 50) {
      _chatController.loadMoreMessages();
    }
  }

  void _showEmojiPicker() {
    EmojiPickerSheet.show(context, (emoji) {
      _inputKey.currentState?.insertEmoji(emoji);
    });
  }

  void _showChatInfo() {
    if (_chatController.activeChatKind == 'room') {
      RoomInfoSheet.show(context, roomId: widget.conversationId, chatController: _chatController);
      return;
    }
    final conv = _chatController.conversations
        .firstWhereOrNull((c) => c.id == widget.conversationId);

    ChatInfoSheet.show(
      context,
      conversationId: widget.conversationId,
      user: widget.user,
      settings: conv?.settings ?? {},
      chatController: _chatController,
    );
  }

  Color _getThemeColor() {
    final conv = _chatController.conversations
        .firstWhereOrNull((c) => c.id == widget.conversationId);
    final theme = conv?.settings['theme'] as String?;

    switch (theme) {
      case 'theme-berry':
        return const Color(0xFFff4b7d);
      case 'theme-purple':
        return const Color(0xFFa335ee);
      case 'theme-ocean':
        return const Color(0xFF00cec9);
      case 'theme-orange':
        return const Color(0xFFe67e22);
      default:
        return AppColors.primary;
    }
  }

  String _getQuickEmoji() {
    final conv = _chatController.conversations
        .firstWhereOrNull((c) => c.id == widget.conversationId);
    return (conv?.settings['emoji'] as String?) ?? '👍';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.isDark ? AppColors.background : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Message search bar
          if (_showMessageSearch) _buildMessageSearchBar(),

          // Messages
          Expanded(
            child: Obx(() {
              if (_chatController.isMessagesLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = _chatController.messages;

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'no_messages_yet'.tr,
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }

              return _buildMessageList(messages);
            }),
          ),

          // Input area or Request banner
          Obx(() {
            if (_isPendingRequest) {
              return _buildRequestActionsBanner();
            }

            final isBlockedByMe = _chatController.isBlockedByMe(widget.conversationId);
            final isBlockedByOther = _chatController.isBlockedByOther(widget.conversationId, widget.user.id);

            if (_currentConversation?.isRoom == true && !_chatController.activeCanPost) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.textSecondary.withValues(alpha: 0.12),
                      child: Icon(Icons.volume_off_rounded, color: AppColors.textSecondary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'channel_read_only'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'channel_read_only_hint'.tr,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (isBlockedByMe || isBlockedByOther) {
              String message = 'messages_cannot_be_sent_to_user'.tr;
              if (isBlockedByMe && !isBlockedByOther) {
                message = 'you_have_blocked_this_user'.tr;
              } else if (isBlockedByOther && !isBlockedByMe) {
                message = 'user_blocked_you_or_unavailable'.tr;
              } else if (isBlockedByMe && isBlockedByOther) {
                message = 'both_blocked_each_other'.tr;
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border(top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1))),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return ChatInput(
              key: _inputKey,
              showGifts: _chatController.activeChatKind != 'room',
              onSend: (body, attachment, {bool viewOnce = false, bool isVoiceNote = false, int? voiceDuration}) {
                _chatController.sendMessage(
                  body: body,
                  attachment: attachment,
                  viewOnce: viewOnce,
                  isVoiceNote: isVoiceNote,
                  voiceDuration: voiceDuration,
                );
              },
              onEmojiTap: _showEmojiPicker,
              quickEmoji: _getQuickEmoji(),
            );
          }),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.cardBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          color: AppColors.textMain,
          size: 24,
        ),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          CustomAvatar(
            avatarUrl: widget.user.avatar,
            name: widget.user.name,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  // Check for nickname
                  final conv = _chatController.conversations
                      .firstWhereOrNull((c) => c.id == widget.conversationId);
                  final displayName =
                      conv?.settings['nickname_${widget.user.id}'] as String? ??
                          widget.user.name;
                  return Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      if (widget.user.profileType != null &&
                          widget.user.profileType != 'user') ...[
                        const SizedBox(width: 4),
                        ProfessionalBadge(
                          profileType: widget.user.profileType,
                          size: 16,
                        ),
                      ],
                    ],
                  );
                }),
              if (_chatController.activeChatKind == 'room')
                Text(
                  _chatController.activeRoomType == 'channel'
                      ? 'channel_info'.tr
                      : 'group_info'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Obx(() {
                  if (_chatController.otherUserTyping.value) {
                    return Text('typing'.tr, style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600));
                  }
                  return Text(
                    widget.user.isOnline ? 'online'.tr : 'offline'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.user.isOnline
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    ),
      actions: [
        if (!_isPendingRequest && _chatController.activeChatKind != 'room') ...[
          Obx(() {
            final callCtrl = Get.put(CallController(), permanent: true);
            if (!callCtrl.voiceEnabled.value) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(
                Icons.call_rounded,
                color: Colors.green,
                size: 22,
              ),
              onPressed: () {
                callCtrl.initiateCall(
                  receiverId: widget.user.id,
                  type: 'voice',
                  conversationId: widget.conversationId,
                  receiverName: widget.user.name,
                  receiverAvatar: widget.user.avatar,
                );
              },
            );
          }),
          Obx(() {
            final callCtrl = Get.put(CallController(), permanent: true);
            if (!callCtrl.videoEnabled.value) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                Icons.videocam_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              onPressed: () {
                callCtrl.initiateCall(
                  receiverId: widget.user.id,
                  type: 'video',
                  conversationId: widget.conversationId,
                  receiverName: widget.user.name,
                  receiverAvatar: widget.user.avatar,
                );
              },
            );
          }),
        ],
        IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _showMessageSearch = !_showMessageSearch;
              if (!_showMessageSearch) {
                _messageSearchController.clear();
                _chatController.openConversation(
                    widget.conversationId, widget.user);
              }
            });
          },
        ),
        IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: _showChatInfo,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          bottom: BorderSide(
            color: AppColors.isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageSearchController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'search_in_conversation'.tr,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                filled: true,
                fillColor: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) {
                if (val.isEmpty) {
                  _chatController.openConversation(
                      widget.conversationId, widget.user);
                } else {
                  _chatController.searchMessages(val);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _showMessageSearch = false;
                _messageSearchController.clear();
                _chatController.openConversation(
                    widget.conversationId, widget.user);
              });
            },
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessageModel> messages) {
    return Obx(() {
      final themeColor = _getThemeColor();

      return ListView.builder(
        controller: _chatController.messagesScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: messages.length + (_chatController.isMoreLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at top
          if (_chatController.isMoreLoading.value && index == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final msgIndex =
              _chatController.isMoreLoading.value ? index - 1 : index;
          final msg = messages[msgIndex];

          // Date divider
          Widget? dateDivider;
          if (msgIndex == 0 ||
              messages[msgIndex].date != messages[msgIndex - 1].date) {
            dateDivider = MessageDateDivider(date: msg.date);
          }

          // Show avatar if first in group or different sender
          final showAvatar = msgIndex == 0 ||
              messages[msgIndex - 1].senderId != msg.senderId ||
              messages[msgIndex].date != messages[msgIndex - 1].date;

          return Column(
            children: [
              if (dateDivider != null) dateDivider,
              MessageBubble(
                message: msg,
                showAvatar: showAvatar,
                showSenderName: _chatController.activeChatKind == 'room' &&
                    !msg.isMine &&
                    showAvatar,
                themeColor: themeColor,
                onLongPress: () => _showMessageActions(msg),
                onSwipeReply: () => _chatController.setReply(msg),
                onOpenViewOnce: () => _openViewOnce(msg),
                onImageTap: msg.attachment != null &&
                        msg.attachmentType == 'image' &&
                        !msg.viewOnce &&
                        !msg.isOptimistic
                    ? () => ImageLightbox.show(context, msg.attachment!)
                    : null,
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _openViewOnce(ChatMessageModel msg) async {
    if (msg.id is! int || msg.viewOnceOpened && !msg.isMine) return;
    final data = await _chatController.openViewOnce(msg.id as int);
    if (data == null || !mounted) return;
    final url = data['url']?.toString();
    if (url == null || url.isEmpty) return;
    final type = data['attachment_type']?.toString() ?? msg.attachmentType ?? 'image';
    await showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(child: _viewOnceMedia(type, url)),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!msg.isMine) _chatController.markViewOnceOpened(msg.id as int);
  }

  Widget _viewOnceMedia(String type, String url) {
    if (type == 'video') {
      return VideoPlayerWidget(videoUrl: url, autoPlay: true);
    }
    if (type == 'voice' || type == 'audio') {
      return _ViewOnceAudio(url: url);
    }
    return InteractiveViewer(child: Image.network(url));
  }

  void _showMessageActions(ChatMessageModel msg) {
    if (msg.id is! int || msg.isDeleted) return;
    final id = msg.id as int;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text('reply'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _chatController.setReply(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: Text('react'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _pickReaction(id);
              },
            ),
            if (msg.isMine && (msg.attachmentType == null || msg.attachmentType!.isEmpty) && (msg.body ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('edit_message'.tr),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(id, msg.body ?? '');
                },
              ),
            if (!msg.viewOnce && msg.attachmentType != 'gift')
              ListTile(
                leading: const Icon(Icons.forward),
                title: Text('forward'.tr),
                onTap: () {
                  Navigator.pop(ctx);
                  _forwardMessage(id);
                },
              ),
            if ((msg.body ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text('copy_text'.tr),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.body!));
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text('delete_for_me'.tr, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(id, 'me');
              },
            ),
            if (msg.isMine)
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: Text('delete_for_everyone'.tr, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(id, 'everyone');
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickReaction(int messageId) {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis
              .map((e) => IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _chatController.reactToMessage(messageId, e);
                    },
                    icon: Text(e, style: const TextStyle(fontSize: 28)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _editMessage(int messageId, String current) {
    final controller = TextEditingController(text: current);
    Get.dialog(AlertDialog(
      title: Text('edit_message'.tr),
      content: TextField(controller: controller, maxLines: 4),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        TextButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) _chatController.editMessage(messageId, text);
            Get.back();
          },
          child: Text('save'.tr),
        ),
      ],
    ));
  }

  void _confirmDelete(int messageId, String scope) {
    Get.dialog(AlertDialog(
      title: Text('delete'.tr),
      content: Text(scope == 'me' ? 'delete_message_for_me_confirm'.tr : 'delete_message_for_everyone_confirm'.tr),
      actions: [
        TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
        TextButton(
          onPressed: () {
            Get.back();
            _chatController.deleteMessage(messageId, scope: scope);
          },
          child: Text('delete'.tr),
        ),
      ],
    ));
  }

  void _forwardMessage(int messageId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _ForwardPickerSheet(
        messageId: messageId,
        chatController: _chatController,
      ),
    );
  }

  Widget _buildRequestActionsBanner() {
    final isSpam = _isSpamRequest;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSpam
                  ? 'spam_request_notice'.tr
                  : 'message_request_notice'.trParams({'name': widget.user.name}),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (_isActionInProgress)
              const SizedBox(
                height: 38,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleBlock,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMain,
                        side: BorderSide(
                          color: AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(
                        'block'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(
                        'delete'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(
                        'accept'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ForwardPickerSheet extends StatefulWidget {
  final int messageId;
  final ChatController chatController;

  const _ForwardPickerSheet({
    required this.messageId,
    required this.chatController,
  });

  @override
  State<_ForwardPickerSheet> createState() => _ForwardPickerSheetState();
}

class _ForwardPickerSheetState extends State<_ForwardPickerSheet> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  bool _forwarding = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadTargets('');
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _loadTargets(_search.text.trim());
    });
  }

  int? _parseUserId(Map<String, dynamic> user) {
    final id = user['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _loadTargets(String query) async {
    setState(() => _loading = true);
    try {
      _users = await ChatService().searchUsers(query);
    } catch (_) {
      _users = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _forwardTo(int userId) async {
    if (_forwarding) return;
    setState(() => _forwarding = true);
    final ok = await widget.chatController.forwardMessage(widget.messageId, [userId]);
    if (!mounted) return;
    setState(() => _forwarding = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
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
                    Text('forward'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'forward_targets_hint'.tr,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'search_friends_or_chats'.tr,
                        prefixIcon: const Icon(Icons.search, size: 22),
                        filled: true,
                        fillColor: AppColors.isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              if (_forwarding)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _users.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'no_forward_targets'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _users.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                            itemBuilder: (_, i) {
                              final u = _users[i];
                              final userId = _parseUserId(u);
                              if (userId == null) return const SizedBox.shrink();
                              final source = u['source']?.toString() ?? 'chat';
                              final badge = source == 'friend' ? 'friend_badge'.tr : 'chat_badge'.tr;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                leading: CustomAvatar(
                                  avatarUrl: u['avatar']?.toString(),
                                  name: u['name']?.toString() ?? '',
                                  radius: 20,
                                ),
                                title: Text(
                                  u['name']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: u['username'] != null && u['username'].toString().isNotEmpty
                                    ? Text('@${u['username']}', maxLines: 1, overflow: TextOverflow.ellipsis)
                                    : null,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    badge,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ),
                                onTap: _forwarding ? null : () => _forwardTo(userId),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewOnceAudio extends StatefulWidget {
  final String url;
  const _ViewOnceAudio({required this.url});

  @override
  State<_ViewOnceAudio> createState() => _ViewOnceAudioState();
}

class _ViewOnceAudioState extends State<_ViewOnceAudio> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    final streamUrl = UrlUtils.mediaStreamUrl(widget.url);
    _player.play(UrlSource(streamUrl, mimeType: 'audio/mp4'));
    _player.onPlayerComplete.listen((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.graphic_eq, color: Colors.white, size: 72);
  }
}
