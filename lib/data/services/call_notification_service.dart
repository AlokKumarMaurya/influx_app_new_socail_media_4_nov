import 'package:material_ui/material_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../utils/string_utils.dart';

class CallNotificationService {
  static final CallNotificationService _instance = CallNotificationService._internal();
  factory CallNotificationService() => _instance;
  CallNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const int _notificationId = 8888;
  static const int _incomingNotificationId = 9999;
  bool _isInitialized = false;

  Function()? onEndCallAction;
  Function()? onReturnCallAction;
  Function(int callId)? onAcceptCallAction;
  Function(int callId)? onDeclineCallAction;

  Future<void> init({
    Function()? onEndCall,
    Function()? onReturnCall,
    Function(int callId)? onAcceptCall,
    Function(int callId)? onDeclineCall,
  }) async {
    if (_isInitialized) return;
    onEndCallAction = onEndCall;
    onReturnCallAction = onReturnCall;
    onAcceptCallAction = onAcceptCall;
    onDeclineCallAction = onDeclineCall;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final actionId = response.actionId;
        final payloadCallId = int.tryParse(response.payload ?? '') ?? 0;

        if (actionId == 'action_end_call') {
          onEndCallAction?.call();
        } else if (actionId == 'action_accept_call') {
          onAcceptCallAction?.call(payloadCallId);
        } else if (actionId == 'action_decline_call') {
          onDeclineCallAction?.call(payloadCallId);
        } else {
          if (payloadCallId > 0 && onAcceptCallAction != null) {
            onAcceptCallAction?.call(payloadCallId);
          } else {
            onReturnCallAction?.call();
          }
        }
      },
    );

    _isInitialized = true;
  }

  Future<void> showIncomingCallNotification({
    required int callId,
    required String callerName,
    required String callType,
  }) async {
    final title = 'Incoming ${callType.capitalizeFirst} Call';
    final body = '$callerName is calling...';

    const androidDetails = AndroidNotificationDetails(
      'incoming_call_channel',
      'Incoming Call Alert',
      channelDescription: 'Pops up full screen incoming call alerts when app is in background',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      category: AndroidNotificationCategory.call,
      color: Color(0xFF10B981),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_accept_call',
          'Accept',
          titleColor: Color(0xFF10B981),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_decline_call',
          'Decline',
          titleColor: Color(0xFFEF4444),
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'incoming_call_category',
      ),
    );

    await _notificationsPlugin.show(
      _incomingNotificationId,
      title,
      body,
      notificationDetails,
      payload: callId.toString(),
    );
  }

  Future<void> showOngoingCallNotification({
    required String callerName,
    required String callType,
    required String statusOrDuration,
    required bool isConnected,
  }) async {
    // Dismiss incoming notification if active
    await dismissIncomingNotification();

    final title = isConnected
        ? 'Active ${callType.capitalizeFirst} Call'
        : 'Calling $callerName...';
    final body = '$callerName • $statusOrDuration';

    const androidDetails = AndroidNotificationDetails(
      'ongoing_call_channel',
      'Ongoing Calls',
      channelDescription: 'Displays active phone and video call status',
      importance: Importance.max,
      priority: Priority.max,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      category: AndroidNotificationCategory.call,
      color: Color(0xFF1877F2),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_return_call',
          'Return to Call',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_end_call',
          'End Call',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      ),
    );

    await _notificationsPlugin.show(
      _notificationId,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> dismissIncomingNotification() async {
    try {
      await _notificationsPlugin.cancel(_incomingNotificationId);
    } catch (_) {}
  }

  Future<void> dismissNotification() async {
    try {
      await _notificationsPlugin.cancel(_notificationId);
      await _notificationsPlugin.cancel(_incomingNotificationId);
    } catch (_) {}
  }
}
