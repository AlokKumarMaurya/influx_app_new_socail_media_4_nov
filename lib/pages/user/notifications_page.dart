import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../data/models/notification_model.dart';
import '../feed/single_post_page.dart';
import '../feed/group_details_page.dart';
import '../user/profile_page.dart';
import '../events/event_detail_page.dart';
import '../chat/conversations_page.dart';
import '../../widgets/common/professional_badge.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already initialized in MainScreen or we can put it here if not exist
    final NotificationController controller = Get.find<NotificationController>();

    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('notifications'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.primary),
            tooltip: 'mark_all_read'.tr,
            onPressed: () => _confirmMarkAllRead(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(controller),
          const Divider(height: 1),

          // Notifications List
          Expanded(
            child: controller.isLoading.value && controller.notifications.isEmpty
                ? _buildSkeletonList()
                : controller.notifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => controller.loadNotifications(showLoading: false),
                        child: ListView.builder(
                          controller: controller.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: controller.notifications.length + (controller.canLoadMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < controller.notifications.length) {
                              final notification = controller.notifications[index];
                              return _buildNotificationItem(notification, controller);
                            } else {
                              return _buildLoadMoreIndicator();
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    ));
  }

  Widget _buildFilterTabs(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Obx(() => Row(
        children: [
          _buildFilterChip(
            'all'.tr,
            controller.filter.value == 'all',
            () => controller.changeFilter('all'),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'unread'.tr,
            controller.filter.value == 'unread',
            () => controller.changeFilter('unread'),
          ),
        ],
      )),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMain,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, NotificationController controller) {
    final bool isSystemNotif = ['kyc_approved', 'kyc_rejected', 'business_approved', 'business_rejected'].contains(notification.type);

    return InkWell(
      onTap: () => _navigateNotification(notification, controller),
      child: Container(
        color: notification.isUnread ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Actor Avatar with Icon Overlay
            Stack(
              children: [
                CustomAvatar(avatarUrl: notification.actorAvatar, radius: 28),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getIconColor(notification.iconColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _getIconData(notification.icon),
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMain),
                      children: isSystemNotif
                          ? [
                              TextSpan(
                                text: notification.message,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ]
                          : [
                              TextSpan(
                                text: notification.actorName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (notification.actorProfileType != null && notification.actorProfileType != 'user')
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: ProfessionalBadge(profileType: notification.actorProfileType, size: 14),
                                  ),
                                ),
                              const TextSpan(text: ' '),
                              TextSpan(text: notification.message.replaceAll(notification.actorName, '').trim()),
                            ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        notification.time,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: notification.isUnread ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                      if (notification.isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'no_notifications_yet'.tr,
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonLoader(width: 56, height: 56, shape: BoxShape.circle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: Get.width * 0.7, height: 16, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  SkeletonLoader(width: 60, height: 12, borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateNotification(NotificationModel n, NotificationController controller) {
    final meta = n.metadata ?? {};
    final type = n.type;
    final int? notifiableId = meta['notifiable_id'];

    if (type.startsWith('post_')) {
      if (notifiableId != null) {
        Get.to(() => SinglePostPage(postId: notifiableId));
      }
    } else if (type == 'friend_request' || type == 'friend_accept') {
      final int? actorId = meta['actor_id'];
      if (actorId != null) {
        Get.to(() => ProfilePage(userId: actorId));
      }
    } else if (type.startsWith('group_')) {
      final int? groupId = meta['group_id'] ?? notifiableId;
      if (groupId != null) {
        Get.to(() => GroupDetailsPage(groupId: groupId));
      } else if (meta['group_slug'] != null) {
        // Fallback for older notifications if any
        Get.snackbar('group'.tr, '${'opening_group'.tr}: ${meta['group_slug']}', snackPosition: SnackPosition.BOTTOM);
      }
    } else if (type.startsWith('event_')) {
      final int? eventId = meta['event_id'] ?? notifiableId;
      if (eventId != null) {
        Get.to(() => EventDetailPage(eventId: eventId));
      }
    } else if (type == 'message' || type == 'missed_call') {
       Get.to(() => const ConversationsPage());
    } else if (type.startsWith('kyc_') || type.startsWith('business_')) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(type.startsWith('kyc_') ? 'identity_verification'.tr : 'business_upgrade'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(n.message),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('ok'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
    
    // Always mark as read when clicking
    controller.markAsRead(n);
  }

  void _confirmMarkAllRead(BuildContext context, NotificationController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('mark_all_as_read_question'.tr, style: AppTextStyles.h3),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.markAllRead();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('confirm'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'thumbs-up': return Icons.thumb_up_rounded;
      case 'message-square': return Icons.comment_rounded;
      case 'share-2': return Icons.share_rounded;
      case 'tag': return Icons.local_offer_rounded;
      case 'heart': return Icons.favorite_rounded;
      case 'user-plus': return Icons.person_add_rounded;
      case 'user-check': return Icons.how_to_reg_rounded;
      case 'users': return Icons.group_rounded;
      case 'check-circle': return Icons.check_circle_rounded;
      case 'mail': return Icons.mail_rounded;
      case 'shield': return Icons.shield_rounded;
      case 'x-circle': return Icons.cancel_rounded;
      case 'award': return Icons.workspace_premium_rounded;
      case 'slash': return Icons.block_flipped;
      case 'calendar': return Icons.calendar_today_rounded;
      case 'phone-missed': return Icons.phone_missed_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String color) {
    switch (color) {
      case 'primary': return Colors.blue;
      case 'info': return Colors.cyan;
      case 'success': return Colors.green;
      case 'warning': return Colors.orange;
      case 'danger': return Colors.red;
      default: return Colors.grey;
    }
  }
}
