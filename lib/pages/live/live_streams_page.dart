import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/live_stream_controller.dart';
import '../../data/models/live_stream_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../user/notifications_page.dart';
import 'go_live_setup_page.dart';
import 'live_room_page.dart';

class LiveStreamsPage extends StatefulWidget {
  const LiveStreamsPage({super.key});

  @override
  State<LiveStreamsPage> createState() => _LiveStreamsPageState();
}

class _LiveStreamsPageState extends State<LiveStreamsPage> {
  late final LiveStreamController _controller;
  bool _showSearchBar = false;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, String>> _pills = const [
    {'filter': 'popular', 'category': 'all', 'label': 'Popular'},
    {'filter': 'live_now', 'category': 'all', 'label': 'Live Now'},
    {'filter': 'ended', 'category': 'all', 'label': 'Past Lives'},
    {'filter': 'nearby', 'category': 'all', 'label': 'Nearby'},
    {'filter': 'popular', 'category': 'gaming', 'label': 'Games'},
    {'filter': 'popular', 'category': 'shopping', 'label': 'Shop'},
    {'filter': 'free', 'category': 'all', 'label': 'Free'},
    {'filter': 'paid', 'category': 'all', 'label': 'VIP / Paid'},
    {'filter': 'fan_pages', 'category': 'all', 'label': 'Fan Pages'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<LiveStreamController>()
        ? Get.find<LiveStreamController>()
        : Get.put(LiveStreamController());
    _controller.fetchStreams();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authUser = Get.find<AuthController>().user.value;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0D14) : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF8B5CF6),
          onRefresh: () => _controller.fetchStreams(),
          child: CustomScrollView(
            slivers: [
              // 1. Reference-Matched Greeting Header ("Welcome back, <Name>" + Search & Bell/Go Live)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowLeft01,
                              size: 18,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 21,
                        backgroundImage: authUser?.avatar != null && authUser!.avatar!.isNotEmpty
                            ? CachedNetworkImageProvider(UrlUtils.getFullUrl(authUser.avatar!))
                            : null,
                        backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        child: (authUser?.avatar == null || authUser!.avatar!.isEmpty)
                            ? const HugeIcon(
                                icon: HugeIcons.strokeRoundedUser,
                                color: Color(0xFF8B5CF6),
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              authUser?.name ?? 'Creator',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildCircleIconButton(
                        hugeIcon: HugeIcons.strokeRoundedSearch01,
                        isDark: isDark,
                        onTap: () => setState(() => _showSearchBar = !_showSearchBar),
                      ),
                      const SizedBox(width: 10),
                      _buildCircleIconButton(
                        hugeIcon: HugeIcons.strokeRoundedNotification01,
                        isDark: isDark,
                        onTap: () => Get.to(() => const NotificationsPage()),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showSearchBar)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: (v) => _controller.fetchStreams(query: v),
                      decoration: InputDecoration(
                        hintText: 'Search live streams, creators or pages...',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.cardBg,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Circular Active Live Streamers Avatar Strip (Glowing Purple Ring + LIVE Pill)
              SliverToBoxAdapter(
                child: Obx(() {
                  final list = _controller.streams.where((s) => s.isLive).toList();
                  if (list.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 104,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final s = list[idx];
                        return GestureDetector(
                          onTap: () => Get.to(() => LiveRoomPage(uuid: s.uuid)),
                          child: Container(
                            width: 72,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                      width: 62,
                                      height: 62,
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: UrlUtils.getFullUrl(s.broadcasterAvatar),
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => Container(
                                            color: Colors.grey.shade800,
                                            child: const Center(
                                              child: HugeIcon(
                                                icon: HugeIcons.strokeRoundedUser,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (idx == 0)
                                      Positioned(
                                        bottom: -5,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDark ? const Color(0xFF0E0D14) : Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s.broadcasterName.split(' ').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),

              // 3. Rounded Filter Pills Row ("Popular", "Nearby", "Games", "Shop", etc.)
              SliverToBoxAdapter(
                child: Obx(() {
                  final curFilter = _controller.selectedFilter.value;
                  final curCat = _controller.selectedCategory.value;
                  return SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      itemCount: _pills.length,
                      itemBuilder: (context, i) {
                        final p = _pills[i];
                        final active = curFilter == p['filter'] && curCat == p['category'];
                        return GestureDetector(
                          onTap: () => _controller.fetchStreams(
                            filter: p['filter'],
                            category: p['category'],
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF8B5CF6)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : AppColors.cardBg),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p['label']!,
                              style: TextStyle(
                                color: active ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),

              // 4. Staggered 2-Column Bento Grid (With "Level Up Your Streaming" Card in Top-Right Slot)
              SliverToBoxAdapter(
                child: Obx(() {
                  if (_controller.isLoadingStreams.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                      ),
                    );
                  }

                  final all = _controller.streams;
                  final leftColumnStreams = <LiveStreamModel>[];
                  final rightColumnStreams = <LiveStreamModel>[];
                  for (var i = 0; i < all.length; i++) {
                    if (i.isEven) {
                      leftColumnStreams.add(all[i]);
                    } else {
                      rightColumnStreams.add(all[i]);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Staggered Column
                            Expanded(
                              child: Column(
                                children: [
                                  for (final s in leftColumnStreams)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: _buildStreamBentoCard(s, height: 225),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Right Staggered Column (Starts with "Level Up Your Streaming" Promo Card)
                            Expanded(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _buildLevelUpPromoCard(),
                                  ),
                                  for (final s in rightColumnStreams)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: _buildStreamBentoCard(s, height: 215),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (all.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 28),
                            child: Column(
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedVideo02,
                                  size: 52,
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No Active Live Streams Yet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap "Level Up Your Streaming" above to start broadcasting!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const GoLiveSetupPage()),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedVideo02,
          color: Colors.white,
          size: 20,
        ),
        label: const Text('Go Live', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required dynamic hugeIcon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        child: Center(
          child: HugeIcon(icon: hugeIcon, size: 20, color: AppColors.textMain),
        ),
      ),
    );
  }

  Widget _buildLevelUpPromoCard() {
    return GestureDetector(
      onTap: () => Get.to(() => const GoLiveSetupPage()),
      child: Container(
        height: 118,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedVideo02,
                color: Colors.white.withValues(alpha: 0.35),
                size: 26,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 10,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAward01,
                color: Colors.white.withValues(alpha: 0.35),
                size: 24,
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Level Up\nYour\nStreaming',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamBentoCard(LiveStreamModel stream, {double height = 220}) {
    final isLive = stream.isLive;
    return GestureDetector(
      onTap: () => Get.to(() => LiveRoomPage(uuid: stream.uuid)),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFF1A1825),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: UrlUtils.getFullUrl(stream.thumbnailUrl),
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: const Color(0xFF231F32),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedVideo02,
                      color: Colors.white38,
                      size: 38,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              // Top-Left Status + VIP Badge
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFFEF4444)
                            : Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(14),
                        border: isLive
                            ? null
                            : Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: isLive
                                ? HugeIcons.strokeRoundedVideo02
                                : HugeIcons.strokeRoundedClock01,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLive
                                ? 'LIVE'
                                : 'ENDED${stream.durationLabel.isNotEmpty ? ' • ${stream.durationLabel}' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stream.isPaid) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedLock,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${stream.currencySymbol ?? _controller.currencySymbol.value}${stream.entryFee.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
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
              // Top-Right Viewer / Peak Count Pill
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.92)
                        : Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedView,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLive ? '${stream.viewerCount}' : '${stream.peakViewerCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Title, Streamer Handle & Stats
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
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
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stream.broadcasterName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${stream.totalReactionsCount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedComment01,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${stream.eventsCount}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

