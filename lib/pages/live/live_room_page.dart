import 'dart:convert';
import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/live_stream_controller.dart';
import '../../data/models/live_stream_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/story/floating_reaction_overlay.dart';

class LiveRoomPage extends StatefulWidget {
  final String uuid;

  const LiveRoomPage({super.key, required this.uuid});

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage> {
  late final LiveStreamController _controller;
  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();
  Worker? _eventsWorker;
  bool _userScrolledUp = false;
  int _unreadBelowCount = 0;
  bool _didCleanExit = false;
  bool _isConfirmDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<LiveStreamController>()
        ? Get.find<LiveStreamController>()
        : Get.put(LiveStreamController());
    _controller.enterLiveRoom(widget.uuid);

    _chatScrollCtrl.addListener(_onChatScroll);
    _eventsWorker = ever<List<LiveEventModel>>(_controller.events, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_chatScrollCtrl.hasClients) return;
        if (!_userScrolledUp) {
          _scrollToBottom(animated: true);
        } else {
          setState(() => _unreadBelowCount++);
        }
      });
    });
  }

  void _onChatScroll() {
    if (!_chatScrollCtrl.hasClients) return;
    final pos = _chatScrollCtrl.position;
    final distFromBottom = pos.maxScrollExtent - pos.pixels;
    final isUp = distFromBottom > 64;
    if (isUp != _userScrolledUp) {
      setState(() {
        _userScrolledUp = isUp;
        if (!isUp) _unreadBelowCount = 0;
      });
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_chatScrollCtrl.hasClients) return;
    final target = _chatScrollCtrl.position.maxScrollExtent;
    if (animated) {
      _chatScrollCtrl.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _chatScrollCtrl.jumpTo(target);
    }
    if (_userScrolledUp || _unreadBelowCount > 0) {
      setState(() {
        _userScrolledUp = false;
        _unreadBelowCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _eventsWorker?.dispose();
    _chatScrollCtrl.removeListener(_onChatScroll);
    _chatScrollCtrl.dispose();
    _commentCtrl.dispose();
    if (!_didCleanExit) {
      _controller.leaveOrEndRoom(
        forceEnd: _controller.isHost.value && !_controller.isStreamEnded.value,
      );
    }
    super.dispose();
  }

  void _sendComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    _controller.sendComment(text);
    Future.delayed(const Duration(milliseconds: 120), () {
      _scrollToBottom(animated: true);
    });
  }

  Future<void> _confirmEndOrLeave(bool isHost, bool isEnded) async {
    if (_isConfirmDialogOpen) return;
    if (isHost && !isEnded) {
      _isConfirmDialogOpen = true;
      final shouldEnd = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: const Color(0xFF161321),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Colors.white12),
          ),
          title: const Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                size: 22,
                color: Color(0xFFEF4444),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'End Live Broadcast?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Leaving this screen will immediately end your live broadcast for all viewers and save your broadcast summary.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Keep Streaming', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('End Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      _isConfirmDialogOpen = false;
      if (shouldEnd != true) return;
      _didCleanExit = true;
      await _controller.leaveOrEndRoom(forceEnd: true);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _didCleanExit = true;
    await _controller.leaveOrEndRoom(forceEnd: false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmEndOrLeave(
          _controller.isHost.value,
          _controller.isStreamEnded.value,
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF09080E),
        resizeToAvoidBottomInset: true,
        body: Obx(() {
        final stream = _controller.activeStream.value;
        final isHost = _controller.isHost.value;
        final needsTicket = _controller.requiresTicket.value;
        final isEnded = _controller.isStreamEnded.value;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Fullscreen Vertical Video Stage (Agora RTC or Thumbnail Fallback)
            _buildVideoCanvas(stream, isHost, needsTicket, isEnded),

            // Subtle Top & Bottom Gradient Vignette for Readability
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.58),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.38, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Top Studio Header & Host Telemetry Strip
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopStudioBar(stream, isHost, isEnded),
                      if (isHost && !isEnded) ...[
                        const SizedBox(height: 8),
                        _buildHostTelemetryHud(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 3. Ended Broadcast Summary Overlay Card (when stream is ended)
            if (isEnded && stream != null)
              Align(
                alignment: const Alignment(0, -0.22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildEndedBroadcastSummaryCard(stream, isHost),
                ),
              ),

            // 4. Center Gift / Tip Pop Showcase Animation
            if (_controller.activeGiftPop.value != null)
              Center(
                child: IgnorePointer(
                  child: _buildGiftPopOverlay(_controller.activeGiftPop.value!),
                ),
              ),

            // 5. Floating Reaction Bursts Overlay (IgnorePointer so it NEVER blocks comment scrolling)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: FloatingReactionOverlay(
                  controller: _controller.reactionController,
                ),
              ),
            ),

            // 6. Scrollable Glassmorphic Comment List + Pinned Comment + Host/Viewer Bottom Controls
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scrollable Live Comments List with Top Fade & Unread Pill
                      _buildScrollableCommentList(),
                      const SizedBox(height: 6),

                      // Pinned Comment / Super Chat Card with Circular 📌 Pin Icon
                      if (_controller.pinnedComment.value != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildPinnedCommentCard(_controller.pinnedComment.value!),
                        ),

                      // Quick Emoji Reaction Strip (for viewers & host when live)
                      if (!isEnded)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildQuickReactionStrip(isHost),
                        ),

                      // Bottom Pill Input ("Comment...") + Action Buttons
                      if (!isEnded)
                        _buildBottomInteractionBar(isHost)
                      else
                        _buildEndedBottomNotice(),
                    ],
                  ),
                ),
              ),
            ),

            // 7. Paid Live Ticket Unlock Gate
            if (needsTicket && !isEnded && stream != null)
              _buildPaidTicketGate(stream),
          ],
        );
      }),
      ),
    );
  }

  Widget _buildTopStudioBar(LiveStreamModel? stream, bool isHost, bool isEnded) {
    return Row(
      children: [
        if (stream != null)
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: CachedNetworkImageProvider(
                            UrlUtils.getFullUrl(stream.broadcasterAvatar),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    stream.broadcasterName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                if (stream.broadcasterVerified) ...[
                                  const SizedBox(width: 4),
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedTick01,
                                    size: 13,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isEnded
                                        ? Colors.grey
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isEnded
                                      ? 'ENDED • ${stream.durationLabel}'
                                      : 'LIVE • ${_controller.formattedDuration}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
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
            ),
          ),
        const SizedBox(width: 8),

        // Purple Viewer Count Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedView,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '${isEnded ? _controller.peakViewerCount.value : _controller.viewerCount.value}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        // Close / End Stream Button
        _buildTopCircleBtn(
          hugeIcon: HugeIcons.strokeRoundedCancel01,
          color: isHost && !isEnded
              ? const Color(0xFFEF4444)
              : Colors.black.withValues(alpha: 0.5),
          onTap: () => _confirmEndOrLeave(isHost, isEnded),
        ),
      ],
    );
  }

  /// Dedicated Host Studio Telemetry & Quick Camera/Mic Controls Bar
  Widget _buildHostTelemetryHud() {
    final micMuted = _controller.isMicMuted.value;
    final camOff = _controller.isCameraOff.value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              // Earnings Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedWallet01,
                      size: 12,
                      color: Color(0xFF6EE7B7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_controller.currencySymbol.value}${_controller.totalEarnings.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedView,
                    size: 12,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Peak ${_controller.peakViewerCount.value}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    size: 12,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${_controller.totalReactionsCount.value}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Host Studio Controls: Mic, Cam, Flip
              _buildStudioChipBtn(
                hugeIcon: micMuted
                    ? HugeIcons.strokeRoundedCancel01
                    : HugeIcons.strokeRoundedVideo02,
                label: micMuted ? 'Muted' : 'Mic',
                isDanger: micMuted,
                onTap: _controller.toggleMic,
              ),
              const SizedBox(width: 6),
              _buildStudioChipBtn(
                hugeIcon: camOff
                    ? HugeIcons.strokeRoundedCancel01
                    : HugeIcons.strokeRoundedCamera01,
                label: camOff ? 'Off' : 'Cam',
                isDanger: camOff,
                onTap: _controller.toggleCamera,
              ),
              const SizedBox(width: 6),
              _buildStudioChipBtn(
                hugeIcon: HugeIcons.strokeRoundedCamera01,
                label: 'Flip',
                onTap: _controller.switchCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudioChipBtn({
    required dynamic hugeIcon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFEF4444).withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger
                ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: hugeIcon,
              size: 13,
              color: isDanger ? const Color(0xFFFCA5A5) : Colors.white,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: isDanger ? const Color(0xFFFCA5A5) : Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndedBroadcastSummaryCard(LiveStreamModel stream, bool isHost) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'BROADCAST SUMMARY • ${stream.durationLabel}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                stream.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Streamed by ${stream.broadcasterName}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryStatTile(
                      value: '${stream.peakViewerCount}',
                      label: 'Peak Viewers',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStatTile(
                      value: stream.durationLabel,
                      label: 'Duration',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStatTile(
                      value: '${stream.totalReactionsCount}',
                      label: 'Reactions',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryStatTile(
                      value: '${_controller.events.length}',
                      label: 'Chat Events',
                    ),
                  ),
                ],
              ),
              if (isHost && stream.totalEarnings > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedWallet01,
                        size: 14,
                        color: Color(0xFF6EE7B7),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Total Broadcast Earnings: ${_controller.currencySymbol.value}${stream.totalEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatTile({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCanvas(
    LiveStreamModel? stream,
    bool isHost,
    bool needsTicket,
    bool isEnded,
  ) {
    if (!isEnded &&
        _controller.isEngineReady.value &&
        _controller.rtcEngine != null &&
        !needsTicket &&
        !(isHost && _controller.isCameraOff.value)) {
      if (isHost) {
        return AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _controller.rtcEngine!,
            canvas: const VideoCanvas(
              uid: 0,
              renderMode: RenderModeType.renderModeHidden,
            ),
          ),
        );
      } else if (_controller.remoteBroadcasterUid.value > 0 && stream != null) {
        return Container(
          color: const Color(0xFF09070F),
          alignment: Alignment.center,
          child: AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _controller.rtcEngine!,
              canvas: VideoCanvas(
                uid: _controller.remoteBroadcasterUid.value,
                renderMode: RenderModeType.renderModeFit,
              ),
              connection: RtcConnection(channelId: stream.channelName),
            ),
          ),
        );
      }
    }

    if (!isEnded &&
        !needsTicket &&
        !isHost &&
        _controller.latestLiveFrame.value.isNotEmpty) {
      try {
        final raw = _controller.latestLiveFrame.value;
        final b64 = raw.contains(',') ? raw.split(',').last : raw;
        final bytes = base64Decode(b64);
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF09070F)),
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Opacity(
                opacity: 0.35,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            Center(
              child: Image.memory(
                bytes,
                width: double.infinity,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ],
        );
      } catch (_) {}
    }

    if (stream != null && stream.thumbnailUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: UrlUtils.getFullUrl(stream.thumbnailUrl),
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Container(color: const Color(0xFF14111F)),
      );
    }

    return Container(color: const Color(0xFF14111F));
  }

  Widget _buildTopCircleBtn({
    required dynamic hugeIcon,
    required VoidCallback onTap,
    Color color = Colors.black45,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: HugeIcon(icon: hugeIcon, size: 17, color: Colors.white),
        ),
      ),
    );
  }

  /// Scrollable Comment List with top-fade ShaderMask, auto-scroll, and "New comments" indicator.
  Widget _buildScrollableCommentList() {
    final allEvents = _controller.events;
    if (allEvents.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 215,
      width: MediaQuery.of(context).size.width * 0.84,
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (Rect rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white, Colors.white],
                stops: [0.0, 0.16, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _chatScrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 18, bottom: 6),
              itemCount: allEvents.length,
              itemBuilder: (context, i) {
                final ev = allEvents[i];
                return _buildSingleCommentBubble(ev);
              },
            ),
          ),
          if (_userScrolledUp && _unreadBelowCount > 0)
            Positioned(
              bottom: 4,
              left: 0,
              child: GestureDetector(
                onTap: () => _scrollToBottom(animated: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedComment01,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_unreadBelowCount new message${_unreadBelowCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleCommentBubble(LiveEventModel ev) {
    final isSuper = ev.type == 'super_chat';
    final isGiftOrTip = ev.type == 'gift' || ev.type == 'tip';
    final giftIcon = (ev.meta['gift_icon'] ?? (ev.type == 'tip' ? '💸' : '🎁')).toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: _controller.isHost.value
              ? () {
                  _controller.togglePinComment(ev.id);
                  Get.snackbar(
                    'Pinned Comment',
                    'Updated pinned message in live room.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.black87,
                    colorText: Colors.white,
                  );
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
                decoration: BoxDecoration(
                  gradient: isSuper
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        )
                      : (isGiftOrTip
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF8B5CF6).withValues(alpha: 0.45),
                                const Color(0xFF6366F1).withValues(alpha: 0.35),
                              ],
                            )
                          : null),
                  color: (!isSuper && !isGiftOrTip)
                      ? Colors.black.withValues(alpha: 0.42)
                      : null,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSuper
                        ? Colors.amberAccent.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isGiftOrTip)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 1),
                        child: Text(giftIcon, style: const TextStyle(fontSize: 18)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 1),
                        child: CircleAvatar(
                          radius: 13,
                          backgroundImage: ev.userAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(
                                  UrlUtils.getFullUrl(ev.userAvatar),
                                )
                              : null,
                          backgroundColor: Colors.white24,
                          child: ev.userAvatar.isEmpty
                              ? const HugeIcon(
                                  icon: HugeIcons.strokeRoundedUser,
                                  size: 13,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  ev.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                              if (isSuper && ev.amount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_controller.currencySymbol.value}${ev.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            ev.message ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Highlighted Pinned Comment / Super Chat card with circular 📌 pin badge on the right
  Widget _buildPinnedCommentCard(LiveEventModel pinned) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.84,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.36),
                const Color(0xFFEC4899).withValues(alpha: 0.28),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: pinned.userAvatar.isNotEmpty
                    ? CachedNetworkImageProvider(UrlUtils.getFullUrl(pinned.userAvatar))
                    : null,
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pinned.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      pinned.message ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                alignment: Alignment.center,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAward01,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReactionStrip(bool isHost) {
    final emojis = _controller.reactionEmojis.take(5).toList();
    return Row(
      children: [
        for (final emoji in emojis)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _controller.sendReaction(emoji),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ),
        if (isHost) ...[
          const Spacer(),
          GestureDetector(
            onTap: () => _confirmEndOrLeave(true, false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 13,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'End Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEndedBottomNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedClock01,
            size: 16,
            color: Colors.white70,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Broadcast has ended • Viewing chat replay',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Pill Input ("Comment...") with nested circular purple Send button +
  /// Gift, Tip, Share, and glowing purple Heart buttons on the right.
  Widget _buildBottomInteractionBar(bool isHost) {
    return Row(
      children: [
        // Pill Comment Input with nested circular purple Paper-Plane button
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 48,
                padding: const EdgeInsets.only(left: 18, right: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        onSubmitted: (_) => _sendComment(),
                        decoration: InputDecoration(
                          hintText: isHost ? 'Message your viewers...' : 'Comment...',
                          hintStyle: const TextStyle(color: Colors.white60, fontSize: 13.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sendComment,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          ),
                        ),
                        child: const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSent,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        if (!isHost) ...[
          // Gift Sheet Button
          _buildBottomCircleBtn(
            hugeIcon: HugeIcons.strokeRoundedAward01,
            onTap: _showGiftBottomSheet,
          ),
          const SizedBox(width: 8),
          // Tip / Super Chat Sheet Button
          _buildBottomCircleBtn(
            hugeIcon: HugeIcons.strokeRoundedWallet01,
            onTap: _showMonetizationSheet,
          ),
          const SizedBox(width: 8),
        ],

        // Share Button
        _buildBottomCircleBtn(
          hugeIcon: HugeIcons.strokeRoundedShare01,
          onTap: _showLiveShareSheet,
        ),
        const SizedBox(width: 8),

        // Purple Heart Reaction Button
        GestureDetector(
          onTap: () => _controller.sendReaction('💜'),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.48),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.65),
              ),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFavourite,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCircleBtn({
    required dynamic hugeIcon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.48),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Center(
          child: HugeIcon(
            icon: hugeIcon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _buildGiftPopOverlay(LiveEventModel ev) {
    final icon = (ev.meta['gift_icon'] ?? (ev.type == 'tip' ? '💸' : '🎁')).toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 6),
          Text(
            ev.userName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            ev.message ?? 'Sent a gift!',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidTicketGate(LiveStreamModel stream) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        color: Colors.black.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                ),
                alignment: Alignment.center,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLock,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'VIP Paid Live Broadcast',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock instant access to watch ${stream.broadcasterName}\'s live stream.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _controller.unlockPaidStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  'Unlock Ticket for ${_controller.currencySymbol.value}${stream.entryFee.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGiftBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF161321),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Obx(() {
          final giftList = _controller.gifts;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAward01,
                    size: 18,
                    color: Color(0xFF8B5CF6),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Send a Live Gift',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 190,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: giftList.length,
                  itemBuilder: (context, idx) {
                    final g = giftList[idx];
                    return GestureDetector(
                      onTap: () {
                        Get.back();
                        _controller.sendGift(g);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(g.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              g.isFree
                                  ? 'FREE'
                                  : '${_controller.currencySymbol.value}${g.price.toStringAsFixed(g.price == g.price.roundToDouble() ? 0 : 2)}',
                              style: TextStyle(
                                color: g.isFree ? Colors.greenAccent : const Color(0xFFA78BFA),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showMonetizationSheet() {
    final amountCtrl = TextEditingController(text: '5');
    final msgCtrl = TextEditingController();
    final isSuperChat = true.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF161321),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    avatar: const HugeIcon(
                      icon: HugeIcons.strokeRoundedComment01,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: const Text('Super Chat'),
                    selected: isSuperChat.value,
                    backgroundColor: const Color(0xFF262136),
                    selectedColor: const Color(0xFF8B5CF6),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSuperChat.value
                          ? const Color(0xFF8B5CF6)
                          : Colors.white24,
                    ),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => isSuperChat.value = true,
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    avatar: const HugeIcon(
                      icon: HugeIcons.strokeRoundedWallet01,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: const Text('Direct Tip'),
                    selected: !isSuperChat.value,
                    backgroundColor: const Color(0xFF262136),
                    selectedColor: const Color(0xFF8B5CF6),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: !isSuperChat.value
                          ? const Color(0xFF8B5CF6)
                          : Colors.white24,
                    ),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => isSuperChat.value = false,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (${_controller.currencySymbol.value})',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: msgCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isSuperChat.value
                      ? 'Highlighted Message'
                      : 'Optional Tip Message',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountCtrl.text.trim()) ?? 5.0;
                    final msg = msgCtrl.text.trim();
                    Get.back();
                    if (isSuperChat.value) {
                      _controller.sendComment(
                        msg.isEmpty ? 'Super Chat!' : msg,
                        isSuperChat: true,
                        amount: amt,
                      );
                    } else {
                      _controller.sendTip(amt, message: msg);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    isSuperChat.value ? 'Send Super Chat' : 'Send Tip',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLiveShareSheet() {
    final stream = _controller.activeStream.value;
    final postId = stream?.postId;
    final shareUrl = UrlUtils.getFullUrl('/live/${widget.uuid}');
    final contentController = TextEditingController();
    final currentUser = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().user.value
        : null;
    String privacy = 'public';

    void performLivePostShare(String targetPrivacy) {
      if (postId != null && postId > 0) {
        final feedCtrl = Get.isRegistered<FeedController>()
            ? Get.find<FeedController>()
            : Get.put(FeedController());
        feedCtrl.sharePost(postId, contentController.text.trim(), targetPrivacy);
        Get.back();
      } else {
        Clipboard.setData(ClipboardData(text: shareUrl));
        Get.back();
        Get.snackbar('success'.tr, 'link_copied_clipboard'.tr);
      }
    }

    Get.bottomSheet(
      Obx(() {
        AppColors.isDark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 20),
                          Text(
                            'share'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CustomAvatar(user: currentUser, radius: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.name ?? stream?.broadcasterName ?? 'User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    builder: (privacyCtx) => SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'select_privacy'.tr,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 12),
                                            ListTile(
                                              leading: const HugeIcon(
                                                icon: HugeIcons.strokeRoundedGlobe02,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              title: Text('public'.tr),
                                              subtitle: Text('anyone_on_or_off_influx'.tr),
                                              trailing: privacy == 'public'
                                                  ? const HugeIcon(
                                                      icon: HugeIcons.strokeRoundedTick01,
                                                      color: AppColors.primary,
                                                      size: 18,
                                                    )
                                                  : null,
                                              onTap: () {
                                                setModalState(() => privacy = 'public');
                                                Navigator.of(privacyCtx).pop();
                                              },
                                            ),
                                            ListTile(
                                              leading: const HugeIcon(
                                                icon: HugeIcons.strokeRoundedUserGroup,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              title: Text('friends'.tr),
                                              subtitle: Text('friends_on_influx'.tr),
                                              trailing: privacy == 'friends'
                                                  ? const HugeIcon(
                                                      icon: HugeIcons.strokeRoundedTick01,
                                                      color: AppColors.primary,
                                                      size: 18,
                                                    )
                                                  : null,
                                              onTap: () {
                                                setModalState(() => privacy = 'friends');
                                                Navigator.of(privacyCtx).pop();
                                              },
                                            ),
                                            ListTile(
                                              leading: const HugeIcon(
                                                icon: HugeIcons.strokeRoundedLock,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                              title: Text('only_me'.tr),
                                              subtitle: Text('only_you_can_see_this'.tr),
                                              trailing: privacy == 'only_me'
                                                  ? const HugeIcon(
                                                      icon: HugeIcons.strokeRoundedTick01,
                                                      color: AppColors.primary,
                                                      size: 18,
                                                    )
                                                  : null,
                                              onTap: () {
                                                setModalState(() => privacy = 'only_me');
                                                Navigator.of(privacyCtx).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      HugeIcon(
                                        icon: privacy == 'friends'
                                            ? HugeIcons.strokeRoundedUserGroup
                                            : (privacy == 'only_me'
                                                ? HugeIcons.strokeRoundedLock
                                                : HugeIcons.strokeRoundedGlobe02),
                                        size: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        privacy == 'friends'
                                            ? 'friends'.tr
                                            : (privacy == 'only_me' ? 'only_me'.tr : 'public'.tr),
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 4),
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedArrowDown01,
                                        size: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contentController,
                        maxLines: 2,
                        style: TextStyle(color: AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: 'say_something_about_this'.tr,
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildShareOptionTile(
                        icon: HugeIcons.strokeRoundedShare01,
                        title: 'share_now_public'.tr,
                        subtitle: 'instantly_sharing_feed'.tr,
                        onTap: () => performLivePostShare('public'),
                      ),
                      _buildShareOptionTile(
                        icon: HugeIcons.strokeRoundedBubbleChat,
                        title: 'send_in_messenger'.tr,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: shareUrl));
                          Get.back();
                          Get.snackbar('success'.tr, 'link_copied_clipboard'.tr);
                        },
                      ),
                      _buildShareOptionTile(
                        icon: HugeIcons.strokeRoundedLink01,
                        title: 'copy_link'.tr,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: shareUrl));
                          Get.back();
                          Get.snackbar('success'.tr, 'link_copied_clipboard'.tr);
                        },
                      ),
                      _buildShareOptionTile(
                        icon: HugeIcons.strokeRoundedMenu01,
                        title: 'more_options'.tr,
                        onTap: () {
                          Get.back();
                          SharePlus.instance.share(ShareParams(uri: Uri.parse(shareUrl)));
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8A2BE2), Color(0xFF9370DB)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () => performLivePostShare(privacy),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'share_on_your_profile'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
      isScrollControlled: true,
    );
  }

  Widget _buildShareOptionTile({
    required dynamic icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: AppColors.textMain, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMain,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          : null,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
