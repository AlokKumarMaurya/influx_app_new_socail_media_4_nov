import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/feed/ad_card.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../feed/media_viewer_page.dart';
import '../user/settings_page.dart';
import '../../data/models/feed_item.dart';
import '../../data/models/post_model.dart';
import '../../widgets/common/professional_badge.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/conversation_model.dart';
import '../chat/chat_page.dart';
import '../marketplace/seller_shop_page.dart';
import 'badge_shop_page.dart';
import '../../controllers/feature_controller.dart';
import '../../widgets/profile_live_streams_tab.dart';

class ProfilePage extends StatefulWidget {
  final int? userId;
  final String? username;
  const ProfilePage({super.key, this.userId, this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late ProfileController controller;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final FeatureController featureCtrl = Get.put(FeatureController());

  String get _tagKey {
    if (widget.userId != null && widget.userId! > 0) {
      return 'profile_${widget.userId}';
    }
    if (widget.username != null && widget.username!.trim().isNotEmpty) {
      return 'profile_u_${widget.username!.trim().toLowerCase().replaceAll('@', '')}';
    }
    final auth = Get.find<AuthController>();
    return 'profile_${auth.user.value?.id ?? 0}';
  }

  dynamic get _targetIdentifier {
    if (widget.userId != null && widget.userId! > 0) {
      return widget.userId;
    }
    if (widget.username != null && widget.username!.trim().isNotEmpty) {
      return widget.username!.trim().replaceFirst('@', '');
    }
    final auth = Get.find<AuthController>();
    return auth.user.value?.id ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _scrollController.addListener(() {
      final int id = controller.profile.value?.id ?? widget.userId ?? 0;
      if (id > 0 &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200) {
        if (Get.isRegistered<ProfileController>(tag: _tagKey)) {
          Get.find<ProfileController>(tag: _tagKey).loadPosts(id);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadProfile();
    });
  }

  void _checkAndLoadProfile() {
    final target = _targetIdentifier;
    if (target != null && target != 0 && target != '') {
      controller = Get.put(ProfileController(), tag: _tagKey);
      if (controller.profile.value == null && !controller.isProfileFetching) {
        controller.loadProfile(target, showSkeleton: true);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final target = _targetIdentifier;

      if (target == null || target == 0 || target == '') {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      controller = Get.put(ProfileController(), tag: _tagKey);

      if (controller.profile.value == null && !controller.isProfileFetching) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.loadProfile(target, showSkeleton: true);
        });
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: () => controller.loadProfile(
            target,
            isSilent: true,
            showSkeleton: true,
          ),
          child: controller.isLoading.value
              ? _buildProfileSkeleton()
              : controller.profile.value == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'profile_not_found'.tr,
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => controller.loadProfile(target, showSkeleton: true),
                        child: Text('retry'.tr),
                      )
                    ],
                  ),
                )
              : NestedScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    final profile = controller.profile.value!;
                    return [
                      _buildHeaderSection(context, profile),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _buildStatsBar(profile),
                            _buildActionButtons(profile),
                            const Divider(height: 1, thickness: 1),
                          ],
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: 'posts'.tr),
                              Tab(text: 'about'.tr),
                              Tab(text: 'friends'.tr),
                              Tab(text: 'media'.tr),
                              const Tab(text: 'Live Videos'),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsTab(),
                      _buildAboutTab(controller.profile.value!),
                      _buildFriendsTab(),
                      _buildMediaTab(),
                      ProfileLiveStreamsTab(
                        userId: controller.profile.value?.id,
                        isOwner: controller.profile.value?.isOwner == true,
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildHeaderSection(BuildContext context, dynamic profile) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(
            height: 245,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Photo
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: CachedNetworkImage(
                    imageUrl:
                        profile.cover ??
                        'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2029&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                ),
                // Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ),
                // Cover Camera Button
                if (profile.isOwner)
                  Positioned(
                    right: 16,
                    bottom: 60,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.pickAndUploadPhoto('cover'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                // Back Button if can pop
                if (Navigator.of(context).canPop())
                  Positioned(
                    top: 0,
                    left: 8,
                    child: SafeArea(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                // Settings Button
                if (profile.isOwner)
                  Positioned(
                    top: 0,
                    right: 8,
                    child: SafeArea(
                      child: IconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedSettings01,
                          color: Colors.white,
                        ),
                        onPressed: () => _showEditOptions(),
                      ),
                    ),
                  ),

                // Avatar & Action Row Offset
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            const SizedBox(
                              width: 100,
                              height: 100,
                              child: CustomAvatar(radius: 50),
                            ),
                            Obx(
                              () => SizedBox(
                                width: 100,
                                height: 100,
                                child: CustomAvatar(
                                  avatarUrl: controller.profile.value?.avatar,
                                  radius: 50,
                                ),
                              ),
                            ),
                            if (profile.isOwner)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      controller.pickAndUploadPhoto('avatar'),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.background,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10), // Matches the -45 overlap spacing
          // Text Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        style: AppTextStyles.h1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ProfessionalBadge(
                      profileType: profile.profileType,
                      badgeIconUrl: profile.badgeIconUrl,
                      customBadgeIconUrl: profile.customBadgeIconUrl,
                      isBadgePrivate: profile.ownedBadges.any((b) => b.isEquipped && !b.isPublic),
                      equippedBadgeCount: profile.equippedBadgeCount,
                      size: 22,
                      showLabel: true,
                      onTap: () {
                        final equippedB = profile.ownedBadges.firstWhere(
                          (b) => b.isEquipped,
                          orElse: () => profile.ownedBadges.isNotEmpty ? profile.ownedBadges.first : null,
                        );
                        if (equippedB != null || profile.customBadgeIconUrl != null) {
                          _showBadgeDetailDialog(
                            context,
                            name: profile.equippedBadgeCount > 1
                                ? '${equippedB?.name ?? "Official Badge"} (${profile.equippedBadgeCount}x)'
                                : (equippedB?.name ?? "Official Badge"),
                            iconUrl: profile.customBadgeIconUrl ?? (equippedB?.iconUrl ?? ''),
                            description: equippedB?.description ?? 'Official profile badge.',
                            isEquipped: true,
                            isPrivate: equippedB != null ? !equippedB.isPublic : false,
                            validityPeriodLabel: equippedB?.validityPeriodLabel ?? 'Lifetime',
                            expiresAt: equippedB?.expiresAt,
                          );
                        }
                      },
                    ),
                  ],
                ),
                Text(
                  '@${profile.username}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (profile.bio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(profile.bio!, style: AppTextStyles.bodyMedium),
                  ),
                _buildOwnedBadgesSection(profile),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startChat(dynamic profile) async {
    final chatController = Get.put(ChatController());
    final result = await chatController.startConversationWith(profile.id);
    if (result != null) {
      final chatUser = ChatUser.fromJson(result['user']);
      Get.to(
        () =>
            ChatPage(conversationId: result['conversation_id'], user: chatUser),
      );
    }
  }

  void _showFriendOptions(dynamic profile) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (profile.relation == 'pending_received') ...[
              _buildBottomSheetItem(
                HugeIcons.strokeRoundedUserAdd01,
                'confirm_request'.tr,
                AppColors.primary,
                () {
                  Get.back();
                  controller.acceptFriendRequest(profile.id);
                },
              ),
              _buildBottomSheetItem(
                HugeIcons.strokeRoundedUserRemove01,
                'cancel_request'.tr,
                Colors.red,
                () {
                  Get.back();
                  controller.rejectFriendRequest(profile.id);
                },
              ),
            ] else if (profile.relation == 'friends') ...[
              _buildBottomSheetItem(
                HugeIcons.strokeRoundedUserRemove01,
                'unfriend'.tr,
                Colors.red,
                () {
                  Get.back();
                  controller.unfriendUser(profile.id);
                },
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem(
    dynamic icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: color, size: 24),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatsBar(dynamic profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('friends'.tr, profile.stats.friendsCount),
          _buildStatItem('followers'.tr, profile.stats.followersCount),
          _buildStatItem('following'.tr, profile.stats.followingCount),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(count.toString(), style: AppTextStyles.h2),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildOwnedBadgesSection(dynamic profile) {
    final List rawOwned = profile.ownedBadges ?? [];
    final List visibleOwned = rawOwned.where((b) {
      try {
        if (b is Map) {
          return b['is_visible_on_profile'] ?? true;
        }
        return b.isVisibleOnProfile ?? true;
      } catch (_) {
        return true;
      }
    }).toList();

    if (visibleOwned.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: visibleOwned.map<Widget>((b) {
          bool isPrivate = false;
          bool isEquipped = false;
          String iconUrl = '';
          String name = 'Badge';
          String? description;
          String? validityPeriodLabel;
          String? expiresAt;

          int count = 1;
          try {
            if (b is Map) {
              isPrivate = b['is_public'] == false;
              isEquipped = b['is_equipped'] == true;
              iconUrl = b['icon_url'] ?? '';
              name = b['name'] ?? 'Badge';
              description = b['description'];
              validityPeriodLabel = b['validity_period_label'];
              expiresAt = b['expires_at'];
              count = b['count'] ?? 1;
            } else {
              isPrivate = b.isPublic == false;
              isEquipped = b.isEquipped == true;
              iconUrl = b.iconUrl ?? '';
              name = b.name ?? 'Badge';
              description = b.description;
              validityPeriodLabel = b.validityPeriodLabel;
              expiresAt = b.expiresAt;
              count = b.count ?? 1;
            }
          } catch (_) {}

          final double boxSize = isPrivate ? 54.0 : 48.0;

          return GestureDetector(
            onTap: () => _showBadgeDetailDialog(
              context,
              name: count > 1 ? '$name (${count}x)' : name,
              iconUrl: iconUrl,
              description: description,
              isEquipped: isEquipped,
              isPrivate: isPrivate,
              validityPeriodLabel: validityPeriodLabel,
              expiresAt: expiresAt,
            ),
            child: Tooltip(
              message: isEquipped
                  ? '$name ${count > 1 ? "(${count}x)" : ""} (Equipped - Click to view)'
                  : '$name ${count > 1 ? "(${count}x)" : ""} (Click to view)',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: boxSize,
                    height: boxSize,
                    padding: const EdgeInsets.all(7.0),
                    decoration: BoxDecoration(
                      color: isPrivate
                          ? Colors.amber.shade50
                          : (isEquipped
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (AppColors.isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPrivate
                            ? Colors.amber.shade600
                            : (isEquipped
                                ? AppColors.primary
                                : Colors.grey.withValues(alpha: 0.25)),
                        width: isPrivate ? 2.0 : (isEquipped ? 1.5 : 1.0),
                      ),
                      boxShadow: [
                        if (isEquipped)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: iconUrl.isNotEmpty
                        ? Image.network(
                            UrlUtils.getFullUrl(iconUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.shield,
                              size: 24,
                              color: Colors.amber,
                            ),
                          )
                        : const Icon(Icons.shield, color: Colors.amber, size: 24),
                  ),
                  if (count > 1)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: Text(
                          '${count}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showBadgeDetailDialog(
    BuildContext context, {
    required String name,
    required String iconUrl,
    String? description,
    required bool isEquipped,
    required bool isPrivate,
    String? validityPeriodLabel,
    String? expiresAt,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enlarged Badge Icon
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEquipped
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEquipped ? AppColors.primary : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: iconUrl.isNotEmpty
                    ? Image.network(
                        UrlUtils.getFullUrl(iconUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, size: 64, color: Colors.amber),
                      )
                    : const Icon(Icons.shield, size: 64, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              // Badge Name
              Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('close'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(dynamic profile) {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              if (profile.isOwner) ...[
                Expanded(
                  child: _buildPrimaryAction(
                    HugeIcons.strokeRoundedEdit02,
                    'edit_profile'.tr,
                    () => Get.to(() => const SettingsPage()),
                  ),
                ),
                if (featureCtrl.isFeatureEnabled('badge_system')) ...[
                  const SizedBox(width: 8),
                  _buildSquareButton(
                    HugeIcons.strokeRoundedAward01,
                    () => Get.to(() => const BadgeShopPage()),
                  ),
                ],
              ] else ...[
                Expanded(child: _buildFriendActionButton(profile)),
                if (featureCtrl.isFeatureEnabled('chat_system')) ...[
                  const SizedBox(width: 8),
                  _buildSquareButton(
                    HugeIcons.strokeRoundedMessage02,
                    () => _startChat(profile),
                  ),
                ],
              ],
              if (featureCtrl.isFeatureEnabled('marketplace_system')) ...[
                const SizedBox(width: 8),
                _buildSquareButton(HugeIcons.strokeRoundedStore01, () {
                  final String username =
                      (profile.username != null &&
                          profile.username.toString().isNotEmpty)
                      ? profile.username.toString()
                      : profile.id.toString();
                  Get.to(() => SellerShopPage(username: username));
                }),
              ],
              const SizedBox(width: 8),
              _buildSquareButton(HugeIcons.strokeRoundedMoreHorizontal, () {}),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildFriendActionButton(dynamic profile) {
    dynamic icon;
    String label;
    Color color;
    Color textColor;

    switch (profile.relation) {
      case 'friends':
        icon = HugeIcons.strokeRoundedUserCheck01;
        label = 'friends'.tr;
        color = AppColors.isDark ? Colors.white10 : Colors.grey.shade200;
        textColor = AppColors.textMain;
        break;
      case 'pending_sent':
        icon = HugeIcons.strokeRoundedUserRemove01;
        label = 'cancel_request'.tr;
        color = AppColors.isDark ? Colors.white10 : Colors.grey.shade200;
        textColor = AppColors.textMain;
        break;
      case 'pending_received':
        icon = HugeIcons.strokeRoundedUserAdd01;
        label = 'respond'.tr;
        color = AppColors.primary;
        textColor = Colors.white;
        break;
      default:
        icon = HugeIcons.strokeRoundedUserAdd01;
        label = 'add_friend'.tr;
        color = AppColors.primary;
        textColor = Colors.white;
    }

    return InkWell(
      onTap: () {
        if (profile.relation == 'friends' ||
            profile.relation == 'pending_received') {
          _showFriendOptions(profile);
        } else {
          controller.toggleFriendAction();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ).copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryAction(dynamic icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(icon: icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton(dynamic icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.isDark ? Colors.white10 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon is IconData
            ? Icon(icon, size: 20, color: AppColors.textMain)
            : HugeIcon(icon: icon, size: 20, color: AppColors.textMain),
      ),
    );
  }

  // ─── Tabs ──────────────────

  Widget _buildPostsTab() {
    return Obx(() {
      if (controller.isPostsLoading.value && controller.posts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedNote01,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text('no_posts_yet'.tr, style: AppTextStyles.bodyLarge),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8),
        itemCount:
            controller.feedItems.length +
            (controller.hasMorePosts.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.feedItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = controller.feedItems[index];
          if (item.type == FeedItemType.ad && item.ad != null) {
            return AdCard(ad: item.ad!);
          }

          if (item.post != null) {
            return PostCard(post: item.post!);
          }

          return const SizedBox.shrink();
        },
      );
    });
  }

  Widget _buildAboutTab(dynamic profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAboutItem(
          HugeIcons.strokeRoundedBriefcase01,
          'works_at'.tr,
          profile.work ?? 'not_specified'.tr,
        ),
        _buildAboutItem(
          HugeIcons.strokeRoundedLibrary,
          'studied_at'.tr,
          profile.education ?? 'not_specified'.tr,
        ),
        _buildAboutItem(
          HugeIcons.strokeRoundedLocation01,
          'lives_in'.tr,
          profile.location ?? 'not_specified'.tr,
        ),
        _buildAboutItem(
          HugeIcons.strokeRoundedLink01,
          'website'.tr,
          profile.website ?? 'not_specified'.tr,
        ),
        const SizedBox(height: 24),
        Text('social_links'.tr, style: AppTextStyles.h3),
        const SizedBox(height: 12),
        ...profile.socialLinks.entries
            .where((e) => e.value != null && e.value!.trim().isNotEmpty)
            .map(
              (e) => _buildAboutItem(
                HugeIcons.strokeRoundedGlobe02,
                e.key.toString().capitalizeFirst ?? e.key.toString(),
                e.value!,
              ),
            ),
        if (profile.customFields != null && profile.customFields.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('additional_details'.tr, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...profile.customFields.map<Widget>((field) {
            final label = field['label']?.toString() ?? field['name']?.toString() ?? '';
            final dynamic val = field['value'];
            final displayVal = val is List ? val.join(', ') : (val?.toString() ?? '');
            return _buildAboutItem(
              HugeIcons.strokeRoundedInformationCircle,
              label,
              displayVal,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildAboutItem(dynamic icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Obx(() {
      if (controller.friends.isEmpty) {
        return Center(child: Text('no_friends_yet'.tr));
      }
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: controller.friends.length,
        itemBuilder: (context, index) {
          final friend = controller.friends[index];
          return Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomAvatar(avatarUrl: friend.avatar, radius: 40),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      friend.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (friend.profileType != null &&
                      friend.profileType != 'user') ...[
                    const SizedBox(width: 4),
                    ProfessionalBadge(
                      profileType: friend.profileType,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildMediaTab() {
    return Obx(() {
      final allMedia = [...controller.photos, ...controller.videos];
      if (allMedia.isEmpty) {
        return Center(child: Text('no_media_yet'.tr));
      }
      return GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: allMedia.length,
        itemBuilder: (context, index) {
          final media = allMedia[index];
          return GestureDetector(
            onTap: () {
              final postMediaItems = allMedia
                  .map((m) => PostMediaModel.fromJson(m))
                  .toList();
              Get.to(
                () =>
                    MediaViewerPage(media: postMediaItems, initialIndex: index),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: media['file_url'] ?? media['file_path'] ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
                if (media['file_type'] == 'video')
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  void _showEditOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('update_profile_media'.tr, style: AppTextStyles.h2),
            const SizedBox(height: 20),
            _buildEditOption(HugeIcons.strokeRoundedUser, 'update_avatar'.tr, () {
              Get.back();
              controller.pickAndUploadPhoto('avatar');
            }),
            _buildEditOption(
              HugeIcons.strokeRoundedImage01,
              'update_cover_photo'.tr,
              () {
                Get.back();
                controller.pickAndUploadPhoto('cover');
              },
            ),
            _buildEditOption(
              HugeIcons.strokeRoundedSettings01,
              'more_settings'.tr,
              () {
                Get.back();
                Get.to(() => const SettingsPage());
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildEditOption(dynamic icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: AppColors.primary),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Stack(
            clipBehavior: Clip.none,
            children: [
              SkeletonLoader(
                width: Get.width,
                height: 200,
                borderRadius: BorderRadius.zero,
              ),
              Positioned(
                bottom: -50,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    shape: BoxShape.circle,
                  ),
                  child: const SkeletonLoader(
                    width: 100,
                    height: 100,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          // Name & Bio Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: Get.width * 0.5,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: Get.width * 0.3,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                SkeletonLoader(
                  width: Get.width * 0.8,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: Get.width * 0.6,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Stats Bar Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                3,
                (index) => Column(
                  children: [
                    SkeletonLoader(
                      width: 40,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    SkeletonLoader(
                      width: 60,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Tabs Skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(width: 80, height: 30),
                SkeletonLoader(width: 80, height: 30),
                SkeletonLoader(width: 80, height: 30),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Post Skeleton
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonLoader(
                        width: 40,
                        height: 40,
                        shape: BoxShape.circle,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(
                            width: 120,
                            height: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          SkeletonLoader(
                            width: 60,
                            height: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SkeletonLoader(
                    width: Get.width,
                    height: 200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.cardBg, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
