import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/events_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../data/models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';
import '../../data/models/user_model.dart';
import '../../data/services/post_service.dart';
import 'create_event_page.dart';

class EventDetailPage extends StatelessWidget {
  final int eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<EventsController>()
        ? Get.find<EventsController>()
        : Get.put(EventsController());
    controller.loadEventDetail(eventId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final event = controller.currentEvent.value;
        if (event == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedAlert01, color: AppColors.textSecondary, size: 48),
                const SizedBox(height: 16),
                Text('event_not_found'.tr, style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: Text('go_back'.tr),
                ),
              ],
            ),
          );
        }

        final isOwner = Get.find<AuthController>().user.value?.id == event.host?.id;
        final isCancelled = event.status == 'cancelled';
        final isUpcoming = event.startDate.isAfter(DateTime.now());

        return CustomScrollView(
          slivers: [
            // Cover Hero
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.cardBg,
              leading: IconButton(
                onPressed: () => Get.back(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => _showInviteDialog(context, controller, event),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                  ),
                ),
                if (isOwner) ...[
                  IconButton(
                    onPressed: () => Get.to(() => CreateEventPage(editEvent: event)),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteDialog(context, controller, event),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    event.coverImage != null
                        ? CustomNetworkImage(
                            imageUrl: event.coverImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 300,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Cancelled badge
                    if (isCancelled)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 12),
                            ],
                          ),
                          child: Text(
                            'cancelled'.tr.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                    // Title overlay
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  event.category ?? 'event'.tr,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  event.type == 'online' ? 'online'.tr : 'in_person'.tr,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: event.isPaid ? Colors.amber.shade700 : Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Text(
                                  event.isPaid
                                      ? '${'paid'.tr.toUpperCase()} ${event.currencySymbol}${event.ticketPrice.toStringAsFixed(2)}'
                                      : 'free'.tr.toUpperCase(),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${'hosted_by'.tr} ',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                              ),
                              Text(
                                event.host?.name ?? 'unknown'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info cards row
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.access_time,
                            title: 'date_and_time'.tr,
                            value: '${event.startDateFormatted ?? ''}\n${event.startTimeFormatted ?? ''}${event.endTimeFormatted != null ? ' - ${event.endTimeFormatted}' : ''}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            icon: event.type == 'online' ? Icons.videocam : Icons.location_on,
                            title: event.type == 'online' ? 'meeting_link'.tr : 'location'.tr,
                            value: event.type == 'online'
                                ? (event.canAccessMaterials || isOwner
                                    ? (event.link ?? 'no_link'.tr)
                                    : 'ticket_required_access_link'.tr)
                                : (event.location ?? 'no_location'.tr),
                            isLink: event.type == 'online' && (event.canAccessMaterials || isOwner),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // RSVP / Buy Ticket section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          _StatItem(count: event.goingCount, label: 'going'.tr, color: AppColors.primary),
                          const SizedBox(width: 30),
                          _StatItem(count: event.interestedCount, label: 'interested'.tr, color: AppColors.textMain),
                          const Spacer(),
                          if (!isCancelled && isUpcoming) ...[
                            if (event.isPaid && !event.canAccessMaterials && !isOwner) ...[
                              ElevatedButton.icon(
                                onPressed: () => _confirmBuyTicket(context, controller, event),
                                icon: const Icon(Icons.shopping_bag, size: 16),
                                label: Text('${'buy_ticket'.tr} (${event.currencySymbol}${event.ticketPrice.toStringAsFixed(2)})'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ] else ...[
                              _DetailRsvpButton(
                                label: 'going'.tr,
                                icon: Icons.check_circle,
                                isActive: event.userStatus == 'going',
                                isPrimary: true,
                                onTap: () {
                                  final newStatus = event.userStatus == 'going' ? 'none' : 'going';
                                  controller.toggleRsvp(event.id, newStatus);
                                },
                              ),
                              const SizedBox(width: 8),
                              _DetailRsvpButton(
                                label: 'interested'.tr,
                                icon: Icons.star,
                                isActive: event.userStatus == 'interested',
                                isPrimary: false,
                                onTap: () {
                                  final newStatus = event.userStatus == 'interested' ? 'none' : 'interested';
                                  controller.toggleRsvp(event.id, newStatus);
                                },
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    Text('about_this_event'.tr,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                    const SizedBox(height: 12),
                    Text(
                      event.description ?? 'no_description_available'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                    ),

                    // Event Materials & Manuals Section
                    if (event.materials != null && event.materials!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.menu_book, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'event_materials_manuals'.tr,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (event.canAccessMaterials || isOwner) ...[
                              Column(
                                children: event.materials!.map((mat) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          mat.fileType == 'image' ? Icons.image : Icons.picture_as_pdf,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            mat.title,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (mat.fileUrl != null)
                                          IconButton(
                                            icon: Icon(Icons.download, color: AppColors.primary, size: 20),
                                            onPressed: () async {
                                              final uri = Uri.parse(mat.fileUrl!);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              }
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, color: Colors.amber.shade900, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'event_materials_locked_desc'.tr,
                                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Attendees
                    if (event.attendees != null && event.attendees!.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${'attendees'.tr} (${event.attendees!.length})',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: event.attendees!.map((attendee) {
                                return Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      backgroundImage: attendee.avatar != null
                                          ? NetworkImage(attendee.avatar!)
                                          : null,
                                      child: attendee.avatar == null
                                          ? Text(
                                              attendee.name.isNotEmpty ? attendee.name[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        attendee.name.length > 8
                                            ? '${attendee.name.substring(0, 8)}...'
                                            : attendee.name,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMain),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                      ),
                                    ),
                                    Text(
                                      attendee.status == 'going' ? 'going'.tr : (attendee.status == 'interested' ? 'interested'.tr : attendee.status),
                                      style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _confirmBuyTicket(BuildContext context, EventsController controller, EventModel event) {
    final walletCtrl = Get.isRegistered<WalletController>() ? Get.find<WalletController>() : Get.put(WalletController());
    final userWallet = walletCtrl.balance.value;
    final hasEnough = userWallet >= event.ticketPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shopping_bag, color: Colors.amber.shade900, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('confirm_ticket_purchase'.tr,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      const SizedBox(height: 2),
                      Text('unlock_full_access_event_materials'.tr,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('event_name'.tr, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Expanded(
                        child: Text(
                          event.name,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ticket_fee'.tr, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        '${event.currencySymbol}${event.ticketPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('your_wallet_balance'.tr, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        '${event.currencySymbol}${userWallet.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!hasEnough) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'insufficient_wallet_balance_event'.tr,
                        style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: hasEnough
                    ? () async {
                        Navigator.pop(ctx);
                        await controller.buyTicket(event.id);
                      }
                    : null,
                icon: const Icon(Icons.check_circle, size: 18),
                label: Text('confirm_and_pay'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, EventsController controller, EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InviteFriendsBottomSheet(
        eventId: event.id,
        onSendInvites: (selectedIds) async {
          await controller.inviteUsers(event.id, selectedIds);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, EventsController controller, EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('delete_event'.tr),
        content: Text('delete_event_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await controller.deleteEvent(event.id);
              if (success) {
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Detail Sub-Widgets
// ═══════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isLink;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: isLink ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isLink ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatItem({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _DetailRsvpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isPrimary;
  final VoidCallback onTap;

  const _DetailRsvpButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isPrimary ? AppColors.primary : const Color(0xFF6B7280))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : (isPrimary ? AppColors.primary : const Color(0xFF9CA3AF)),
            width: 1.2,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: (isPrimary ? AppColors.primary : const Color(0xFF6B7280)).withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.white
                  : (isPrimary ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : (isPrimary ? AppColors.primary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteFriendsBottomSheet extends StatefulWidget {
  final int eventId;
  final Function(List<int>) onSendInvites;

  const _InviteFriendsBottomSheet({
    required this.eventId,
    required this.onSendInvites,
  });

  @override
  State<_InviteFriendsBottomSheet> createState() => _InviteFriendsBottomSheetState();
}

class _InviteFriendsBottomSheetState extends State<_InviteFriendsBottomSheet> {
  final PostService _postService = PostService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<UserModel> _filteredFriends = [];
  final Set<int> _selectedUserIds = {};
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      final list = await _postService.searchUsers(query, friendsOnly: true);
      if (mounted) {
        setState(() {
          _filteredFriends = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String val) {
    _loadFriends(val.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'invite_friends'.tr,
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
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: TextStyle(fontSize: 14, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'search_friends'.tr,
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadFriends('');
                      },
                    )
                  : null,
              fillColor: AppColors.background,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'no_friends_to_invite'.tr
                              : 'no_results_found'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredFriends.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
                        ),
                        itemBuilder: (context, index) {
                          final user = _filteredFriends[index];
                          final isSelected = _selectedUserIds.contains(user.id);
                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedUserIds.add(user.id);
                                } else {
                                  _selectedUserIds.remove(user.id);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                                  ? NetworkImage(user.avatar!)
                                  : null,
                              child: (user.avatar == null || user.avatar!.isEmpty)
                                  ? Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                            subtitle: Text(
                              user.username != null && user.username!.isNotEmpty ? '@${user.username}' : '',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedUserIds.isEmpty || _isSending
                  ? null
                  : () async {
                      setState(() => _isSending = true);
                      Navigator.pop(context);
                      await widget.onSendInvites(_selectedUserIds.toList());
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _selectedUserIds.isEmpty
                          ? 'select_friends_to_invite'.tr
                          : '${'send_invites'.tr} (${_selectedUserIds.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
