import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/chat_controller.dart';
import '../../data/models/conversation_model.dart';
import '../../data/services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/chat/conversation_tile.dart';
import 'chat_page.dart';

class MessageRequestsPage extends StatefulWidget {
  const MessageRequestsPage({super.key});

  @override
  State<MessageRequestsPage> createState() => _MessageRequestsPageState();
}

class _MessageRequestsPageState extends State<MessageRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _service = ChatService();
  final ChatController _chatController = Get.find<ChatController>();

  bool _loadingRequests = true;
  bool _loadingSpam = true;

  final List<ConversationModel> _requests = [];
  final List<ConversationModel> _spam = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
    _loadSpam();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final res = await _service.getConversations(page: 1, box: 'requests');
      final items = res['items'] as List<ConversationModel>;
      setState(() {
        _requests.clear();
        _requests.addAll(items);
      });
      final counts = res['counts'] as Map<String, dynamic>?;
      if (counts != null && counts['requests'] != null) {
        _chatController.requestsCount.value =
            int.tryParse(counts['requests'].toString()) ?? items.length;
      } else {
        _chatController.requestsCount.value = items.length;
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
    } finally {
      setState(() => _loadingRequests = false);
    }
  }

  Future<void> _loadSpam() async {
    setState(() => _loadingSpam = true);
    try {
      final res = await _service.getConversations(page: 1, box: 'spam');
      final items = res['items'] as List<ConversationModel>;
      setState(() {
        _spam.clear();
        _spam.addAll(items);
      });
      final counts = res['counts'] as Map<String, dynamic>?;
      if (counts != null && counts['spam'] != null) {
        _chatController.spamCount.value =
            int.tryParse(counts['spam'].toString()) ?? items.length;
      } else {
        _chatController.spamCount.value = items.length;
      }
    } catch (e) {
      debugPrint('Error loading spam: $e');
    } finally {
      setState(() => _loadingSpam = false);
    }
  }

  void _openConversation(ConversationModel conv) {
    Get.to(() => ChatPage(
          conversationId: conv.id,
          user: conv.user,
          conversation: conv,
        ))?.then((_) {
      _loadRequests();
      _loadSpam();
      _chatController.loadConversations(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'message_requests'.tr,
          style: AppTextStyles.h2,
        ),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textMain,
            size: 24,
          ),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'requests'.tr),
            Tab(text: 'spam'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(
            loading: _loadingRequests,
            items: _requests,
            emptyTitle: 'no_message_requests'.tr,
            emptySubtitle: 'message_requests_empty_desc'.tr,
            onRefresh: _loadRequests,
          ),
          _buildList(
            loading: _loadingSpam,
            items: _spam,
            emptyTitle: 'no_spam_messages'.tr,
            emptySubtitle: 'spam_messages_empty_desc'.tr,
            onRefresh: _loadSpam,
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required bool loading,
    required List<ConversationModel> items,
    required String emptyTitle,
    required String emptySubtitle,
    required Future<void> Function() onRefresh,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMail01,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        emptySubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, index) => Divider(
          height: 1,
          indent: 72,
          color: AppColors.textSecondary.withValues(alpha: 0.08),
        ),
        itemBuilder: (context, index) {
          final conv = items[index];
          return ConversationTile(
            conversation: conv,
            isActive: false,
            onTap: () => _openConversation(conv),
          );
        },
      ),
    );
  }
}
