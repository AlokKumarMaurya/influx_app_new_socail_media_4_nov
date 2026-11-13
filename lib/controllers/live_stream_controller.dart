import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/models/live_stream_model.dart';
import '../data/services/live_stream_service.dart';
import '../widgets/story/floating_reaction_overlay.dart';
import 'settings_controller.dart';

class LiveStreamController extends GetxController {
  final LiveStreamService _service = LiveStreamService();
  final FloatingReactionController reactionController = FloatingReactionController();

  // Discovery State
  final streams = <LiveStreamModel>[].obs;
  final isLoadingStreams = false.obs;
  final selectedFilter = 'popular'.obs;
  final selectedCategory = 'all'.obs;
  final searchQuery = ''.obs;

  // Config & Catalog State
  final canGoLive = true.obs;
  final gifts = <LiveGiftModel>[].obs;
  final superChatTiers = <SuperChatTierModel>[].obs;
  final reactionEmojis = <String>['💜', '❤️', '🔥', '👏', '😂', '🎉'].obs;
  final managedPages = <Map<String, dynamic>>[].obs;
  final liveFeatures = <String, dynamic>{}.obs;
  final minTipAmount = 1.0.obs;
  final maxTipAmount = 500.0.obs;
  final minEntryFee = 1.0.obs;
  final maxEntryFee = 500.0.obs;
  final currencySymbol = '\$'.obs;

  // Active Room State
  final activeStream = Rxn<LiveStreamModel>();
  final events = <LiveEventModel>[].obs;
  final pinnedComment = Rxn<LiveEventModel>();
  final activeGiftPop = Rxn<LiveEventModel>();
  final isHost = false.obs;
  final requiresTicket = false.obs;
  final isRoomLoading = false.obs;
  final viewerCount = 0.obs;
  final peakViewerCount = 0.obs;
  final totalReactionsCount = 0.obs;
  final totalEarnings = 0.0.obs;
  final elapsedSeconds = 0.obs;
  final isStreamEnded = false.obs;
  final latestLiveFrame = ''.obs;

  // Agora RTC Engine State
  RtcEngine? rtcEngine;
  final isEngineReady = false.obs;
  final remoteBroadcasterUid = 0.obs;
  final isMicMuted = false.obs;
  final isCameraOff = false.obs;

  Timer? _syncTimer;
  Timer? _durationTimer;
  int _lastEventId = 0;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<SettingsController>()) {
      final sym = Get.find<SettingsController>().currencySymbol.value;
      if (sym.isNotEmpty) {
        currencySymbol.value = sym;
      }
    }
    loadLiveConfig();
    fetchStreams();
  }

  void _syncCurrencySymbol(dynamic rawSymbol) {
    final sym = (rawSymbol ?? '').toString().trim();
    if (sym.isNotEmpty) {
      currencySymbol.value = sym;
      if (Get.isRegistered<SettingsController>()) {
        Get.find<SettingsController>().currencySymbol.value = sym;
      }
    }
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _durationTimer?.cancel();
    disposeAgora();
    super.onClose();
  }

  String get formattedDuration {
    final s = elapsedSeconds.value;
    final hrs = s ~/ 3600;
    final mins = (s % 3600) ~/ 60;
    final secs = s % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return hrs > 0 ? '${two(hrs)}:${two(mins)}:${two(secs)}' : '${two(mins)}:${two(secs)}';
  }

  Future<void> loadLiveConfig() async {
    try {
      final data = await _service.getConfig();
      canGoLive.value = data['can_go_live'] == true;

      if (data['gifts'] is List) {
        gifts.assignAll(
          (data['gifts'] as List)
              .map((g) => LiveGiftModel.fromJson(Map<String, dynamic>.from(g)))
              .toList(),
        );
      }

      if (data['managed_pages'] is List) {
        managedPages.assignAll(
          List<Map<String, dynamic>>.from(data['managed_pages']),
        );
      }

      final cfg = data['config'] is Map
          ? Map<String, dynamic>.from(data['config'])
          : <String, dynamic>{};
      _syncCurrencySymbol(cfg['currency_symbol']);
      if (cfg['features'] is Map) {
        liveFeatures.assignAll(Map<String, dynamic>.from(cfg['features']));
      }
      if (cfg['reaction_emojis'] is List) {
        reactionEmojis.assignAll(
          (cfg['reaction_emojis'] as List).map((e) => e.toString()).toList(),
        );
      }
      if (cfg['super_chat_tiers'] is List) {
        superChatTiers.assignAll(
          (cfg['super_chat_tiers'] as List)
              .map((t) => SuperChatTierModel.fromJson(Map<String, dynamic>.from(t)))
              .toList(),
        );
      }
      minTipAmount.value =
          double.tryParse((cfg['min_tip_amount'] ?? 1).toString()) ?? 1.0;
      maxTipAmount.value =
          double.tryParse((cfg['max_tip_amount'] ?? 500).toString()) ?? 500.0;
      minEntryFee.value =
          double.tryParse((cfg['min_entry_fee'] ?? 1).toString()) ?? 1.0;
      maxEntryFee.value =
          double.tryParse((cfg['max_entry_fee'] ?? 500).toString()) ?? 500.0;
    } catch (e) {
      debugPrint('Live config load error: $e');
    }
  }

  Future<void> fetchStreams({String? filter, String? category, String? query}) async {
    if (filter != null) selectedFilter.value = filter;
    if (category != null) selectedCategory.value = category;
    if (query != null) searchQuery.value = query;

    isLoadingStreams.value = true;
    try {
      final result = await _service.getStreams(
        filter: selectedFilter.value,
        category: selectedCategory.value,
        query: searchQuery.value,
      );
      if (result.isNotEmpty && result.first.currencySymbol != null) {
        _syncCurrencySymbol(result.first.currencySymbol);
      }
      streams.assignAll(result);
    } catch (e) {
      debugPrint('Fetch live streams error: $e');
    } finally {
      isLoadingStreams.value = false;
    }
  }

  Future<LiveStreamModel?> startNewBroadcast({
    required String title,
    String? description,
    String category = 'general',
    int? fanPageId,
    bool isPaid = false,
    double entryFee = 0.0,
    File? thumbnailFile,
  }) async {
    try {
      final res = await _service.startStream(
        title: title,
        description: description,
        category: category,
        fanPageId: fanPageId,
        isPaid: isPaid,
        entryFee: entryFee,
        thumbnailFile: thumbnailFile,
      );
      final stream = LiveStreamModel.fromJson(
        Map<String, dynamic>.from(res['stream']),
      );
      return stream;
    } catch (e) {
      Get.snackbar(
        'Cannot Start Broadcast',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<void> enterLiveRoom(String uuid) async {
    isRoomLoading.value = true;
    isStreamEnded.value = false;
    events.clear();
    pinnedComment.value = null;
    remoteBroadcasterUid.value = 0;
    latestLiveFrame.value = '';
    _lastEventId = 0;

    try {
      final data = await _service.joinStream(uuid);
      final stream = LiveStreamModel.fromJson(
        Map<String, dynamic>.from(data['stream']),
      );
      if (stream.currencySymbol != null) {
        _syncCurrencySymbol(stream.currencySymbol);
      }
      activeStream.value = stream;
      viewerCount.value = stream.viewerCount;
      peakViewerCount.value = stream.peakViewerCount;
      totalReactionsCount.value = stream.totalReactionsCount;
      totalEarnings.value = stream.totalEarnings;
      elapsedSeconds.value = stream.durationSeconds;
      isStreamEnded.value = stream.status != 'live';

      final join = Map<String, dynamic>.from(data['join'] ?? {});
      _syncCurrencySymbol(join['currency_symbol']);
      if (join['live_frame'] != null && join['live_frame'].toString().isNotEmpty) {
        latestLiveFrame.value = join['live_frame'].toString();
      }
      isHost.value = join['is_host'] == true;
      requiresTicket.value = join['requires_ticket'] == true;

      if (data['events'] is List) {
        final evList = (data['events'] as List)
            .map((e) => LiveEventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        events.assignAll(evList.where((e) => e.type != 'reaction'));
        if (evList.isNotEmpty) {
          _lastEventId = evList.last.id;
        }
      }

      if (data['pinned_comment'] != null) {
        pinnedComment.value = LiveEventModel.fromJson(
          Map<String, dynamic>.from(data['pinned_comment']),
        );
      }

      if (!isStreamEnded.value) {
        if (!requiresTicket.value) {
          await _initAgoraBroadcast(join);
        }
        _startRoomSync(uuid);
        _startDurationClock();
        WakelockPlus.enable();
      }
    } catch (e) {
      debugPrint('Enter live room error: $e');
    } finally {
      isRoomLoading.value = false;
    }
  }

  Future<void> _initAgoraBroadcast(Map<String, dynamic> join) async {
    final appId = (join['agora_app_id'] ?? '').toString();
    final channel = (join['channel_name'] ?? '').toString();
    final token = (join['token'] ?? '').toString();
    final uid = (join['uid'] as num?)?.toInt() ?? 0;

    if (appId.isEmpty || channel.isEmpty) return;

    try {
      if (isHost.value) {
        await [Permission.camera, Permission.microphone].request();
      }

      await disposeAgora();

      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      bool retriedWithoutToken = false;
      final mediaOptions = ChannelMediaOptions(
        clientRoleType: isHost.value
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishCameraTrack: isHost.value,
        publishMicrophoneTrack: isHost.value,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      );

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (RtcConnection connection, int rUid, int elapsed) {
            if (rUid > 0) {
              remoteBroadcasterUid.value = rUid;
            }
          },
          onRemoteVideoStateChanged: (
            RtcConnection connection,
            int rUid,
            RemoteVideoState state,
            RemoteVideoStateReason reason,
            int elapsed,
          ) {
            if (rUid > 0 &&
                (state == RemoteVideoState.remoteVideoStateStarting ||
                    state == RemoteVideoState.remoteVideoStateDecoding)) {
              remoteBroadcasterUid.value = rUid;
            }
          },
          onUserOffline: (
            RtcConnection connection,
            int rUid,
            UserOfflineReasonType reason,
          ) {
            if (remoteBroadcasterUid.value == rUid) {
              remoteBroadcasterUid.value = 0;
            }
          },
          onError: (ErrorCodeType err, String msg) async {
            if (!retriedWithoutToken &&
                token.isNotEmpty &&
                (err == ErrorCodeType.errInvalidToken ||
                    err == ErrorCodeType.errTokenExpired)) {
              retriedWithoutToken = true;
              try {
                await engine.leaveChannel();
                await engine.joinChannel(
                  token: '',
                  channelId: channel,
                  uid: uid,
                  options: mediaOptions,
                );
              } catch (_) {}
            }
          },
        ),
      );

      await engine.enableVideo();
      await engine.enableAudio();
      await engine.setDefaultAudioRouteToSpeakerphone(true);
      await engine.setEnableSpeakerphone(true);
      await engine.muteAllRemoteAudioStreams(false);
      await engine.adjustPlaybackSignalVolume(100);
      await engine.setClientRole(
        role: isHost.value
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      if (isHost.value) {
        await engine.enableLocalAudio(true);
        await engine.muteLocalAudioStream(isMicMuted.value);
        await engine.adjustRecordingSignalVolume(100);
        await engine.startPreview();
      }

      await engine.joinChannel(
        token: token,
        channelId: channel,
        uid: uid,
        options: mediaOptions,
      );

      rtcEngine = engine;
      isEngineReady.value = true;
    } catch (e) {
      debugPrint('Agora live init notice: $e');
    }
  }

  Future<void> unlockPaidStream() async {
    final stream = activeStream.value;
    if (stream == null) return;
    try {
      final res = await _service.unlockStream(stream.uuid);
      requiresTicket.value = false;
      final join = Map<String, dynamic>.from(res['join'] ?? {});
      await _initAgoraBroadcast(join);
      Get.snackbar(
        'Unlocked!',
        'Welcome to the VIP live broadcast.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF8B5CF6),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Unlock Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> sendComment(
    String message, {
    bool isSuperChat = false,
    double amount = 0.0,
  }) async {
    final stream = activeStream.value;
    if (stream == null || message.trim().isEmpty) return;

    try {
      final ev = await _service.sendComment(
        stream.uuid,
        message: message.trim(),
        isSuperChat: isSuperChat,
        amount: amount,
      );
      _processIncomingEvent(ev);
    } catch (e) {
      Get.snackbar(
        'Message Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> togglePinComment(int eventId) async {
    final stream = activeStream.value;
    if (stream == null || !isHost.value) return;
    try {
      await _service.pinComment(stream.uuid, eventId);
    } catch (_) {}
  }

  Future<void> sendGift(LiveGiftModel gift, {int quantity = 1, String? message}) async {
    final stream = activeStream.value;
    if (stream == null) return;

    try {
      final ev = await _service.sendGift(
        stream.uuid,
        giftId: gift.id,
        quantity: quantity,
        message: message,
      );
      _processIncomingEvent(ev);
    } catch (e) {
      Get.snackbar(
        'Gift Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendTip(double amount, {String? message}) async {
    final stream = activeStream.value;
    if (stream == null) return;

    try {
      final ev = await _service.sendTip(
        stream.uuid,
        amount: amount,
        message: message,
      );
      _processIncomingEvent(ev);
    } catch (e) {
      Get.snackbar(
        'Tip Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> sendReaction(String emoji) async {
    reactionController.trigger(emoji);
    final stream = activeStream.value;
    if (stream == null) return;
    try {
      await _service.sendReaction(stream.uuid, emoji);
    } catch (_) {}
  }

  void _processIncomingEvent(LiveEventModel ev) {
    if (ev.id > _lastEventId) {
      _lastEventId = ev.id;
    }

    if (ev.type == 'reaction') {
      final emoji = (ev.meta['emoji'] ?? ev.message ?? '💜').toString();
      reactionController.trigger(emoji);
      return;
    }

    if (ev.type == 'gift' || ev.type == 'tip') {
      activeGiftPop.value = ev;
      Future.delayed(const Duration(seconds: 3), () {
        if (activeGiftPop.value?.id == ev.id) {
          activeGiftPop.value = null;
        }
      });
    }

    if (!events.any((existing) => existing.id == ev.id)) {
      events.add(ev);
      if (events.length > 80) {
        events.removeRange(0, events.length - 80);
      }
    }
  }

  void _startDurationClock() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isStreamEnded.value) {
        _durationTimer?.cancel();
        return;
      }
      elapsedSeconds.value++;
    });
  }

  void _startRoomSync(String uuid) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (isStreamEnded.value) {
        _syncTimer?.cancel();
        return;
      }
      try {
        final data = await _service.sync(uuid, _lastEventId);
        _syncCurrencySymbol(data['currency_symbol']);
        if (data['live_frame'] != null && data['live_frame'].toString().isNotEmpty) {
          latestLiveFrame.value = data['live_frame'].toString();
        }
        viewerCount.value = (data['viewer_count'] as num?)?.toInt() ?? viewerCount.value;
        peakViewerCount.value =
            (data['peak_viewer_count'] as num?)?.toInt() ?? peakViewerCount.value;
        if (data['total_reactions_count'] != null) {
          totalReactionsCount.value = (data['total_reactions_count'] as num).toInt();
        }
        if (data['total_earnings'] != null) {
          totalEarnings.value = (data['total_earnings'] as num).toDouble();
        }

        if (data['status'] == 'ended') {
          isStreamEnded.value = true;
          _syncTimer?.cancel();
          _durationTimer?.cancel();
        }

        if (data['pinned_comment'] != null) {
          pinnedComment.value = LiveEventModel.fromJson(
            Map<String, dynamic>.from(data['pinned_comment']),
          );
        } else {
          pinnedComment.value = null;
        }

        if (data['events'] is List) {
          for (final item in (data['events'] as List)) {
            final ev = LiveEventModel.fromJson(Map<String, dynamic>.from(item));
            _processIncomingEvent(ev);
          }
        }
      } catch (_) {}
    });
  }

  Future<void> toggleMic() async {
    isMicMuted.value = !isMicMuted.value;
    await rtcEngine?.muteLocalAudioStream(isMicMuted.value);
  }

  Future<void> toggleCamera() async {
    isCameraOff.value = !isCameraOff.value;
    await rtcEngine?.muteLocalVideoStream(isCameraOff.value);
  }

  Future<void> switchCamera() async {
    await rtcEngine?.switchCamera();
  }

  Future<void> leaveOrEndRoom({bool forceEnd = false}) async {
    _syncTimer?.cancel();
    _durationTimer?.cancel();
    final stream = activeStream.value;
    if (stream != null) {
      if (isHost.value && forceEnd) {
        await _service.endStream(stream.uuid);
      } else {
        await _service.leaveStream(stream.uuid);
      }
    }
    await disposeAgora();
    WakelockPlus.disable();
  }

  Future<void> disposeAgora() async {
    isEngineReady.value = false;
    final engine = rtcEngine;
    rtcEngine = null;
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } catch (_) {}
    }
  }
}

