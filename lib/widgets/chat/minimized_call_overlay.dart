import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:influx_app/controllers/call_controller.dart';

class MinimizedCallOverlay extends StatelessWidget {
  const MinimizedCallOverlay({super.key});

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final CallController controller = Get.find<CallController>();

    return Obx(() {
      if (!controller.hasActiveCall.value || !controller.isMinimized.value) {
        return const SizedBox.shrink();
      }

      final callerName = controller.callerData['name']?.toString() ?? 'User';
      final callerAvatar = controller.callerData['avatar']?.toString();
      final isVideo = controller.callType.value == 'video';
      final isConnected = controller.isCallConnected.value;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Material(
            elevation: 12,
            color: Colors.transparent,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: controller.expandCall,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isConnected ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.amberAccent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with status pulse
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: (callerAvatar != null && callerAvatar.isNotEmpty)
                              ? NetworkImage(callerAvatar)
                              : null,
                          child: (callerAvatar == null || callerAvatar.isEmpty)
                              ? Text(
                                  callerName.isNotEmpty ? callerName[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isConnected ? Colors.greenAccent : Colors.amberAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // User Info & Timer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            callerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isConnected
                                ? '${isVideo ? "Video" : "Voice"} Call • ${_formatDuration(controller.callDuration.value)}'
                                : 'Ringing...',
                            style: TextStyle(
                              color: isConnected ? Colors.greenAccent : Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mute Button
                        Obx(() => GestureDetector(
                          onTap: controller.toggleMute,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: controller.isMuted.value ? Colors.amber : Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              controller.isMuted.value ? Icons.mic_off : Icons.mic,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )),
                        const SizedBox(width: 8),

                        // End Call Button
                        GestureDetector(
                          onTap: controller.endCall,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Expand Button Icon
                        const Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
