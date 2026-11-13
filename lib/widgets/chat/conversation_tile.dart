import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../data/models/conversation_model.dart';
import '../../utils/app_theme.dart';
import '../common/custom_avatar.dart';
import '../common/professional_badge.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final bool isActive;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final isRoom = conversation.isRoom;

    // Check for nickname override
    final displayName = isRoom
        ? (conversation.roomTitle ?? conversation.user.name)
        : (conversation.settings['nickname_${conversation.user.id}'] as String? ?? conversation.user.name);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : (hasUnread ? AppColors.primary.withValues(alpha: 0.03) : Colors.transparent),
          border: Border(
            left: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CustomAvatar(
                  avatarUrl: conversation.user.avatar,
                  name: conversation.user.name,
                  radius: 26,
                  isOnline: conversation.user.isOnline,
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Row(
                    children: [
                      if (isRoom) ...[
                        Text(
                          conversation.roomType == 'channel' ? '📢' : '👥',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRoom &&
                          conversation.user.profileType != null &&
                          conversation.user.profileType != 'user') ...[
                        const SizedBox(width: 4),
                        ProfessionalBadge(
                          profileType: conversation.user.profileType,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Last message preview
                  if (conversation.lastMessage != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _buildPreview(),
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread
                                  ? AppColors.textMain
                                  : AppColors.textSecondary,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' · ${conversation.lastMessage!.time}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Unread dot
            if (hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildPreview() {
    final msg = conversation.lastMessage!;
    final prefix = msg.isMine ? 'You: ' : '';
    final type = msg.attachmentType;
    final body = (type != null && (msg.body == null || msg.body!.isEmpty))
        ? (type == 'image'
            ? '📷 Photo'
            : type == 'video'
                ? '🎥 Video'
                : type == 'gift'
                    ? '🎁 ${'gift'.tr}'
                    : type == 'location'
                        ? '📍 ${'shared_location'.tr}'
                        : (type == 'voice' || type == 'audio')
                            ? '🎤 ${'voice_note'.tr}'
                            : '📎 File')
        : (msg.body ?? '');
    return '$prefix$body';
  }
}
