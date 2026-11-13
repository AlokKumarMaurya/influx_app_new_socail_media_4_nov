import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/reaction_model.dart';
import '../../data/services/post_service.dart';
import '../../data/services/profile_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../pages/user/profile_page.dart';
import '../../widgets/common/professional_badge.dart';

class ReactionsPage extends StatefulWidget {
  final int postId;
  final String model; // 'post' or 'comment'
  final Map<String, int> summary;

  const ReactionsPage({
    super.key,
    required this.postId,
    required this.summary,
    this.model = 'post',
  });

  @override
  State<ReactionsPage> createState() => _ReactionsPageState();
}

class _ReactionsPageState extends State<ReactionsPage> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final ProfileService _profileService = ProfileService();
  final Set<int> _sentRequests = {};
  late TabController _tabController;
  
  final List<String> _types = ['all', 'like', 'love', 'care', 'haha', 'wow', 'sad', 'angry'];
  final Map<String, List<ReactionModel>> _reactions = {};
  final Map<String, int> _pages = {};
  final Map<String, bool> _hasMore = {};
  final Map<String, bool> _isLoading = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    for (var type in _types) {
      _reactions[type] = [];
      _pages[type] = 1;
      _hasMore[type] = true;
      _isLoading[type] = false;
    }
    _loadReactions(_types[0]);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final type = _types[_tabController.index];
        if (_reactions[type]!.isEmpty && _hasMore[type]!) {
          _loadReactions(type);
        }
      }
    });
  }

  Future<void> _loadReactions(String type) async {
    if (_isLoading[type]! || !_hasMore[type]!) return;

    setState(() {
      _isLoading[type] = true;
    });

    try {
      final result = await _postService.getReactions(
        widget.postId,
        page: _pages[type]!,
        type: type,
        model: widget.model,
      );

      setState(() {
        _reactions[type]!.addAll(result['reactions'] as List<ReactionModel>);
        _pages[type] = _pages[type]! + 1;
        _hasMore[type] = result['currentPage'] < result['lastPage'];
        _isLoading[type] = false;
      });
    } catch (e) {
      setState(() {
        _isLoading[type] = false;
      });
      Get.snackbar('error'.tr, 'failed_load_reactions'.tr);
    }
  }

  void _sendFriendRequest(int userId) async {
    try {
      await _profileService.sendFriendRequest(userId);
      setState(() {
        _sentRequests.add(userId);
      });
      Get.snackbar(
        'success'.tr,
        'friend_request_sent'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'notice'.tr,
        'could_not_send_friend_request'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('reactions'.tr, style: AppTextStyles.h3),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _types.map((type) {
            int count = type == 'all' 
                ? widget.summary.values.fold(0, (sum, val) => sum + val)
                : widget.summary[type] ?? 0;
            
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type != 'all') ...[
                    _getReactionIcon(type),
                    const SizedBox(width: 4),
                  ] else ...[
                    Text('all'.tr),
                    const SizedBox(width: 4),
                  ],
                  Text(count.toString()),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _types.map((type) {
          return _buildReactionList(type);
        }).toList(),
      ),
    );
  }

  Widget _buildReactionList(String type) {
    final list = _reactions[type]!;
    
    if (_isLoading[type]! && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_emotions_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('no_reactions_yet'.tr, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadReactions(type);
        }
        return true;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _reactions[type] = [];
            _pages[type] = 1;
            _hasMore[type] = true;
          });
          await _loadReactions(type);
        },
        child: ListView.builder(
          itemCount: list.length + (_hasMore[type]! ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == list.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final reaction = list[index];
            final isSelf = reaction.user.id == Get.find<AuthController>().user.value?.id;
            final isSent = _sentRequests.contains(reaction.user.id);

            return ListTile(
              onTap: () => Get.to(() => ProfilePage(userId: reaction.user.id)),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: reaction.user.avatar != null 
                        ? CachedNetworkImageProvider(UrlUtils.getFullUrl(reaction.user.avatar!)) 
                        : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: reaction.user.avatar == null 
                        ? const Icon(Icons.person, color: AppColors.primary) 
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: _getReactionIcon(reaction.type, size: 16),
                  ),
                ],
              ),
              title: Row(
                children: [
                  Text(reaction.user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (reaction.user.profileType != null) ProfessionalBadge(profileType: reaction.user.profileType, size: 12),
                ],
              ),
              subtitle: Text(reaction.createdAt),
              trailing: isSelf
                  ? null
                  : ElevatedButton(
                      onPressed: isSent ? null : () => _sendFriendRequest(reaction.user.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSent ? Colors.grey.shade200 : AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: isSent ? Colors.grey.shade600 : AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(isSent ? 'requested'.tr : 'add_friend'.tr),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _getReactionIcon(String type, {double size = 20}) {
    // Fallback to emoji if assets not found, or use a helper that returns the right widget
    switch (type) {
      case 'like': return Text('👍', style: TextStyle(fontSize: size));
      case 'love': return Text('❤️', style: TextStyle(fontSize: size));
      case 'care': return Text('🥰', style: TextStyle(fontSize: size));
      case 'haha': return Text('😆', style: TextStyle(fontSize: size));
      case 'wow': return Text('😮', style: TextStyle(fontSize: size));
      case 'sad': return Text('😢', style: TextStyle(fontSize: size));
      case 'angry': return Text('😡', style: TextStyle(fontSize: size));
      default: return Text('👍', style: TextStyle(fontSize: size));
    }
  }
}
