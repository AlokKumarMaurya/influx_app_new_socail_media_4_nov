import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../providers/api_client.dart';
import '../../controllers/call_controller.dart';
import '../../pages/user/notifications_page.dart';
import '../../pages/chat/conversations_page.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static bool _initialized = false;
  static String? _currentAppId;

  /// Initialize OneSignal with App ID fetched from backend API
  static Future<void> initialize(String appId) async {
    if (appId.trim().isEmpty) return;
    if (_initialized && _currentAppId == appId) return;

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      } else {
        OneSignal.Debug.setLogLevel(OSLogLevel.none);
      }

      OneSignal.initialize(appId.trim());
      _initialized = true;
      _currentAppId = appId.trim();

      // Request notification permissions
      await OneSignal.Notifications.requestPermission(true);

      // Handle notifications received in foreground
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final data = event.notification.additionalData;
        if (data != null && data['type'] == 'incoming_call') {
          if (Get.isRegistered<CallController>()) {
            Get.find<CallController>().handleIncomingPushCall(Map<String, dynamic>.from(data));
          }
        }
      });

      // Handle notification taps/clicks
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data == null) return;
        _handleNotificationNavigation(Map<String, dynamic>.from(data));
      });

      // Listen for subscription changes and sync player ID with backend
      OneSignal.User.pushSubscription.addObserver((state) {
        final newId = state.current.id;
        if (newId != null && newId.isNotEmpty) {
          PushNotificationService().registerDevice(newId);
        }
      });

      // If already has player ID, sync it now
      final existingId = getPlayerId();
      if (existingId != null && existingId.isNotEmpty) {
        PushNotificationService().registerDevice(existingId);
      }
    } catch (e) {
      debugPrint('OneSignal initialization failed: $e');
    }
  }

  /// Navigate to corresponding page when a notification is tapped
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final type = data['type']?.toString();
      if (type == 'incoming_call') {
        if (Get.isRegistered<CallController>()) {
          Get.find<CallController>().handleIncomingPushCall(data);
        }
        Get.to(() => const ConversationsPage());
      } else if (type == 'chat_message' || type == 'missed_call') {
        Get.to(() => const ConversationsPage());
      } else {
        Get.to(() => const NotificationsPage());
      }
    } catch (e) {
      debugPrint('Error handling notification click: $e');
    }
  }

  /// Get current OneSignal subscription / player ID
  static String? getPlayerId() {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (e) {
      debugPrint('Error getting OneSignal subscription ID: $e');
      return null;
    }
  }

  /// Associate authenticated user ID with OneSignal
  static void setExternalUserId(String userId) {
    try {
      OneSignal.login(userId);
      final playerId = getPlayerId();
      if (playerId != null && playerId.isNotEmpty) {
        PushNotificationService().registerDevice(playerId);
      }
    } catch (e) {
      debugPrint('Error setting OneSignal external user ID: $e');
    }
  }

  /// Disassociate user upon logout
  static void removeExternalUserId() {
    try {
      OneSignal.logout();
    } catch (e) {
      debugPrint('Error logging out from OneSignal: $e');
    }
  }

  /// Register device subscription ID to backend API
  Future<bool> registerDevice(String playerId) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.post('/user/device', data: {
        'player_id': playerId,
      });

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error registering push device ID: $e');
      return false;
    }
  }
}
