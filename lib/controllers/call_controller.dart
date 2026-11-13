import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:influx_app/controllers/auth_controller.dart';
import 'package:influx_app/controllers/chat_controller.dart';
import 'package:influx_app/data/providers/api_client.dart';
import 'package:influx_app/data/services/call_notification_service.dart';
import 'package:influx_app/pages/chat/active_call_page.dart';
import 'package:influx_app/widgets/chat/incoming_call_dialog.dart';

class CallController extends GetxController with WidgetsBindingObserver {
  final ApiClient _apiClient = ApiClient();

  final RxBool voiceEnabled = true.obs;
  final RxBool videoEnabled = true.obs;
  final RxString agoraAppId = ''.obs;

  final RxBool hasActiveCall = false.obs;
  final RxBool isIncomingCall = false.obs;
  final RxBool isCallConnected = false.obs;
  final RxBool isMinimized = false.obs;
  final RxBool isMuted = false.obs;
  final RxBool isSpeakerOn = false.obs;
  final RxBool isCameraOff = false.obs;
  final RxBool isRemoteVideoMuted = false.obs;

  final RxInt activeCallId = 0.obs;
  final RxString channelName = ''.obs;
  final RxString callType = 'voice'.obs; // 'voice' or 'video'

  final RxInt remoteUid = 0.obs;
  final RxInt callDuration = 0.obs;

  final RxMap<String, dynamic> callerData = <String, dynamic>{}.obs;

  RtcEngine? rtcEngine;
  final CallNotificationService _notificationService = CallNotificationService();
  AudioPlayer? _audioPlayer;
  Timer? _pollingTimer;
  Timer? _durationTimer;
  bool _isDialogShowing = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchCallConfig();
    startActiveCallPolling();
    _notificationService.init(
      onEndCall: () => endCall(),
      onReturnCall: () => expandCall(),
      onAcceptCall: (callId) {
        _notificationService.dismissIncomingNotification();
        final targetId = callId > 0 ? callId : activeCallId.value;
        if (targetId > 0) {
          acceptCall(targetId);
        }
      },
      onDeclineCall: (callId) {
        _notificationService.dismissIncomingNotification();
        final targetId = callId > 0 ? callId : activeCallId.value;
        if (targetId > 0) {
          rejectCall(targetId);
        }
      },
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _durationTimer?.cancel();
    _stopRingtone();
    destroyEngine();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && hasActiveCall.value) {
      ensureWakelock();
    }
  }

  Future<void> ensureWakelock() async {
    if (!hasActiveCall.value) return;
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Error enabling wakelock: $e');
    }
  }

  Future<void> _playIncomingRingtone() async {
    try {
      await _stopRingtone();
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
      await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer?.play(AssetSource('audio/rington.mp3'));
    } catch (e) {
      Get.log('Error playing incoming ringtone: $e');
    }
  }

  Future<void> _playOutgoingRingtone() async {
    try {
      await _stopRingtone();
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playAndRecord,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
      await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer?.play(AssetSource('audio/outgoing_call_ring.mp3'));
    } catch (e) {
      Get.log('Error playing outgoing ringtone: $e');
    }
  }

  Future<void> _stopRingtone() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer?.stop();
        await _audioPlayer?.dispose();
        _audioPlayer = null;
      }
    } catch (_) {
      _audioPlayer = null;
    }
  }

  Future<void> fetchCallConfig() async {
    try {
      final response = await _apiClient.dio.get('/chat/call/config');
      if (response.data != null && response.data['status'] == 'success') {
        final data = response.data['data'];
        final vEnable = data['voice_enabled'];
        final vidEnable = data['video_enabled'];
        voiceEnabled.value = (vEnable == true || vEnable == 1 || vEnable == '1' || vEnable == 'true');
        videoEnabled.value = (vidEnable == true || vidEnable == 1 || vidEnable == '1' || vidEnable == 'true');
        agoraAppId.value = data['agora_app_id'] ?? '';
      }
    } catch (_) {}
  }

  void startActiveCallPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      checkActiveCall();
    });
  }

  Future<void> checkActiveCall() async {
    try {
      String url = '/chat/call/active';
      if (hasActiveCall.value && activeCallId.value > 0) {
        url += '?call_id=${activeCallId.value}';
      }

      final response = await _apiClient.dio.get(url);
      if (response.data != null && response.data['status'] == 'success') {
        final data = response.data;

        // If active call was terminated by other device
        if (data['is_terminated'] == true || (hasActiveCall.value && data['has_call'] == false)) {
          if (_isDialogShowing) {
            Get.back();
            _isDialogShowing = false;
          }
          _stopRingtone();
          endCall();
          return;
        }

        if (!hasActiveCall.value && data['has_call'] == true && data['is_incoming'] == true) {
          final callData = data['data'];
          activeCallId.value = callData['call_id'] ?? 0;
          channelName.value = callData['channel_name'] ?? '';
          callType.value = callData['call_type'] ?? 'voice';
          callerData.value = callData['caller'] ?? {};

          hasActiveCall.value = true;
          isIncomingCall.value = true;

          _playIncomingRingtone();
          _notificationService.showIncomingCallNotification(
            callId: activeCallId.value,
            callerName: callerData['name']?.toString() ?? 'Incoming Call',
            callType: callType.value,
          );

          if (!_isDialogShowing) {
            _showIncomingCallDialog();
          }
        }
      }
    } catch (_) {}
  }

  /// Handle incoming call triggered directly by high-priority OneSignal push notification
  void handleIncomingPushCall(Map<String, dynamic> data) {
    final callId = int.tryParse(data['call_id']?.toString() ?? '') ?? 0;
    if (callId <= 0 || hasActiveCall.value) return;

    activeCallId.value = callId;
    channelName.value = data['channel_name']?.toString() ?? '';
    callType.value = data['call_type']?.toString() ?? 'voice';
    callerData.value = {
      'id': data['caller_id'],
      'name': data['caller_name'],
      'avatar': data['caller_avatar'],
    };

    hasActiveCall.value = true;
    isIncomingCall.value = true;

    _playIncomingRingtone();
    _notificationService.showIncomingCallNotification(
      callId: activeCallId.value,
      callerName: callerData['name']?.toString() ?? 'Incoming Call',
      callType: callType.value,
    );

    if (!_isDialogShowing) {
      _showIncomingCallDialog();
    }
  }

  void _showIncomingCallDialog() {
    _isDialogShowing = true;
    Get.dialog(
      IncomingCallDialog(
        callerName: callerData['name'] ?? 'Incoming Call',
        callerAvatar: callerData['avatar'],
        callType: callType.value,
        onAccept: () {
          Get.back();
          _isDialogShowing = false;
          acceptCall(activeCallId.value);
        },
        onDecline: () {
          Get.back();
          _isDialogShowing = false;
          rejectCall(activeCallId.value);
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> initiateCall({
    required int receiverId,
    required String type,
    int? conversationId,
    String? receiverName,
    String? receiverAvatar,
  }) async {
    if (receiverName != null) {
      callerData.value = {'name': receiverName, 'avatar': receiverAvatar};
    }
    hasActiveCall.value = true;
    isIncomingCall.value = false;
    callType.value = type;

    try {
      await ensureWakelock();
    } catch (_) {}

    _playOutgoingRingtone();
    _notificationService.showOngoingCallNotification(
      callerName: callerData['name']?.toString() ?? 'User',
      callType: callType.value,
      statusOrDuration: 'Ringing...',
      isConnected: false,
    );

    // Instantly navigate to ActiveCallPage calling screen
    Get.to(() => const ActiveCallPage());

    try {
      final response = await _apiClient.dio.post('/chat/call/initiate', data: {
        'receiver_id': receiverId,
        'call_type': type,
        'conversation_id': conversationId,
      });

      if (response.data != null && response.data['status'] == 'success') {
        final data = response.data['data'];
        activeCallId.value = data['call_id'];
        channelName.value = data['channel_name'];
        agoraAppId.value = data['agora_app_id'] ?? agoraAppId.value;

        await _initAgoraRtcEngine(
          appId: agoraAppId.value,
          channel: channelName.value,
          token: data['token'] ?? data['caller_token'] ?? '',
        );
      } else {
        if (Get.currentRoute.contains('ActiveCallPage')) {
          Get.back();
        }
        _resetCallState();
        Get.snackbar('call_error'.tr, response.data['message'] ?? 'unable_to_start_call'.tr);
      }
    } catch (e) {
      if (Get.currentRoute.contains('ActiveCallPage')) {
        Get.back();
      }
      _resetCallState();
      Get.snackbar('call_error'.tr, 'failed_to_initiate_call'.tr);
    }
  }

  Future<void> acceptCall(int callId) async {
    _stopRingtone();
    _notificationService.dismissIncomingNotification();
    try {
      await ensureWakelock();
    } catch (_) {}
    try {
      final response = await _apiClient.dio.post('/chat/call/$callId/answer');
      if (response.data != null && response.data['status'] == 'success') {
        final data = response.data['data'];
        agoraAppId.value = data['agora_app_id'] ?? agoraAppId.value;
        channelName.value = data['channel_name'];
        callType.value = data['call_type'];

        await _initAgoraRtcEngine(
          appId: agoraAppId.value,
          channel: channelName.value,
          token: data['token'] ?? '',
        );

        Get.to(() => const ActiveCallPage());
      }
    } catch (_) {}
  }

  Future<void> rejectCall(int callId) async {
    _stopRingtone();
    _notificationService.dismissIncomingNotification();
    try {
      await _apiClient.dio.post('/chat/call/$callId/reject');
    } catch (_) {}
    _resetCallState();
  }

  Future<void> endCall() async {
    _stopRingtone();
    final duration = callDuration.value;
    if (activeCallId.value > 0) {
      try {
        await _apiClient.dio.post('/chat/call/${activeCallId.value}/end', data: {
          'duration_seconds': duration,
        });
      } catch (_) {}
    }
    _resetCallState();
    if (Get.currentRoute.contains('ActiveCallPage')) {
      Get.back();
    }
    if (Get.isRegistered<ChatController>()) {
      final chatCtrl = Get.find<ChatController>();
      chatCtrl.loadConversations(showLoading: false);
      if (chatCtrl.activeConversationId != null) {
        chatCtrl.openConversation(chatCtrl.activeConversationId!, chatCtrl.activeUser!);
      }
    }
  }

  Future<void> _initAgoraRtcEngine({
    required String appId,
    required String channel,
    required String token,
  }) async {
    if (appId.isEmpty) return;

    try {
      await [Permission.microphone, Permission.camera].request();
    } catch (_) {}

    // Re-assert wakelock after permission request in case system dialog caused activity pause/resume
    await ensureWakelock();

    rtcEngine = createAgoraRtcEngine();
    await rtcEngine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    final isVideo = callType.value == 'video';
    // Video calls always default to speakerphone
    isSpeakerOn.value = isVideo;

    try {
      await rtcEngine!.setDefaultAudioRouteToSpeakerphone(isVideo);
    } catch (_) {}

    rtcEngine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          await ensureWakelock();
          if (isVideo || isSpeakerOn.value) {
            try {
              await rtcEngine?.setEnableSpeakerphone(true);
            } catch (_) {}
          }
          if (isIncomingCall.value) {
            isCallConnected.value = true;
            _startDurationTimer();
            _stopRingtone();
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUidValue, int elapsed) async {
          await ensureWakelock();
          if (isVideo || isSpeakerOn.value) {
            try {
              await rtcEngine?.setEnableSpeakerphone(true);
            } catch (_) {}
          }
          remoteUid.value = remoteUidValue;
          isCallConnected.value = true;
          _startDurationTimer();
          _stopRingtone();
        },
        onUserOffline: (RtcConnection connection, int remoteUidValue, UserOfflineReasonType reason) {
          remoteUid.value = 0;
          endCall();
        },
        onUserMuteVideo: (RtcConnection connection, int remoteUidValue, bool muted) {
          isRemoteVideoMuted.value = muted;
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('Agora RTC Error: $err, $msg');
          if (err == ErrorCodeType.errInvalidAppId) {
            Get.snackbar('agora_setup_error'.tr, 'invalid_agora_app_id'.tr,
                backgroundColor: Colors.red, colorText: Colors.white);
          }
        },
      ),
    );

    if (isVideo) {
      await rtcEngine!.enableVideo();
      await rtcEngine!.startPreview();
    } else {
      await rtcEngine!.enableAudio();
      await rtcEngine!.disableVideo();
    }

    int currentUserId = 0;
    if (Get.isRegistered<AuthController>()) {
      currentUserId = Get.find<AuthController>().user.value?.id ?? 0;
    }

    await rtcEngine!.joinChannel(
      token: token,
      channelId: channel,
      uid: currentUserId,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: isVideo,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideo,
      ),
    );

    await ensureWakelock();

    if (!isIncomingCall.value && !isCallConnected.value && _audioPlayer != null) {
      try {
        await _audioPlayer?.resume();
      } catch (_) {}
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    rtcEngine?.muteLocalAudioStream(isMuted.value);
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn.value = !isSpeakerOn.value;
    try {
      await rtcEngine?.setEnableSpeakerphone(isSpeakerOn.value);
    } catch (e) {
      debugPrint('Error toggling speakerphone: $e');
    }
  }

  void toggleCamera() {
    if (callType.value != 'video') return;
    isCameraOff.value = !isCameraOff.value;
    if (isCameraOff.value) {
      rtcEngine?.stopPreview();
      rtcEngine?.muteLocalVideoStream(true);
    } else {
      rtcEngine?.enableVideo();
      rtcEngine?.startPreview();
      rtcEngine?.muteLocalVideoStream(false);
    }
  }

  void switchCamera() {
    if (callType.value == 'video') {
      rtcEngine?.switchCamera();
    }
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _startDurationTimer() {
    callDuration.value = 0;
    _durationTimer?.cancel();
    ensureWakelock();
    _notificationService.showOngoingCallNotification(
      callerName: callerData['name']?.toString() ?? 'User',
      callType: callType.value,
      statusOrDuration: _formatDuration(callDuration.value),
      isConnected: true,
    );
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callDuration.value++;
      // Periodically re-assert wakelock every 5 seconds so OS sleep timeouts are kept at bay
      if (callDuration.value % 5 == 0) {
        ensureWakelock();
      }
      _notificationService.showOngoingCallNotification(
        callerName: callerData['name']?.toString() ?? 'User',
        callType: callType.value,
        statusOrDuration: _formatDuration(callDuration.value),
        isConnected: true,
      );
    });
  }

  void minimizeCall() {
    isMinimized.value = true;
    if (Get.currentRoute.contains('ActiveCallPage')) {
      Get.back();
    }
  }

  void expandCall() {
    isMinimized.value = false;
    ensureWakelock();
    if (!Get.currentRoute.contains('ActiveCallPage') && hasActiveCall.value) {
      Get.to(() => const ActiveCallPage());
    }
  }

  void destroyEngine() {
    _durationTimer?.cancel();
    rtcEngine?.leaveChannel();
    rtcEngine?.release();
    rtcEngine = null;
  }

  void _resetCallState() {
    _stopRingtone();
    _notificationService.dismissNotification();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    destroyEngine();
    hasActiveCall.value = false;
    isIncomingCall.value = false;
    isCallConnected.value = false;
    isMinimized.value = false;
    isMuted.value = false;
    isSpeakerOn.value = false;
    isCameraOff.value = false;
    isRemoteVideoMuted.value = false;
    activeCallId.value = 0;
    channelName.value = '';
    remoteUid.value = 0;
    callDuration.value = 0;
    callerData.clear();
  }
}
