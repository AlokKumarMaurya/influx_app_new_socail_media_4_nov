import 'package:flutter/src/material/app.dart';
import 'package:material_ui/material_ui.dart' hide ThemeMode;
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../utils/app_theme.dart';
import '../controllers/auth_controller.dart';
import '../controllers/main_controller.dart';
import '../controllers/settings_controller.dart';
import '../pages/chat/call_logs_page.dart';
import '../pages/user/settings_page.dart';
import '../pages/user/profile_page.dart';
import '../pages/marketplace/marketplace_page.dart';
import '../pages/wallet/wallet_page.dart';
import '../pages/user/badge_shop_page.dart';
import '../pages/discover/discover_creators_page.dart';
import '../pages/blog/blogs_page.dart';
import '../pages/campaign/campaign_directory_page.dart';
import '../pages/campaign/my_campaigns_page.dart';
import '../pages/user/memories_page.dart';
import '../pages/common/common_things_page.dart';
import '../pages/user/saved_items_page.dart';
import '../pages/support/support_tickets_page.dart';
import '../pages/forum/forum_index_page.dart';
import '../pages/threads/threads_feed_page.dart';
import '../pages/feed/search_page.dart';
import '../pages/events/events_page.dart';
import '../pages/creator/creator_dashboard_page.dart';
import '../pages/custom_page/custom_page_view.dart';
import '../pages/fan_page/fan_pages_list_page.dart';
import '../pages/fan_page/fan_page_inbox_page.dart';
import '../pages/fan_page/jobs/all_jobs_explore_page.dart';
import '../pages/fan_page/jobs/my_job_applications_page.dart';
import '../pages/live/live_streams_page.dart';
import '../controllers/custom_page_controller.dart';
import '../controllers/feature_controller.dart';
import '../controllers/language_controller.dart';
import './common/custom_network_image.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showLanguageBottomSheet(BuildContext context, LanguageController langCtrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_language'.tr,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                title: const Text('English'),
                trailing: langCtrl.currentLocale.value.languageCode == 'en'
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  langCtrl.changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇧🇩', style: TextStyle(fontSize: 22)),
                title: const Text('Bengali (বাংলা)'),
                trailing: langCtrl.currentLocale.value.languageCode == 'bn'
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  langCtrl.changeLanguage('bn');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇮🇹', style: TextStyle(fontSize: 22)),
                title: const Text('Italian (Italiano)'),
                trailing: langCtrl.currentLocale.value.languageCode == 'it'
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  langCtrl.changeLanguage('it');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final settingsController = Get.find<SettingsController>();
    final featureCtrl = Get.put(FeatureController());

    return Obx(() => Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          _buildHeader(authController),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildDrawerItem(
                  HugeIcons.strokeRoundedUser,
                  'my_profile'.tr,
                  () {
                    Navigator.pop(context);
                    Get.to(() => const ProfilePage());
                  },
                ),
                _buildDrawerItem(
                  HugeIcons.strokeRoundedTelephone,
                  'call_logs'.tr,
                  () {
                    Navigator.pop(context);
                    Get.to(() => const CallLogsPage());
                  },
                ),
                if (featureCtrl.isFeatureEnabled('live_streaming'))
                  _buildDrawerItem(
                    HugeIcons.strokeRoundedVideo02,
                    '🔴 Live Streams',
                    () {
                      Navigator.pop(context);
                      Get.to(() => const LiveStreamsPage());
                    },
                  ),
                _buildDrawerItem(
                  HugeIcons.strokeRoundedHome01,
                  'home_feed'.tr,
                  () {
                    final tabCtrl = DefaultTabController.of(context);
                    Navigator.pop(context);
                    tabCtrl.animateTo(0);
                    Get.find<MainController>().changeIndex(0);
                  },
                ),
                Obx(() => featureCtrl.isFeatureEnabled('creator_campaigns')
                    ? Column(
                        children: [
                          _buildDrawerItem(
                            HugeIcons.strokeRoundedCompass01,
                            'creator_campaign'.tr,
                            () {
                              final tabCtrl = DefaultTabController.of(context);
                              Navigator.pop(context);
                              tabCtrl.animateTo(1);
                              Get.find<MainController>().changeIndex(1);
                            },
                          ),
                          _buildDrawerItem(
                            HugeIcons.strokeRoundedMegaphone02,
                            'campaigns'.tr,
                            () {
                              Navigator.pop(context);
                              Get.to(() => const CampaignDirectoryPage());
                            },
                          ),
                          _buildDrawerItem(
                            HugeIcons.strokeRoundedBriefcase02,
                            'my_campaigns'.tr,
                            () {
                              Navigator.pop(context);
                              Get.to(() => const MyCampaignsPage());
                            },
                          ),
                          if (authController.user.value?.profileType == 'creator' || authController.user.value?.kycStatus == 'approved')
                            _buildDrawerItem(
                              HugeIcons.strokeRoundedChartHistogram,
                              'creator_dashboard'.tr,
                              () {
                                Navigator.pop(context);
                                Get.to(() => const CreatorDashboardPage());
                              },
                            ),
                          _buildDrawerItem(
                            HugeIcons.strokeRoundedUserMultiple02,
                            'discover_creators'.tr,
                            () {
                              Navigator.pop(context);
                              Get.to(() => const DiscoverCreatorsPage());
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink()),
                _buildDrawerItem(
                  HugeIcons.strokeRoundedSearch01,
                  'explore'.tr,
                  () {
                    Navigator.pop(context);
                    Get.to(() => const SearchPage());
                  },
                ),
                Obx(() => featureCtrl.isFeatureEnabled('pages_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedFlag02,
                        'Company',
                        () {
                          Navigator.pop(context);
                          Get.to(() => const FanPagesListPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('pages_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedMail01,
                        'Page Inbox',
                        () {
                          Navigator.pop(context);
                          Get.to(() => const FanPageInboxHubPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('pages_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedBriefcase02,
                        'Jobs & Careers',
                        () {
                          Navigator.pop(context);
                          Get.to(() => const AllJobsExplorePage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('pages_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedDocumentValidation,
                        'My Applications',
                        () {
                          Navigator.pop(context);
                          Get.to(() => const MyJobApplicationsPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('marketplace_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedShoppingBag01,
                        'marketplace'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const MarketplacePage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('wallet_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedWallet01,
                        'wallet'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const WalletPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('badge_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedAward01,
                        'badge_shop'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const BadgeShopPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('blogs_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedNews,
                        'news_and_blogs'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const BlogsPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('events_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedCalendar01,
                        'events'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const EventsPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('memories_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedCalendar03,
                        'memories'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const MemoriesPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('common_things_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedUserGroup,
                        'common_things'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const CommonThingsPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('saved_posts_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedBookmark01,
                        'saved_items'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const SavedItemsPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('forum_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedBubbleChatDelay,
                        'community_forum'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const ForumIndexPage());
                        },
                      )
                    : const SizedBox.shrink()),
                Obx(() => featureCtrl.isFeatureEnabled('threads_system')
                    ? _buildDrawerItem(
                        HugeIcons.strokeRoundedAlignLeft,
                        'threads'.tr,
                        () {
                          Navigator.pop(context);
                          Get.to(() => const ThreadsFeedPage());
                        },
                      )
                    : const SizedBox.shrink()),
                _buildDrawerItem(
                  HugeIcons.strokeRoundedLifebuoy,
                  'help_and_support'.tr,
                  () {
                    Navigator.pop(context);
                    Get.to(() => const SupportTicketsPage());
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Divider(),
                ),
                Obx(() {
                  final customPageCtrl = Get.put(CustomPageController());
                  if (customPageCtrl.isLoading.value && customPageCtrl.pages.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                  }
                  return Column(
                    children: customPageCtrl.pages.map((page) => _buildDrawerItem(
                      HugeIcons.strokeRoundedDocumentAttachment,
                      page['title'] ?? 'Page',
                      () {
                        Navigator.pop(context);
                        Get.to(() => CustomPageView(
                          slug: page['slug'] ?? '',
                          title: page['title'] ?? '',
                        ));
                      },
                    )).toList(),
                  );
                }),
                Obx(() {
                  final customPageCtrl = Get.put(CustomPageController());
                  if (customPageCtrl.pages.isNotEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Divider(),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Obx(() {
                  final langCtrl = Get.find<LanguageController>();
                  return ListTile(
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedGlobal,
                      color: AppColors.textMain,
                      size: 24,
                    ),
                    title: Text(
                      'language'.tr,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      langCtrl.currentLocale.value.languageCode == 'bn'
                          ? 'Bengali (বাংলা)'
                          : (langCtrl.currentLocale.value.languageCode == 'it'
                              ? 'Italian (Italiano)'
                              : 'English'),
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade500),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    onTap: () {
                      _showLanguageBottomSheet(context, langCtrl);
                    },
                  );
                }),
                Obx(() => SwitchListTile(
                  secondary: HugeIcon(
                    icon: settingsController.themeMode.value == ThemeMode.dark
                        ? HugeIcons.strokeRoundedMoon01
                        : HugeIcons.strokeRoundedSun01,
                    color: AppColors.textMain,
                    size: 24,
                  ),
                  title: Text(
                    settingsController.themeMode.value == ThemeMode.dark
                        ? 'dark_mode'.tr
                        : 'light_mode'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: settingsController.themeMode.value == ThemeMode.dark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (bool isDark) {
                    settingsController.changeTheme(
                      (isDark ? ThemeMode.dark : ThemeMode.light),
                    );
                  },
                )),
                _buildDrawerItem(
                  HugeIcons.strokeRoundedSettings01,
                  'settings'.tr,
                  () {
                    Navigator.pop(context);
                    Get.to(() => const SettingsPage());
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Divider(),
                ),
                _buildDrawerItem(
                  HugeIcons.strokeRoundedLogout01,
                  'logout'.tr,
                  () {
                    authController.logout();
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'v1.0.0',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildHeader(AuthController authController) {
    return Obx(() {
      final user = authController.user.value;
      return GestureDetector(
        onTap: () {
          Get.back();
          Get.to(() => const ProfilePage());
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.cardBg,
                  child: ClipOval(
                    child: user?.avatar != null && user!.avatar!.isNotEmpty
                        ? CustomNetworkImage(
                            imageUrl: user.avatar!,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            color: AppColors.primary,
                            size: 40,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user?.name ?? 'Guest User',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.primary,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Connect with the world',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMain.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDrawerItem(
    dynamic icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: color ?? AppColors.textMain, size: 24),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: color ?? AppColors.textMain,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
