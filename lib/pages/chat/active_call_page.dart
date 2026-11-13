import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:influx_app/controllers/call_controller.dart';

class ActiveCallPage extends StatefulWidget {
  const ActiveCallPage({super.key});

  @override
  State<ActiveCallPage> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  final CallController controller = Get.find<CallController>();

  @override
  void initState() {
    super.initState();
    controller.ensureWakelock();
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          controller.minimizeCall();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient Gradient Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.3),
                      radius: 1.2,
                      colors: [
                        Color(0xFF1E293B),
                        Color(0xFF0F172A),
                        Color(0xFF0B0F19),
                      ],
                    ),
                  ),
                ),
              ),

              // Remote Stream Video or Voice Avatar Centerpiece
              Obx(() {
                final isVideo = controller.callType.value == 'video';
                final remoteUid = controller.remoteUid.value;
                final isRemoteVideoMuted = controller.isRemoteVideoMuted.value;

                if (isVideo && remoteUid != 0 && !isRemoteVideoMuted && controller.rtcEngine != null) {
                  return AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: controller.rtcEngine!,
                      canvas: VideoCanvas(uid: remoteUid),
                      connection: RtcConnection(channelId: controller.channelName.value),
                    ),
                  );
                }

                // Voice Call Centerpiece View
                final callerName = controller.callerData['name']?.toString() ?? 'User';
                final callerAvatar = controller.callerData['avatar']?.toString();

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isVideo ? Colors.blue.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: (callerAvatar != null && callerAvatar.isNotEmpty)
                              ? NetworkImage(callerAvatar)
                              : null,
                          child: (callerAvatar == null || callerAvatar.isEmpty)
                              ? Text(
                                  callerName.isNotEmpty ? callerName[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        callerName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          controller.isCallConnected.value
                              ? '${isVideo ? "Video" : "Voice"} Call • ${_formatDuration(controller.callDuration.value)}'
                              : 'Ringing...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: controller.isCallConnected.value ? Colors.greenAccent : Colors.amberAccent,
                          ),
                        ),
                      )),
                    ],
                  ),
                );
              }),

              // Local Video Preview PIP (ONLY visible for Video Calls)
              Obx(() {
                final isVideo = controller.callType.value == 'video';
                if (isVideo && !controller.isCameraOff.value && controller.rtcEngine != null) {
                  return Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 110,
                      height: 155,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.6), width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: controller.rtcEngine!,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Top Bar Header (Minimize Button + Timer Pill)
              Positioned(
                top: 16,
                left: 16,
                child: Row(
                  children: [
                    // Minimize Button
                    GestureDetector(
                      onTap: controller.minimizeCall,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Call Timer Pill Header
                    Obx(() {
                      final isConnected = controller.isCallConnected.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isConnected ? Colors.greenAccent : Colors.amberAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isConnected
                                  ? _formatDuration(controller.callDuration.value)
                                  : 'Ringing...',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Floating Bottom Control Bar
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Mic
                      Obx(() => GestureDetector(
                        onTap: controller.toggleMute,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: controller.isMuted.value ? Colors.amber : Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            controller.isMuted.value ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      )),

                      // Toggle Speakerphone
                      Obx(() => GestureDetector(
                        onTap: controller.toggleSpeaker,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: controller.isSpeakerOn.value ? const Color(0xFF3B82F6) : Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            controller.isSpeakerOn.value ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      )),

                      // Switch Camera (if Video Call)
                      Obx(() {
                        if (controller.callType.value == 'video') {
                          return GestureDetector(
                            onTap: controller.switchCamera,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 22),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // Toggle Camera (if Video Call)
                      Obx(() {
                        if (controller.callType.value == 'video') {
                          return GestureDetector(
                            onTap: controller.toggleCamera,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: controller.isCameraOff.value ? Colors.amber : Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.isCameraOff.value ? Icons.videocam_off : Icons.videocam,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      // End Call Button
                      GestureDetector(
                        onTap: controller.endCall,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Color(0x66EF4444), blurRadius: 12, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
