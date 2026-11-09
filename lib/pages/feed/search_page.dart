import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/feed_controller.dart';
import '../../data/models/user_model.dart';
import '../../data/models/post_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_avatar.dart';
import '../../widgets/common/professional_badge.dart';
import '../../widgets/feed/post_card.dart';
import '../user/profile_page.dart';
import 'group_details_page.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FeedController controller = Get.find<FeedController>();
  late TabController _tabController;
  final RxString _searchQuery = ''.obs;
  final RxBool _isDetailedSearchDone = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchQuery.value = widget.initialQuery!;
      _isDetailedSearchDone.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.performGlobalSearch(widget.initialQuery!);
        if (widget.initialQuery!.startsWith('#')) {
          _tabController.animateTo(3); // Direct to Posts tab
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Quick user search as you type
  void _onChanged(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      controller.globalSearchResults['people'] = [];
      controller.globalSearchResults.refresh();
      _isDetailedSearchDone.value = false;
      return;
    }
    
    // Perform rapid user search for "AJAX" style results
    controller.searchUsers(query).then((users) {
      if (_searchQuery.value == query && !_isDetailedSearchDone.value) {
        controller.globalSearchResults['people'] = users;
        controller.globalSearchResults.refresh();
      }
    });
  }

  // Explicit global search (on button click or enter)
  void _onDetailedSearch(String query) {
    if (query.isEmpty) return;
    _searchQuery.value = query;
    _isDetailedSearchDone.value = true;
    controller.performGlobalSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBg,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textMain),
            onPressed: () => Get.back(),
          ),
          title: Container(
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onChanged,
              onSubmitted: _onDetailedSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'search_people_groups_posts'.tr,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
                  onPressed: () => _onDetailedSearch(_searchController.text),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: AppColors.textMain),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'all'.tr),
              Tab(text: 'people'.tr),
              Tab(text: 'groups'.tr),
              Tab(text: 'posts'.tr),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isSearchingGlobal.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.globalSearchResults.isEmpty || _searchQuery.value.isEmpty) {
            return _buildInitialState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllResults(),
              _buildPeopleResults(),
              _buildGroupsResults(),
              _buildPostsResults(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'search_people_groups_or_posts'.tr
                : 'no_results_found'.tr,
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildAllResults() {
    final List<UserModel> people = List<UserModel>.from(controller.globalSearchResults['people'] ?? []);
    final List<dynamic> groups = controller.globalSearchResults['groups'] ?? [];
    final List<PostModel> posts = List<PostModel>.from(controller.globalSearchResults['posts'] ?? []);

    if (people.isEmpty && groups.isEmpty && posts.isEmpty) {
      return _buildInitialState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (people.isNotEmpty) ...[
          _buildSectionHeader('people'.tr, () => _tabController.animateTo(1)),
          ...people.take(3).map((u) => _buildUserTile(u)),
          const SizedBox(height: 16),
        ],
        if (groups.isNotEmpty) ...[
          _buildSectionHeader('groups'.tr, () => _tabController.animateTo(2)),
          ...groups.take(3).map((g) => _buildGroupTile(g)),
          const SizedBox(height: 16),
        ],
        if (posts.isNotEmpty) ...[
          _buildSectionHeader('posts'.tr, () => _tabController.animateTo(3)),
          ...posts.take(3).map((p) => PostCard(post: p)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h3),
          TextButton(
            onPressed: onSeeAll,
            child: Text('see_all'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleResults() {
    final List<UserModel> people = List<UserModel>.from(controller.globalSearchResults['people'] ?? []);
    if (people.isEmpty) return _buildInitialState();

    return ListView.builder(
      itemCount: people.length,
      itemBuilder: (context, index) => _buildUserTile(people[index]),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      onTap: () => Get.to(() => ProfilePage(userId: user.id)),
      leading: CustomAvatar(avatarUrl: user.avatar, radius: 24),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.name,
              style: AppTextStyles.h4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (user.profileType != null && user.profileType != 'user') ...[
            const SizedBox(width: 4),
            ProfessionalBadge(profileType: user.profileType, size: 14),
          ],
        ],
      ),
      subtitle: user.username != null ? Text('@${user.username}') : null,
      trailing: OutlinedButton(
        onPressed: () => Get.to(() => ProfilePage(userId: user.id)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text('view'.tr),
      ),
    );
  }

  Widget _buildGroupsResults() {
    final List<dynamic> groups = controller.globalSearchResults['groups'] ?? [];
    if (groups.isEmpty) return _buildInitialState();

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) => _buildGroupTile(groups[index]),
    );
  }

  Widget _buildGroupTile(dynamic group) {
    return ListTile(
      onTap: () => Get.to(() => GroupDetailsPage(groupId: group['id'])),
      leading: CustomAvatar(avatarUrl: group['avatar'], radius: 24),
      title: Text(group['name'], style: AppTextStyles.h4),
      subtitle: Text('${group['member_count']} ${'members'.tr} • ${(group['privacy'] == 'private' ? 'private'.tr : 'public'.tr)}'),
      trailing: ElevatedButton(
        onPressed: () => Get.to(() => GroupDetailsPage(groupId: group['id'])),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text('view'.tr),
      ),
    );
  }

  Widget _buildPostsResults() {
    final List<PostModel> posts = List<PostModel>.from(controller.globalSearchResults['posts'] ?? []);
    if (posts.isEmpty) return _buildInitialState();

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(post: posts[index]),
    );
  }
}
