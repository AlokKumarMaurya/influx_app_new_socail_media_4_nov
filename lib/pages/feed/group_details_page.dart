import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../utils/string_utils.dart';
import '../../controllers/group_details_controller.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/professional_badge.dart';
import '../../data/models/group_model.dart';
import '../../controllers/auth_controller.dart';
import 'create_post_page.dart';

class GroupDetailsPage extends StatefulWidget {
  final int groupId;
  const GroupDetailsPage({super.key, required this.groupId});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  late GroupDetailsController controller;
  late AuthController authController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      GroupDetailsController(groupId: widget.groupId),
      tag: 'group_${widget.groupId}',
    );
    authController = Get.find<AuthController>();

    controller.refreshAll();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // We can't easily check current tab index here without a controller reference,
    // so we'll use DefaultTabController.of(context) inside a builder if needed,
    // or just rely on the fact that pagination only triggers if scrolling at bottom.
    // For safety, we only load posts if we are likely on the first tab.
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      controller.loadPosts();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAdmin = controller.isAdmin.value;
      final tabCount = isAdmin ? 4 : 3;

      return DefaultTabController(
        key: ValueKey('group_${widget.groupId}_tabs_$tabCount'),
        length: tabCount,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: _TabListener(
            controller: controller,
            child: RefreshIndicator(
              onRefresh: () => controller.refreshAll(),
              child: _buildBody(),
            ),
          ),
          floatingActionButton: controller.canPost.value
              ? FloatingActionButton(
                  onPressed: () =>
                      Get.to(() => CreatePostPage(groupId: widget.groupId)),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.edit, color: Colors.white),
                )
              : null,
        ),
      );
    });
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final group = controller.group.value;
    if (group == null) {
      return Center(child: Text('group_not_found'.tr));
    }

    return NestedScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildHeaderSection(context, group),
          const SliverToBoxAdapter(child: Divider(height: 1, thickness: 1)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'posts'.tr),
                  Tab(text: 'members'.tr),
                  Tab(text: 'media'.tr),
                  if (controller.isAdmin.value) Tab(text: 'settings'.tr),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        children: [
          _buildPostsTab(),
          _buildMembersTab(),
          _buildMediaTab(),
          if (controller.isAdmin.value) _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, GroupModel group) {
    final coverUrl = group.coverPhoto;
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover Photo
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
                  child: (coverUrl != null && coverUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.white54,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.group,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),
                ),
                // Overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 160,
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
                if (controller.isAdmin.value)
                  Positioned(
                    right: 16,
                    bottom: 50,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => controller.pickAndUploadMedia('cover'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                // Back Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // Avatar
                Positioned(
                  bottom: 0,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        CustomAvatar(avatarUrl: group.avatar, radius: 40),
                        if (controller.isAdmin.value)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => controller.pickAndUploadMedia('avatar'),
                              child: Container(
                                padding: const EdgeInsets.all(6),
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
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (group.privacy == 'private') ...[
                                Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '${controller.memberCount.value} ${'members'.tr} • ${(group.privacy == 'private' ? 'private'.tr : 'public'.tr)} ${'group'.tr}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (_shouldShowInvite(group)) ...[
                          _buildInviteButton(),
                          const SizedBox(width: 8),
                        ],
                        _buildHeaderAction(group),
                      ],
                    ),
                  ],
                ),
                if (group.description != null &&
                    group.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    group.description ?? '',
                    style: TextStyle(fontSize: 14, color: AppColors.textMain),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(GroupModel group) {
    return Obx(() {
      final status = controller.membershipStatus.value;
      if (status == 'member') {
        return OutlinedButton(
          onPressed: () => controller.toggleJoin(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 32),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text('leave'.tr, style: const TextStyle(fontSize: 12)),
        );
      } else if (status == 'pending') {
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text('requested'.tr, style: const TextStyle(fontSize: 12)),
        );
      } else {
        return ElevatedButton(
          onPressed: () => controller.toggleJoin(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text('join'.tr, style: const TextStyle(fontSize: 12)),
        );
      }
    });
  }

  bool _shouldShowInvite(GroupModel group) {
    if (group.privacy == 'public') return true;
    return controller.isAdmin.value;
  }

  Widget _buildInviteButton() {
    return ElevatedButton.icon(
      onPressed: () => _showInviteModal(),
      icon: const Icon(Icons.add, size: 16),
      label: Text('invite'.tr, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        foregroundColor: AppColors.primary,
        elevation: 0,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showInviteModal() {
    controller.searchInviteableFriends('');
    Get.bottomSheet(
      Obx(() {
        AppColors.isDark; // Reactivity trigger
        return Container(
          height: Get.height * 0.7,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'invite_friends'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => controller.searchInviteableFriends(v),
                  style: TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'search_friends'.tr,
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: () {
                  if (controller.isLoadingInviteable.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.inviteableFriends.isEmpty) {
                    return Center(
                      child: Text(
                        'no_friends_to_invite'.tr,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.inviteableFriends.length,
                    itemBuilder: (context, index) {
                      final friend = controller.inviteableFriends[index];
                      return ListTile(
                        leading: CustomAvatar(
                          avatarUrl: friend['avatar']?.toString(),
                          radius: 20,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                friend['name']?.toString() ?? 'User',
                                style: TextStyle(color: AppColors.textMain),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (friend['profile_type'] != null && friend['profile_type'] != 'user') ...[
                              const SizedBox(width: 4),
                              ProfessionalBadge(profileType: friend['profile_type'], size: 14),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => controller.inviteUser(friend['id']),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(60, 32),
                            elevation: 0,
                            backgroundColor: AppColors.primary,
                          ),
                          child: Text(
                            'invite'.tr,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      );
                    },
                  );
                }(),
              ),
            ],
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  Widget _buildPostsTab() {
    return Obx(() {
      if (controller.posts.isEmpty && !controller.isLoadingPosts.value) {
        return Center(child: Text('no_posts_yet'.tr));
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount:
            controller.posts.length + (controller.isLoadingPosts.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return PostCard(post: controller.posts[index]);
        },
      );
    });
  }

  Widget _buildMembersTab() {
    return Obx(() {
      if (controller.isLoadingMembers.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.members.isEmpty) {
        return Center(child: Text('no_members_found'.tr));
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.members.length,
        itemBuilder: (context, index) {
          final member = controller.members[index];
          final user = member['user'];
          if (user == null) return const SizedBox.shrink();
          return ListTile(
            leading: CustomAvatar(
              avatarUrl: user['avatar']?.toString(),
              radius: 20,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    user['name']?.toString() ?? 'User',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user['profile_type'] != null && user['profile_type'] != 'user') ...[
                  const SizedBox(width: 4),
                  ProfessionalBadge(profileType: user['profile_type'], size: 14),
                ],
              ],
            ),
            subtitle: Text(
              member['role']?.toString().capitalizeFirst ?? 'Member',
            ),
            trailing:
                controller.isAdmin.value &&
                    user['id'] != authController.user.value?.id
                ? IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showMemberOptions(member),
                  )
                : null,
          );
        },
      );
    });
  }

  Widget _buildMediaTab() {
    return Obx(() {
      if (controller.isLoadingMedia.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.media.isEmpty) {
        return Center(child: Text('no_media_found'.tr));
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: controller.media.length,
        itemBuilder: (context, index) {
          final item = controller.media[index];
          return GestureDetector(
            onTap: () => Get.to(() => MediaPreviewPage(item: item)),
            child: CachedNetworkImage(
              imageUrl: item['file_path'] ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[100]),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.grey[200]),
            ),
          );
        },
      );
    });
  }

  Widget _buildSettingsTab() {
    final group = controller.group.value;
    if (group == null) return const SizedBox.shrink();

    final nameCtrl = TextEditingController(text: group.name);
    final descCtrl = TextEditingController(text: group.description ?? '');
    final privacy = group.privacy.obs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('name'.tr),
          TextField(
            controller: nameCtrl,
            decoration: _inputDecoration('enter_group_name'.tr),
          ),
          const SizedBox(height: 20),
          _buildLabel('description'.tr),
          TextField(
            controller: descCtrl,
            maxLines: 4,
            decoration: _inputDecoration('enter_description'.tr),
          ),
          const SizedBox(height: 20),
          _buildLabel('privacy'.tr),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: privacy.value,
                  isExpanded: true,
                  dropdownColor: AppColors.cardBg,
                  style: TextStyle(color: AppColors.textMain),
                  items: [
                    DropdownMenuItem(value: 'public', child: Text('public'.tr)),
                    DropdownMenuItem(value: 'private', child: Text('private'.tr)),
                  ],
                  onChanged: (v) => privacy.value = v!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => controller.updateGroup(
                name: nameCtrl.text,
                description: descCtrl.text,
                privacy: privacy.value,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'save_changes'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (authController.user.value?.id == group.creatorId) ...[
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'danger_zone'.tr,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDeleteDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('delete_group'.tr),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('delete_group'.tr),
        content: Text(
          'delete_group_confirm'.tr,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => controller.deleteGroup(),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    // Member options implementation
  }
}

class MediaPreviewPage extends StatelessWidget {
  final Map<String, dynamic> item;
  const MediaPreviewPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: CachedNetworkImage(
          imageUrl: item['file_path'] ?? '',
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, color: Colors.white54, size: 48),
        ),
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
    return Container(color: AppColors.background, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return true;
  }
}

class _TabListener extends StatefulWidget {
  final Widget child;
  final GroupDetailsController controller;

  const _TabListener({required this.child, required this.controller});

  @override
  State<_TabListener> createState() => _TabListenerState();
}

class _TabListenerState extends State<_TabListener> {
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (newController != _tabController) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = newController;
      _tabController?.addListener(_onTabChanged);
    }
  }

  @override
  void didUpdateWidget(_TabListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    // In case the widget is updated and we need to ensure listeners are still attached
    final currentController = DefaultTabController.of(context);
    if (currentController != _tabController) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = currentController;
      _tabController?.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      final index = _tabController!.index;
      if (index == 1) widget.controller.loadMembers();
      if (index == 2) widget.controller.loadMedia();
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
