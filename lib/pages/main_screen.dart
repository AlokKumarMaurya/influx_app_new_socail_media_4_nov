import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:influx_app/config/app_config.dart';
import 'package:influx_app/pages/auth/verify_otp.dart';
import 'package:influx_app/pages/fan_page/jobs/all_jobs_explore_page.dart';
import 'marketplace/mall_products_page.dart';
import '../utils/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../controllers/main_controller.dart';
import 'feed/feed_page.dart';
import '../controllers/feed_controller.dart';
import 'discover/discover_home_page.dart';
import 'watch/watch_page.dart';
import 'user/profile_page.dart';
import 'user/friends_page.dart';
import 'user/notifications_page.dart';
import 'feed/groups_page.dart';
import 'feed/search_page.dart';
import 'feed/create_post_page.dart';
import 'story/create_story_page.dart';
import 'feed/create_group_page.dart';
import '../controllers/notification_controller.dart';
import 'chat/conversations_page.dart';
import 'marketplace/marketplace_page.dart';
import 'marketplace/create_listing_page.dart';
import 'fan_page/fan_pages_list_page.dart';
import 'live/go_live_setup_page.dart';
import '../data/providers/api_client.dart';
import 'package:get_storage/get_storage.dart';
import '../widgets/common/news_ticker_widget.dart';
import '../controllers/feature_controller.dart';
import '../controllers/call_controller.dart';
import '../widgets/chat/minimized_call_overlay.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  void _showAddBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildBottomSheetItem(
                  icon: HugeIcons.strokeRoundedEdit02,
                  title: 'create_post'.tr,
                  subtitle: 'share_thoughts_community'.tr,
                  onTap: () {
                    Get.back();
                    Get.to(() => const CreatePostPage());
                  },
                ),
                _buildBottomSheetItem(
                  icon: HugeIcons.strokeRoundedCamera01,
                  title: 'add_story'.tr,
                  subtitle: 'share_photo_video_disappears'.tr,
                  onTap: () {
                    Get.back();
                    Get.to(() => const CreateStoryPage());
                  },
                ),
                if (FeatureController.to.isFeatureEnabled('live_streaming'))
                  _buildBottomSheetItem(
                    icon: HugeIcons.strokeRoundedVideo02,
                    title: '🔴 Go Live',
                    subtitle: 'Broadcast live video & receive gifts or tips',
                    onTap: () {
                      Get.back();
                      Get.to(() => const GoLiveSetupPage());
                    },
                  ),
                if (FeatureController.to.isFeatureEnabled('groups_system'))
                  _buildBottomSheetItem(
                    icon: HugeIcons.strokeRoundedUserGroup,
                    title: 'create_group'.tr,
                    subtitle: 'start_new_community'.tr,
                    onTap: () {
                      Get.back();
                      Get.to(() => const CreateGroupPage());
                    },
                  ),
                if (FeatureController.to.isFeatureEnabled('marketplace_system'))
                  _buildBottomSheetItem(
                    icon: HugeIcons.strokeRoundedShoppingBag01,
                    title: 'sell_something'.tr,
                    subtitle: 'list_item_marketplace'.tr,
                    onTap: () {
                      Get.back();
                      Get.to(() => const CreateListingPage());
                    },
                  ),
                if (FeatureController.to.isFeatureEnabled('pages_system'))
                  _buildBottomSheetItem(
                    icon: HugeIcons.strokeRoundedFlag02,
                    title: 'Pages & Businesses',
                    subtitle: 'Discover, follow or create fan pages',
                    onTap: () {
                      Get.back();
                      Get.to(() => const FanPagesListPage());
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCountryPickerSheet(BuildContext context) {
    final GetStorage storage = GetStorage();
    final RxString selectedCountry =
        (storage.read('selected_country') as String? ?? 'all').obs;
    final RxList<Map<String, String>> countryList = <Map<String, String>>[
      {'code': 'all', 'name': 'all_countries'.tr, 'flag': '🌐'},
    ].obs;
    final RxBool isLoading = true.obs;

    // Fetch full dynamic countries list from DB via API
    ApiClient().dio
        .get('/countries')
        .then((response) {
          if (response.data != null && response.data['data'] != null) {
            final list = response.data['data'] as List;
            final formatted = list
                .map(
                  (item) => {
                    'code': item['code'].toString(),
                    'name': item['name'].toString(),
                    'flag': (item['flag'] ?? '🏳️').toString(),
                  },
                )
                .toList();

            countryList.value = [
              {'code': 'all', 'name': 'all_countries'.tr, 'flag': '🌐'},
              ...formatted,
            ];
          }
        })
        .catchError((e) {
          Get.log('Error fetching country list: $e');
        })
        .whenComplete(() {
          isLoading.value = false;
        });

    final RxString searchQuery = ''.obs;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text('filter_by_country'.tr, style: AppTextStyles.h4),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                onChanged: (val) => searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'search_country'.tr,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: AppColors.isDark
                      ? Colors.white10
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (isLoading.value && countryList.length <= 1) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = searchQuery.value.toLowerCase().trim();
                final filtered = countryList.where((item) {
                  if (query.isEmpty) return true;
                  final name = (item['name'] ?? '').toLowerCase();
                  final code = (item['code'] ?? '').toLowerCase();
                  return name.contains(query) || code.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'no_country_found'.tr,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final code = item['code'] ?? 'all';
                    final name = item['name'] ?? '';
                    final flag = item['flag'] ?? '🌐';
                    final isSelected =
                        selectedCountry.value.toLowerCase() ==
                        code.toLowerCase();

                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMain,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        selectedCountry.value = code;
                        storage.write('selected_country', code);
                        storage.write('selected_country_chosen', true);
                        Get.back();
                        if (Get.isRegistered<FeedController>()) {
                          Get.find<FeedController>().loadFeed();
                        }
                        Get.snackbar(
                          'country_filter_updated'.tr,
                          '${'showing_content_for'.tr} $name',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildBottomSheetItem({
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainController());
    final notifController = Get.put(NotificationController());
    final featureCtrl = Get.put(FeatureController());
    Get.put(CallController(), permanent: true);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final GetStorage storage = GetStorage();
      final bool hasChosen = storage.read('selected_country_chosen') ?? false;
      if (!hasChosen) {
        _showCountryPickerSheet(context);
      }
    });

    return Obx(() {
      final isWatchEnabled = featureCtrl.isFeatureEnabled('watch_system');
      final isGroupsEnabled = featureCtrl.isFeatureEnabled('groups_system');
      final isCreatorCampaignsEnabled = featureCtrl.isFeatureEnabled(
        'creator_campaigns',
      );

      final List<Widget> pages = [
        FeedPage(onMenuTap: () => scaffoldKey.currentState?.openDrawer()),
        if (isWatchEnabled) const WatchPage(),
        if (isCreatorCampaignsEnabled)
          DiscoverHomePage(
            onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
          ),
        const FriendsPage(),
        const MallProductsPage(),

        FanPagesListPage(),
        // const ProfilePage(),
        const NotificationsPage(),
        AllJobsExplorePage(),
        // if (isGroupsEnabled) const GroupsPage(),
      ];

      final List<Widget> tabsList = [
        const Tab(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedHome01,
            color: Colors.white,
            size: 24,
          ),
        ),
        if (isWatchEnabled)
          const Tab(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPlayList,
              color: Colors.white,
              size: 24,
            ),
          ),
        if (isCreatorCampaignsEnabled)
          const Tab(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCompass01,
              color: Colors.white,
              size: 24,
            ),
          ),
        const Tab(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedUserMultiple,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Tab(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedShoppingBag01,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Tab(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedBuilding01,
            color: Colors.white,
            size: 24,
          ),
        ),
        Tab(
          icon: _buildTabIconWithBadge(
            HugeIcons.strokeRoundedNotification01,
            notifController.unreadCount.value,
          ),
        ),
        // if (isGroupsEnabled)
        //   const Tab(
        //     icon: HugeIcon(
        //       icon: HugeIcons.strokeRoundedUserGroup,
        // color: Colors.white,
        //       size: 24,
        //     ),
        //   ),
        const Tab(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedNewJob,
            color: Colors.white,
            size: 24,
          ),
        ),
      ];

      return DefaultTabController(
        length: tabsList.length,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await controller.handleBack();
            if (shouldPop) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: AppColors.background,
            drawer: const AppDrawer(),
            appBar: AppBar(
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFD8000),
                      Color(0xFFFFFFFF),
                      Color(0xFF138808),
                    ],
                    stops: [0.0, 0.65, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              backgroundColor: AppColors.cardBg,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMenu01,
                  color: AppColors.textMain,
                  size: 24,
                ),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                AppConfig.appName,
                style: TextStyle(
                  color: const Color(0xFF1877F2),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              actions: [
                if (featureCtrl.isFeatureEnabled('marketplace_system'))
                  _buildAppBarAction(
                    HugeIcons.strokeRoundedShoppingBag01,
                    () => Get.to(() => const MarketplacePage()),
                  ),
                _buildAppBarAction(
                  HugeIcons.strokeRoundedAdd01,
                  () => _showAddBottomSheet(context),
                ),
                _buildAppBarAction(
                  HugeIcons.strokeRoundedSearch01,
                  () => Get.to(() => const SearchPage()),
                ),
                if (featureCtrl.isFeatureEnabled('chat_system'))
                  _buildAppBarAction(
                    HugeIcons.strokeRoundedMessage01,
                    () => Get.to(() => const ConversationsPage()),
                    badgeCount: notifController.msgUnreadCount.value,
                  ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    onTap: (index) => controller.changeIndex(index),
                    indicatorColor: const Color(0xFFFFFFFF),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFFFFFFFF),
                    unselectedLabelColor: AppColors.textSecondary.withValues(
                      alpha: 0.6,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: tabsList,
                  ),
                ),
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    if (featureCtrl.isFeatureEnabled('news_ticker'))
                      const NewsTickerWidget(),
                    Expanded(
                      child: TabBarView(
                        physics: const PageScrollPhysics(),
                        // physics: const NeverScrollableScrollPhysics(),
                        children: pages,
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: MinimizedCallOverlay(),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAppBarAction(
    dynamic icon,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: AppColors.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: onTap,
            icon: HugeIcon(icon: icon, color: AppColors.textMain, size: 20),
          ),
        ),
        if (badgeCount > 0)
          Positioned(right: -2, top: -2, child: _buildBadge(badgeCount)),
      ],
    );
  }

  Widget _buildTabIconWithBadge(dynamic icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        HugeIcon(icon: icon, color: Colors.white, size: 24),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: _buildBadge(count, small: true),
          ),
      ],
    );
  }

  Widget _buildBadge(int count, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 4 : 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 8 : 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
