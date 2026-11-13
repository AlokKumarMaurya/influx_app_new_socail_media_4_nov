import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';
import '../../data/models/fan_page_model.dart';
import '../../data/models/post_model.dart';
import '../../data/services/fan_page_service.dart';
import '../../widgets/feed/post_card.dart';
import '../feed/create_post_page.dart';
import '../live/go_live_setup_page.dart';
import '../../controllers/feature_controller.dart';
import '../../widgets/profile_live_streams_tab.dart';
import 'fan_page_chat_screen.dart';
import 'fan_page_inbox_page.dart';
import 'fan_page_manage_page.dart';
import 'jobs/fan_page_jobs_tab.dart';

class FanPageProfilePage extends StatefulWidget {
  final String slug;
  final FanPageModel? initialPage;

  const FanPageProfilePage({super.key, required this.slug, this.initialPage});

  @override
  State<FanPageProfilePage> createState() => _FanPageProfilePageState();
}

class _FanPageProfilePageState extends State<FanPageProfilePage> with SingleTickerProviderStateMixin {
  final FanPageService _service = FanPageService();
  late TabController _tabController;

  FanPageModel? _page;
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (widget.initialPage != null) {
      _page = widget.initialPage;
      _isFollowing = _page!.isFollowing;
      _followersCount = _page!.followersCount;
    }
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final pageData = await _service.getPageDetails(widget.slug);
      final postsData = await _service.getPagePosts(widget.slug);
      if (mounted) {
        setState(() {
          _page = pageData;
          _isFollowing = pageData.isFollowing;
          _followersCount = pageData.followersCount;
          _posts = postsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_page == null) return;
    setState(() {
      _isFollowing = !_isFollowing;
      _followersCount += _isFollowing ? 1 : -1;
    });

    try {
      final res = await _service.toggleFollow(widget.slug);
      if (mounted) {
        setState(() {
          _isFollowing = res['is_followed'] == true;
          if (res['followers'] is int) {
            _followersCount = res['followers'] as int;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _followersCount += _isFollowing ? 1 : -1;
        });
      }
    }
  }

  void _triggerCta() async {
    if (_page == null || _page!.ctaButtonType == 'none') return;
    final url = _page!.ctaButtonUrl;
    if (url != null && url.isNotEmpty) {
      Uri? uri;
      if (_page!.ctaButtonType == 'call') {
        uri = Uri.parse('tel:$url');
      } else if (_page!.ctaButtonType == 'whatsapp') {
        final clean = url.replaceAll(RegExp(r'[^0-9]'), '');
        uri = Uri.parse('https://wa.me/$clean');
      } else if (_page!.ctaButtonType == 'email') {
        uri = Uri.parse('mailto:$url');
      } else {
        uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _page == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final page = _page;
    if (page == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Page Not Found')),
        body: const Center(child: Text('Page not found or unavailable.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              title: innerBoxIsScrolled
                  ? Text(page.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  : null,
              actions: [
                if (page.canManage) ...[
                  IconButton(
                    icon: const Icon(Icons.mail_outline, color: Colors.white),
                    tooltip: 'Page Inbox',
                    onPressed: () => Get.to(() => FanPageInboxPage(page: page)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: 'Manage Page',
                    onPressed: () async {
                      await Get.to(() => FanPageManagePage(page: page));
                      _fetchDetails();
                    },
                  ),
                ],
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomNetworkImage(
                      imageUrl: page.coverPhoto,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorWidget: Container(
                        color: AppColors.primary,
                        child: const Center(child: Icon(Icons.flag, size: 48, color: Colors.white38)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: ClipOval(
                              child: CustomNetworkImage(
                                imageUrl: page.avatar,
                                fit: BoxFit.cover,
                                width: 72,
                                height: 72,
                                shape: BoxShape.circle,
                                errorWidget: Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.flag, size: 36, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      page.name,
                                      style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (page.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, size: 18, color: Colors.blue),
                                  ],
                                ],
                              ),
                              if (page.category != null)
                                Text(
                                  page.category!.name,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              Text(
                                '$_followersCount followers • ${page.postsCount} posts',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (page.bio != null && page.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(page.bio!, style: AppTextStyles.bodyMedium),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (page.canManage) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Get.to(() => FanPageInboxPage(page: page)),
                              icon: const Icon(Icons.mail_outline, size: 16),
                              label: const Text('Page Inbox'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await Get.to(() => FanPageManagePage(page: page));
                                _fetchDetails();
                              },
                              icon: const Icon(Icons.settings_outlined, size: 16),
                              label: const Text('Manage'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                          if (FeatureController.to.isFeatureEnabled('live_streaming')) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => Get.to(
                                () => GoLiveSetupPage(
                                  initialFanPageId: page.id,
                                  initialFanPageName: page.name,
                                ),
                              ),
                              icon: const Icon(Icons.videocam_rounded, size: 16),
                              label: const Text('Go Live'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Get.to(() => FanPageChatScreen(page: page)),
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (page.ctaButtonType != 'none' && page.ctaButtonType != 'message') ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _triggerCta,
                                icon: const Icon(Icons.arrow_outward, size: 16),
                                label: Text(_getCtaLabel(page.ctaButtonType)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _toggleFollow,
                              icon: Icon(_isFollowing ? Icons.check : Icons.add, size: 16),
                              label: Text(_isFollowing ? 'Following' : 'Follow'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _isFollowing ? AppColors.textSecondary : AppColors.primary,
                                side: BorderSide(color: _isFollowing ? Colors.grey.shade400 : AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Live Videos'),
                    Tab(text: 'Jobs'),
                    Tab(text: 'About'),
                    Tab(text: 'Reviews'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Posts Tab
            _posts.isEmpty
                ? const Center(child: Text('No posts yet on this page.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return PostCard(post: _posts[index]);
                    },
                  ),

            // Live Videos Tab (Active & Ended Page Broadcasts)
            ProfileLiveStreamsTab(
              fanPageId: page.id,
              fanPageName: page.name,
              isOwner: page.canManage,
            ),

            // Jobs Tab
            FanPageJobsTab(
              pageSlug: widget.slug,
              pageName: page.name,
              canManage: page.canManage,
            ),

            // About Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (page.description != null && page.description!.isNotEmpty) ...[
                  Text('About', style: AppTextStyles.h3),
                  const SizedBox(height: 6),
                  Text(page.description!, style: AppTextStyles.bodyMedium),
                  const Divider(height: 24),
                ],
                if (page.website != null) _buildInfoTile(Icons.language, 'Website', page.website!),
                if (page.email != null) _buildInfoTile(Icons.email_outlined, 'Email', page.email!),
                if (page.phone != null) _buildInfoTile(Icons.phone_outlined, 'Phone', page.phone!),
                if (page.location != null) _buildInfoTile(Icons.location_on_outlined, 'Location', page.location!),
              ],
            ),

            // Reviews Tab
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 48, color: Colors.amber),
                  const SizedBox(height: 8),
                  Text('${page.averageRating} Stars', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text('Community Recommendations', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: page.canManage
          ? FloatingActionButton.extended(
              onPressed: () {
                Get.to(() => CreatePostPage(fanPageId: page.id, fanPage: page))?.then((_) => _fetchDetails());
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Post as Page', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  String _getCtaLabel(String type) {
    switch (type) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'call':
        return 'Call Now';
      case 'website':
        return 'Website';
      case 'shop':
        return 'Shop';
      case 'email':
        return 'Email';
      case 'book_now':
        return 'Book';
      default:
        return 'Message';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
