import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import '../controllers/settings_controller.dart';
import '../data/models/live_stream_model.dart';
import '../data/services/live_stream_service.dart';
import '../pages/live/live_room_page.dart';
import '../pages/live/go_live_setup_page.dart';
import '../utils/app_theme.dart';

class ProfileLiveStreamsTab extends StatefulWidget {
  final int? userId;
  final int? fanPageId;
  final String? fanPageName;
  final bool isOwner;

  const ProfileLiveStreamsTab({
    super.key,
    this.userId,
    this.fanPageId,
    this.fanPageName,
    this.isOwner = false,
  });

  @override
  State<ProfileLiveStreamsTab> createState() => _ProfileLiveStreamsTabState();
}

class _ProfileLiveStreamsTabState extends State<ProfileLiveStreamsTab> {
  final LiveStreamService _service = LiveStreamService();
  List<LiveStreamModel> _streams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getStreams(
        userId: widget.userId,
        fanPageId: widget.fanPageId,
        includeEnded: true,
      );
      if (mounted) {
        setState(() {
          _streams = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_streams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedVideo02,
                    size: 32,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No Live Broadcasts Yet',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isOwner
                    ? 'Active and ended live streams with audience stats will appear here.'
                    : 'No live broadcasts have been streamed yet.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (widget.isOwner) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Get.to(
                      () => GoLiveSetupPage(
                        initialFanPageId: widget.fanPageId,
                        initialFanPageName: widget.fanPageName,
                      ),
                    );
                    _loadStreams();
                  },
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedVideo02,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('Start Live Broadcast'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _streams.length,
        itemBuilder: (context, index) {
          final stream = _streams[index];
          final isLive = stream.status == 'live';

          return GestureDetector(
            onTap: () => Get.to(() => LiveRoomPage(uuid: stream.uuid)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 16:9 Thumbnail Stage
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: stream.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xFF1E1B4B),
                            child: const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedVideo02,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black45,
                                Colors.transparent,
                                Colors.black87,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isLive
                                      ? Colors.redAccent
                                      : Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: isLive
                                          ? HugeIcons.strokeRoundedVideo02
                                          : HugeIcons.strokeRoundedClock01,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isLive
                                          ? 'LIVE NOW'
                                          : 'ENDED • ${stream.durationLabel}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (stream.isPaid) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const HugeIcon(
                                        icon: HugeIcons.strokeRoundedLock,
                                        size: 12,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${stream.currencySymbol ?? (Get.isRegistered<SettingsController>() ? Get.find<SettingsController>().currencySymbol.value : '\$')}${stream.entryFee.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedView,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isLive
                                      ? '${stream.viewerCount} watching'
                                      : '${stream.peakViewerCount} peak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stream.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isLive
                                    ? 'Started ${stream.startedAt ?? "just now"}'
                                    : 'Streamed ${stream.startedAt ?? ""} ${stream.endedAt != null ? "• Ended ${stream.endedAt}" : ""}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Metrics & Details Row
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatChip(
                              'Peak Viewers',
                              '${stream.peakViewerCount}',
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip('Duration', stream.durationLabel),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              'Reactions',
                              '${stream.totalReactionsCount}',
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              'Chat & Gifts',
                              '${stream.eventsCount}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.isOwner && stream.totalEarnings > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedWallet01,
                                      size: 12,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Earned ${stream.currencySymbol ?? (Get.isRegistered<SettingsController>() ? Get.find<SettingsController>().currencySymbol.value : '\$')}${stream.totalEarnings.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                isLive
                                    ? 'Broadcasting Live'
                                    : 'Recorded Broadcast Summary',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: isLive
                                      ? HugeIcons.strokeRoundedVideo02
                                      : HugeIcons.strokeRoundedChartHistogram,
                                  size: 14,
                                  color: const Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isLive ? 'Watch Live →' : 'View Details →',
                                  style: const TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

