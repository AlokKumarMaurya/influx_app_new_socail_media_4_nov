import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/feed_controller.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/story_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/chat/conversation_tile.dart';
import '../../widgets/common/custom_avatar.dart';
import '../story/story_view_page.dart';
import 'call_logs_page.dart';
import 'chat_page.dart';
import 'create_room_sheet.dart';
import 'message_requests_page.dart';
import '../user/settings/message_settings_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final ChatController _chatController = Get.put(ChatController());
  late final FeedController _feedController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    try {
      _feedController = Get.find<FeedController>();
    } catch (_) {
      _feedController = Get.put(FeedController());
    }
    _chatController.loadConversations();
    _chatController.startListPolling();
  }

  @override
  void dispose() {
    _chatController.stopListPolling();
    _searchController.dispose();
    super.dispose();
  }

  void _openConversation(ConversationModel conv) {
    _chatController.stopListPolling();
    Get.to(() => ChatPage(
          conversationId: conv.id,
          user: conv.user,
          conversation: conv,
        ))?.then((_) {
      _chatController.leaveConversation();
      _chatController.loadConversations(showLoading: false);
      _chatController.startListPolling();
    });
  }

  void _openRoom(ConversationModel conv) {
    _chatController.stopListPolling();
    Get.to(() => ChatPage(
          conversationId: conv.id,
          user: conv.user,
          conversation: conv,
        ))?.then((_) {
      _chatController.leaveConversation();
      _chatController.loadConversations(showLoading: false);
      _chatController.startListPolling();
    });
  }

  void _showCreateMenu() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('new_message'.tr),
                onTap: () {
                  Get.back();
                  _showNewChatSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add_outlined),
                title: Text('new_group'.tr),
                onTap: () async {
                  Get.back();
                  final room = await Get.bottomSheet<Map<String, dynamic>>(
                    CreateRoomSheet(type: 'group', chatController: _chatController),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                  if (room != null) {
                    Get.snackbar('success'.tr, 'group_created'.tr);
                    _openRoom(conversationFromRoom(room));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: Text('new_channel'.tr),
                onTap: () async {
                  Get.back();
                  final room = await Get.bottomSheet<Map<String, dynamic>>(
                    CreateRoomSheet(type: 'channel', chatController: _chatController),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                  if (room != null) {
                    Get.snackbar('success'.tr, 'channel_created'.tr);
                    _openRoom(conversationFromRoom(room));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.travel_explore_outlined),
                title: Text('public_channels'.tr),
                onTap: () async {
                  Get.back();
                  final room = await Get.bottomSheet<Map<String, dynamic>>(
                    const PublicChannelsSheet(),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                  if (room != null) _openRoom(conversationFromRoom(room));
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _showNewChatSheet() {
    _chatController.searchUsers('');
    Get.bottomSheet(
      _NewChatSheet(
        chatController: _chatController,
        onUserSelected: (userId, user) async {
          Get.back();
          final result = await _chatController.startConversationWith(userId);
          if (result != null) {
            final chatUser = ChatUser.fromJson(result['user']);
            _chatController.stopListPolling();
            Get.to(
              () => ChatPage(
                conversationId: result['conversation_id'],
                user: chatUser,
              ),
            )?.then((_) {
              _chatController.leaveConversation();
              _chatController.loadConversations(showLoading: false);
              _chatController.startListPolling();
            });
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
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
          scrolledUnderElevation: 0,
          title: _showSearch
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(fontSize: 16, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'search_chats_hint'.tr,
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : Text('chats'.tr, style: AppTextStyles.h2),
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.textMain,
              size: 24,
            ),
            onPressed: () => Get.back(),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'all'.tr),
              Tab(text: 'online'.tr),
              Tab(text: 'calls'.tr),
              Tab(text: 'stories'.tr),
            ],
          ),
          actions: [
            IconButton(
              icon: HugeIcon(
                icon: _showSearch
                    ? HugeIcons.strokeRoundedCancel01
                    : HugeIcons.strokeRoundedSearch01,
                color: AppColors.textMain,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit02,
                color: AppColors.textMain,
                size: 22,
              ),
              onPressed: _showCreateMenu,
            ),
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings02,
                color: AppColors.textMain,
                size: 22,
              ),
              onPressed: () => Get.to(() => const MessageSettingsPage()),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            _buildConversationsList(false), // All
            _buildConversationsList(true), // Online
            const CallLogsPage(showAppBar: false), // Calls
            _buildStoriesTab(), // Stories
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsBanner() {
    return Obx(() {
      final count = _chatController.requestsCount.value;
      if (count <= 0) return const SizedBox.shrink();
      return InkWell(
        onTap: () {
          _chatController.stopListPolling();
          Get.to(() => const MessageRequestsPage())?.then((_) {
            _chatController.loadConversations(showLoading: false);
            _chatController.startListPolling();
          });
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedMail01,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'message_requests'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'you_have_message_requests'.trParams({'count': count.toString()}),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildConversationsList(bool onlyOnline) {
    return Obx(() {
      if (_chatController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final showRequestsBanner = !onlyOnline && _chatController.requestsCount.value > 0;

      var list = onlyOnline
          ? _chatController.onlineConversations
          : _chatController.conversations;

      if (_searchQuery.isNotEmpty) {
        list = list
            .where(
              (c) => c.user.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();
      }

      if (list.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => _chatController.loadConversations(),
          child: ListView(
            children: [
              if (showRequestsBanner) _buildRequestsBanner(),
              _buildEmptyState(
                title: onlyOnline ? 'no_friends_online'.tr : 'no_messages'.tr,
                subtitle: onlyOnline
                    ? 'check_back_later_or_invite'.tr
                    : 'start_conversation_with_friend'.tr,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _chatController.loadConversations(),
        child: ListView.builder(
          itemCount: list.length + (showRequestsBanner ? 1 : 0),
          itemBuilder: (context, index) {
            if (showRequestsBanner && index == 0) {
              return _buildRequestsBanner();
            }
            final conv = list[showRequestsBanner ? index - 1 : index];
            return ConversationTile(
              conversation: conv,
              isActive: false,
              onTap: () => _openConversation(conv),
            );
          },
        ),
      );
    });
  }

  Widget _buildStoriesTab() {
    return Obx(() {
      final storiesList = _feedController.stories;

      if (storiesList.isEmpty) {
        return _buildEmptyState(
          title: 'no_stories'.tr,
          subtitle: 'share_story_with_friends_desc'.tr,
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: storiesList.length,
        itemBuilder: (context, index) {
          final group = storiesList[index];
          return _StoryCard(group: group, allGroups: storiesList);
        },
      );
    });
  }

  Widget _buildEmptyState({
    String title = 'Your Messages',
    String subtitle = 'Send private messages to a friend.',
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.message_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _showNewChatSheet,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'send_message'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// New Chat Bottom Sheet
// ═══════════════════════════════════════════════

class _NewChatSheet extends StatefulWidget {
  final ChatController chatController;
  final Function(int userId, Map<String, dynamic> user) onUserSelected;

  const _NewChatSheet({
    required this.chatController,
    required this.onUserSelected,
  });

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.chatController.searchUsers('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('new_message'.tr, style: AppTextStyles.h3),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'search_friends'.tr,
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (val) {
                widget.chatController.searchUsers(val);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Results
          Expanded(
            child: Obx(() {
              final results = widget.chatController.searchResults;

              if (results.isEmpty) {
                return Center(
                  child: Text(
                    'type_to_search_friends'.tr,
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }

              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final user = results[index];
                  return ListTile(
                    leading: CustomAvatar(
                      avatarUrl: user['avatar'],
                      name: user['name'],
                      radius: 22,
                      isOnline:
                          user['is_online'] == true || user['is_online'] == 1,
                    ),
                    title: Text(
                      user['name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textMain,
                      ),
                    ),
                    subtitle: user['username'] != null
                        ? Text(
                            '@${user['username']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    onTap: () => widget.onUserSelected(user['id'], user),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final StoryGroup group;
  final List<StoryGroup> allGroups;

  const _StoryCard({required this.group, required this.allGroups});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => StoryViewPage(
          groups: allGroups,
          initialGroupIndex: allGroups.indexOf(group),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(group.stories.first.mediaUrl ?? ''),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dark gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // User info
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CustomAvatar(
                      avatarUrl: group.user.avatar,
                      name: group.user.name,
                      radius: 18,
                      isOnline: false,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
