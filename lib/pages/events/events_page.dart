import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/events_controller.dart';
import '../../controllers/feature_controller.dart';
import '../../data/models/event_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';
import 'event_detail_page.dart';
import 'create_event_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EventsController());
    final authController = Get.find<AuthController>();
    final featureCtrl = Get.find<FeatureController>();

    final isBusiness = authController.user.value?.profileType == 'business';
    final eventsPermission = featureCtrl.getFeatureValue('events_creation_permission') ?? 'everyone';
    final canCreate = eventsPermission == 'everyone' || isBusiness;

    return DefaultTabController(
      length: canCreate ? 3 : 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
            onPressed: () => Get.back(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('events'.tr, style: AppTextStyles.h3),
              Text('discover_whats_happening'.tr,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'discover'.tr),
              Tab(text: 'attending'.tr),
              if (canCreate) Tab(text: 'hosted_by_me'.tr),
            ],
          ),
        ),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: () => Get.to(() => const CreateEventPage()),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add, size: 20),
                label: Text('create_event'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              )
            : null,
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _DiscoverTab(controller: controller),
              _AttendingTab(controller: controller),
              if (canCreate) _HostedTab(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Discover Tab
// ═══════════════════════════════════════════

class _DiscoverTab extends StatelessWidget {
  final EventsController controller;
  const _DiscoverTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.discoverEvents.isEmpty) {
        return _buildEmptyState(
          icon: HugeIcons.strokeRoundedCalendar03,
          title: 'no_upcoming_events'.tr,
          subtitle: 'check_back_later_new_events'.tr,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshEvents,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              controller.loadMoreDiscover();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.discoverEvents.length + (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.discoverEvents.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(
                  event: controller.discoverEvents[index],
                  controller: controller,
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════
// Attending Tab
// ═══════════════════════════════════════════

class _AttendingTab extends StatelessWidget {
  final EventsController controller;
  const _AttendingTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.attendingEvents.isEmpty) {
        return _buildEmptyState(
          icon: HugeIcons.strokeRoundedCalendar03,
          title: 'you_arent_attending_any_events'.tr,
          subtitle: 'find_something_interesting_discover'.tr,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshEvents,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: controller.attendingEvents.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventCard(
                event: controller.attendingEvents[index],
                controller: controller,
              ),
            );
          },
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════
// Hosted Tab
// ═══════════════════════════════════════════

class _HostedTab extends StatelessWidget {
  final EventsController controller;
  const _HostedTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.hostedEvents.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text('you_havent_created_any_events'.tr, style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Text('start_hosting_events_audience'.tr,
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Get.to(() => const CreateEventPage()),
                icon: const Icon(Icons.add, size: 18),
                label: Text('create_first_event'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshEvents,
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              controller.loadMoreHosted();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.hostedEvents.length + (controller.isHostedLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == controller.hostedEvents.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(
                  event: controller.hostedEvents[index],
                  controller: controller,
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════
// Event Card Widget
// ═══════════════════════════════════════════

class _EventCard extends StatelessWidget {
  final EventModel event;
  final EventsController controller;
  const _EventCard({required this.event, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isCancelled = event.status == 'cancelled';

    return GestureDetector(
      onTap: () => Get.to(() => EventDetailPage(eventId: event.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: event.coverImage != null
                      ? CustomNetworkImage(
                          imageUrl: event.coverImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 160,
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 48,
                            ),
                          ),
                        ),
                ),
                // Type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      event.type == 'online' ? 'online'.tr : 'in_person'.tr,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                  ),
                ),
                // Price badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.isPaid ? Colors.amber.shade700 : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      event.isPaid
                          ? '${event.currencySymbol}${event.ticketPrice.toStringAsFixed(2)}'
                          : 'free'.tr.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                // Category badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      event.category ?? 'event'.tr,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
                // Cancelled overlay
                if (isCancelled)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'cancelled'.tr.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        '${event.startDateFormatted ?? ''} • ${event.startTimeFormatted ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    event.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Host
                  Row(
                    children: [
                      Text(
                        '${'hosted_by'.tr} ',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        event.host?.name ?? 'unknown'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  // Location / Link
                  if (event.type == 'in_person' && event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Description preview
                  if (event.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Footer: counts + RSVP buttons
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Going count
                        _CountBadge(
                          icon: Icons.check_circle_outline,
                          count: event.goingCount,
                          label: 'going'.tr,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        // Interested count
                        _CountBadge(
                          icon: Icons.star_outline,
                          count: event.interestedCount,
                          label: 'interested'.tr,
                          color: const Color(0xFFF59E0B),
                        ),
                        const Spacer(),
                        // RSVP buttons
                        if (!isCancelled && event.startDate.isAfter(DateTime.now())) ...[
                          _RsvpButton(
                            label: 'going'.tr,
                            isActive: event.userStatus == 'going',
                            isPrimary: true,
                            onTap: () {
                              final newStatus = event.userStatus == 'going' ? 'none' : 'going';
                              controller.toggleRsvp(event.id, newStatus);
                            },
                          ),
                          const SizedBox(width: 6),
                          _RsvpButton(
                            label: 'interested'.tr,
                            isActive: event.userStatus == 'interested',
                            isPrimary: false,
                            onTap: () {
                              final newStatus = event.userStatus == 'interested' ? 'none' : 'interested';
                              controller.toggleRsvp(event.id, newStatus);
                            },
                          ),
                        ],
                      ],
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
}

// ═══════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _CountBadge({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isPrimary;
  final VoidCallback onTap;

  const _RsvpButton({
    required this.label,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive
                ? Colors.white
                : (isPrimary ? AppColors.primary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

Widget _buildEmptyState({
  required dynamic icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HugeIcon(
          icon: icon,
          color: AppColors.textSecondary.withValues(alpha: 0.4),
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
      ],
    ),
  );
}
