import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../data/models/notification_model.dart';
import '../data/services/notification_service.dart';
import 'dart:async';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();

  // Observable states
  var notifications = <NotificationModel>[].obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs;
  var unreadCount = 0.obs;
  var msgUnreadCount = 0.obs;
  var filter = 'all'.obs;
  
  // Pagination
  int currentPage = 1;
  bool canLoadMore = true;

  // Polling
  Timer? _pollingTimer;
  bool _isPolling = false;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    startPolling();
    
    // Setup infinite scroll
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        loadMore();
      }
    });
  }

  @override
  void onClose() {
    stopPolling();
    scrollController.dispose();
    super.onClose();
  }

  /// Initial load or refresh
  Future<void> loadNotifications({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    currentPage = 1;
    canLoadMore = true;

    try {
      final result = await _service.getNotifications(currentPage, filter: filter.value);
      notifications.assignAll(result['items']);
      canLoadMore = result['nextPageUrl'] != null;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load next page
  Future<void> loadMore() async {
    if (isMoreLoading.value || !canLoadMore) return;

    isMoreLoading.value = true;
    currentPage++;

    try {
      final result = await _service.getNotifications(currentPage, filter: filter.value);
      notifications.addAll(result['items']);
      canLoadMore = result['nextPageUrl'] != null;
    } catch (e) {
      currentPage--;
      debugPrint('Error loading more notifications: $e');
    } finally {
      isMoreLoading.value = false;
    }
  }

  /// Change filter and reload
  void changeFilter(String newFilter) {
    if (filter.value == newFilter) return;
    filter.value = newFilter;
    loadNotifications();
  }

  /// Start long-polling for counts
  void startPolling() async {
    if (_isPolling) return;
    _isPolling = true;
    _poll();
  }

  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
  }

  Future<void> _poll() async {
    if (!_isPolling) return;

    try {
      // Long-poll request (or immediate if count changed)
      final counts = await _service.getCounts(
        lastCount: unreadCount.value,
        lastMsgCount: msgUnreadCount.value,
      );

      unreadCount.value = counts.count;
      msgUnreadCount.value = counts.msgCount;

      if (_isPolling) {
        if (counts.mode == 'poll') {
          // Local/Dev mode: wait 10 seconds to avoid blocking single-threaded server
          Future.delayed(const Duration(seconds: 10), () => _poll());
        } else {
          // Production (long-poll): server will hold connection, so we can re-poll immediately
          _poll();
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
      // On error (timeout or other), wait then retry
      if (_isPolling) {
        Future.delayed(const Duration(seconds: 10), () => _poll());
      }
    }
  }

  /// Mark as read locally and on server
  Future<void> markAsRead(NotificationModel notification) async {
    if (!notification.isUnread) return;

    // Update locally
    int index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = NotificationModel(
        id: notification.id,
        type: notification.type,
        message: notification.message,
        actorName: notification.actorName,
        actorAvatar: notification.actorAvatar,
        actorUsername: notification.actorUsername,
        icon: notification.icon,
        iconColor: notification.iconColor,
        isUnread: false,
        time: notification.time,
        metadata: notification.metadata,
      );
    }
    
    // Decrement count if possible
    if (unreadCount.value > 0) unreadCount.value--;

    await _service.markAsRead(notification.id);
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    unreadCount.value = 0;
    loadNotifications(showLoading: false);
  }
}
