import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/call_controller.dart';
import '../../data/providers/api_client.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_avatar.dart';

class CallLogsPage extends StatefulWidget {
  final bool showAppBar;
  const CallLogsPage({super.key, this.showAppBar = true});

  @override
  State<CallLogsPage> createState() => _CallLogsPageState();
}

class _CallLogsPageState extends State<CallLogsPage> {
  final ApiClient _apiClient = ApiClient();
  final CallController _callController = Get.put(CallController(), permanent: true);

  final RxList<Map<String, dynamic>> _callLogs = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = true.obs;
  final RxString _errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    fetchCallLogs();
  }

  Future<void> fetchCallLogs() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final response = await _apiClient.dio.get('/chat/call/logs');
      if (response.data != null && response.data['status'] == 'success') {
        final List list = response.data['data'] ?? [];
        _callLogs.assignAll(list.map((e) => Map<String, dynamic>.from(e)).toList());
      } else {
        _errorMessage.value = response.data['message'] ?? 'Failed to load call logs';
      }
    } catch (e) {
      _errorMessage.value = 'Network error fetching call logs';
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.isDark ? AppColors.background : const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                'Call Logs',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.cardBg,
            )
          : null,
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage.value, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: fetchCallLogs,
                  child: Text('retry'.tr),
                )
              ],
            ),
          );
        }

        if (_callLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedTelephone,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'no_call_history'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'no_call_history_desc'.tr,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: fetchCallLogs,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _callLogs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              color: AppColors.textSecondary.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final log = _callLogs[index];
              final otherUser = log['other_user'] as Map<String, dynamic>?;
              if (otherUser == null) return const SizedBox.shrink();

              final isVideo = log['call_type'] == 'video';
              final isCaller = log['is_caller'] == true;
              final isMissed = log['is_missed'] == true;
              final durationStr = log['formatted_duration']?.toString() ?? '';
              final timeStr = log['created_at_formatted']?.toString() ?? log['time']?.toString() ?? '';

              IconData iconData;
              Color iconColor;

              if (isMissed) {
                iconData = Icons.call_missed_rounded;
                iconColor = Colors.red;
              } else if (isCaller) {
                iconData = Icons.call_made_rounded;
                iconColor = AppColors.primary;
              } else {
                iconData = Icons.call_received_rounded;
                iconColor = Colors.green;
              }

              return Container(
                color: AppColors.cardBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar
                    CustomAvatar(
                      avatarUrl: otherUser['avatar'],
                      name: otherUser['name'] ?? 'User',
                      radius: 24,
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherUser['name'] ?? 'User',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(iconData, color: iconColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${isCaller ? "outgoing".tr : "incoming".tr} ${isVideo ? "video".tr : "audio".tr}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (durationStr.isNotEmpty) ...[
                                Text(
                                  ' • $durationStr',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Call Back Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            _callController.initiateCall(
                              receiverId: otherUser['id'],
                              type: 'voice',
                              conversationId: log['conversation_id'],
                              receiverName: otherUser['name'],
                              receiverAvatar: otherUser['avatar'],
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_rounded, color: Colors.green, size: 18),
                          ),
                          tooltip: 'audio_call_back'.tr,
                        ),
                        Obx(() {
                          if (!_callController.videoEnabled.value) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            onPressed: () {
                              _callController.initiateCall(
                                receiverId: otherUser['id'],
                                type: 'video',
                                conversationId: log['conversation_id'],
                                receiverName: otherUser['name'],
                                receiverAvatar: otherUser['avatar'],
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.videocam_rounded, color: AppColors.primary, size: 18),
                            ),
                            tooltip: 'video_call_back'.tr,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
