import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/conversation_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_avatar.dart';
import '../user/profile_page.dart';

class ChatInfoSheet extends StatefulWidget {
  final int conversationId;
  final ChatUser user;
  final Map<String, dynamic> settings;
  final ChatController chatController;

  const ChatInfoSheet({
    super.key,
    required this.conversationId,
    required this.user,
    required this.settings,
    required this.chatController,
  });

  static void show(
    BuildContext context, {
    required int conversationId,
    required ChatUser user,
    required Map<String, dynamic> settings,
    required ChatController chatController,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatInfoSheet(
        conversationId: conversationId,
        user: user,
        settings: settings,
        chatController: chatController,
      ),
    );
  }

  @override
  State<ChatInfoSheet> createState() => _ChatInfoSheetState();
}

class _ChatInfoSheetState extends State<ChatInfoSheet> {
  late Map<String, dynamic> _settings;
  final TextEditingController _nicknameController = TextEditingController();

  static const Map<String, Color> _themes = {
    'default': Color(0xFF0084FF),
    'theme-berry': Color(0xFFFF4B7D),
    'theme-purple': Color(0xFFA335EE),
    'theme-ocean': Color(0xFF00CEC9),
    'theme-orange': Color(0xFFE67E22),
  };

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.settings);
    _nicknameController.text =
        _settings['nickname_${widget.user.id}'] as String? ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _updateTheme(String theme) {
    setState(() => _settings['theme'] = theme);
    widget.chatController.updateSetting(
      widget.conversationId,
      {'theme': theme},
    );
  }

  void _updateNickname() {
    final name = _nicknameController.text.trim();
    widget.chatController.updateSetting(
      widget.conversationId,
      {
        'nickname': name.isEmpty ? null : name,
        'target_user_id': widget.user.id,
      },
    );
    Get.back();
  }

  void _showMuteOptions() {
    final myId = widget.chatController.currentUserId;
    final until = _settings['muted_until_$myId'];
    final muted = until != null && until.toString().isNotEmpty;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (muted)
              ListTile(
                title: Text('unmute_notifications'.tr),
                onTap: () async {
                  Navigator.pop(ctx);
                  await widget.chatController.unmuteConversation();
                },
              ),
            ListTile(title: Text('mute_8h'.tr), onTap: () => _mute(ctx, '8h')),
            ListTile(title: Text('mute_1w'.tr), onTap: () => _mute(ctx, '1w')),
            ListTile(title: Text('mute_forever'.tr), onTap: () => _mute(ctx, 'forever')),
          ],
        ),
      ),
    );
  }

  Future<void> _mute(BuildContext ctx, String duration) async {
    Navigator.pop(ctx);
    await widget.chatController.muteConversation(duration);
    if (mounted) {
      setState(() => _settings['muted_until_${widget.chatController.currentUserId}'] = duration);
    }
  }

  void _toggleBlock() {
    final myId = widget.chatController.currentUserId;
    final key = 'blocked_by_$myId';
    final isBlocked = _settings[key] == true;
    
    widget.chatController.updateSetting(
      widget.conversationId,
      {'block': !isBlocked},
    );
    setState(() => _settings[key] = !isBlocked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // User info
                  _buildUserInfo(),
                  const SizedBox(height: 24),

                  // Theme picker
                  _buildSection(
                    'chat_theme'.tr,
                    _buildThemePicker(),
                  ),
                  const SizedBox(height: 20),

                  // Nickname
                  _buildSection(
                    'nickname'.tr,
                    _buildNicknameSetting(),
                  ),
                  const SizedBox(height: 20),

                  // Quick Emoji
                  _buildSection(
                    'quick_reply_emoji'.tr,
                    _buildQuickEmojiSetting(),
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_off_outlined),
                    title: Text('mute_notifications'.tr),
                    onTap: _showMuteOptions,
                  ),
                  const SizedBox(height: 12),

                  // Actions
                  _buildDangerSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        CustomAvatar(
          avatarUrl: widget.user.avatar,
          name: widget.user.name,
          radius: 40,
        ),
        const SizedBox(height: 12),
        Text(
          widget.user.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        if (widget.user.username != null && widget.user.username!.isNotEmpty)
          Text(
            '@${widget.user.username}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            Get.back(); // Close sheet
            Get.to(() => ProfilePage(userId: widget.user.id));
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'view_profile'.tr,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildThemePicker() {
    final currentTheme = _settings['theme'] as String? ?? 'default';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _themes.entries.map((e) {
        final isSelected = e.key == currentTheme;
        return GestureDetector(
          onTap: () => _updateTheme(e.key),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: e.value,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.textMain, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: e.value.withValues(alpha: 0.4), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNicknameSetting() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _nicknameController,
            style: TextStyle(fontSize: 14, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'set_nickname_hint'.tr,
              hintStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onSubmitted: (_) => _updateNickname(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _updateNickname,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('save'.tr, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildQuickEmojiSetting() {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '🎉'];
    final current = _settings['emoji'] as String? ?? '👍';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: emojis.map((emoji) {
        final isSelected = emoji == current;
        return GestureDetector(
          onTap: () {
            setState(() => _settings['emoji'] = emoji);
            widget.chatController.updateSetting(
              widget.conversationId,
              {'emoji': emoji},
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDangerSection() {
    final blockKey = 'blocked_by_${widget.chatController.currentUserId}';
    final isBlocked = _settings[blockKey] == true;

    return Column(
      children: [
        const Divider(),
        ListTile(
          leading: Icon(
            isBlocked ? Icons.lock_open : Icons.block,
            color: AppColors.error,
          ),
          title: Text(
            isBlocked ? 'unblock_user'.tr : 'block_user'.tr,
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: _toggleBlock,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
          title: Text(
            'report_user'.tr,
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            final controller = TextEditingController();
            Get.dialog(
              AlertDialog(
                title: Text('report_user'.tr),
                content: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: 'reason_for_report'.tr),
                ),
                actions: [
                  TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
                  TextButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        widget.chatController.reportUser(widget.conversationId, controller.text);
                        Get.back();
                      }
                    },
                    child: Text('report'.tr),
                  ),
                ],
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: AppColors.error),
          title: Text(
            'delete_conversation'.tr,
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Get.dialog(
              AlertDialog(
                title: Text('delete_conversation'.tr),
                content: Text('delete_conversation_confirm'.tr),
                actions: [
                  TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
                  TextButton(
                    onPressed: () async {
                      final success = await widget.chatController.deleteConversation(widget.conversationId);
                      if (success) {
                        Get.back(); // Close dialog
                        Get.back(); // Close sheet
                        Get.back(); // Exit ChatPage back to list
                      }
                    },
                    child: Text('delete'.tr, style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
