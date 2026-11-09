import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/fan_page_chat_model.dart';
import '../../data/models/fan_page_model.dart';
import '../../data/services/fan_page_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';
import 'fan_page_chat_screen.dart';
import 'fan_pages_list_page.dart';

class FanPageInboxPage extends StatefulWidget {
  final FanPageModel page;

  const FanPageInboxPage({super.key, required this.page});

  @override
  State<FanPageInboxPage> createState() => _FanPageInboxPageState();
}

class _FanPageInboxPageState extends State<FanPageInboxPage> {
  final FanPageService _service = FanPageService();
  List<FanPageConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getPageConversations(widget.page.slug);
      if (mounted) {
        setState(() {
          _conversations = list.map((e) => FanPageConversationModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Page Inbox',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              widget.page.name,
              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mark_chat_unread_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When customers message ${widget.page.name}, conversations will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (context, i) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      final user = conv.user;
                      final hasUnread = conv.pageUnreadCount > 0;

                      return ListTile(
                        tileColor: hasUnread ? Colors.blue.withValues(alpha: 0.04) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Stack(
                          children: [
                            ClipOval(
                              child: CustomNetworkImage(
                                imageUrl: user?.avatar,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.person, size: 28, color: Colors.grey),
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                user?.name ?? 'Customer',
                                style: TextStyle(
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conv.lastMessageAt != null)
                              Text(
                                _formatTime(conv.lastMessageAt!),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.lastMessage ?? 'Attachment / New conversation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conv.pageUnreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        onTap: () async {
                          await Get.to(() => FanPageConversationChatPage(
                                page: widget.page,
                                conversation: conv,
                              ));
                          _loadConversations();
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class FanPageConversationChatPage extends StatefulWidget {
  final FanPageModel page;
  final FanPageConversationModel conversation;

  const FanPageConversationChatPage({
    super.key,
    required this.page,
    required this.conversation,
  });

  @override
  State<FanPageConversationChatPage> createState() => _FanPageConversationChatPageState();
}

class _FanPageConversationChatPageState extends State<FanPageConversationChatPage> {
  final FanPageService _service = FanPageService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<FanPageMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedMedia;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final res = await _service.getConversationMessages(widget.page.slug, widget.conversation.id);
      List? list;
      if (res['messages'] is List) {
        list = res['messages'] as List;
      } else if (res['data'] is Map && res['data']['messages'] is List) {
        list = res['data']['messages'] as List;
      } else if (res['data'] is List) {
        list = res['data'] as List;
      }
      final msgList = list ?? [];
      if (mounted) {
        setState(() {
          _messages = msgList.map((e) => FanPageMessageModel.fromJson(e)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedMedia = File(picked.path));
    }
  }

  Future<void> _sendReply() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedMedia == null) return;

    setState(() => _isSending = true);
    final media = _selectedMedia;
    _textController.clear();
    setState(() => _selectedMedia = null);

    try {
      final res = await _service.replyAsPage(
        widget.page.slug,
        widget.conversation.id,
        message: text.isNotEmpty ? text : null,
        media: media,
      );

      final msgData = res['message'] ?? res['data'];
      if ((res['success'] == true || res['status'] == true) && msgData != null && msgData is Map<String, dynamic>) {
        final newMsg = FanPageMessageModel.fromJson(msgData);
        setState(() {
          _messages.add(newMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reply. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.conversation.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black87),
        titleSpacing: 0,
        title: Row(
          children: [
            ClipOval(
              child: CustomNetworkImage(
                imageUrl: user?.avatar,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Customer',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Replying as ${widget.page.name}',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isPage = msg.isFromPage;

                      return Align(
                        alignment: isPage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isPage ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isPage ? 16 : 4),
                              bottomRight: Radius.circular(isPage ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isPage) ...[
                                Text(
                                  widget.page.name,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                                ),
                                const SizedBox(height: 2),
                              ],
                              if (msg.message != null && msg.message!.isNotEmpty)
                                Text(
                                  msg.message!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isPage ? Colors.white : Colors.black87,
                                  ),
                                ),
                              if (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CustomNetworkImage(
                                    imageUrl: msg.attachmentUrl,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_selectedMedia != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedMedia!, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 8),
                  const Text('Image attached', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _selectedMedia = null),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.photo, color: Colors.grey.shade600),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Reply as ${widget.page.name}...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send, size: 16, color: Colors.white),
                      onPressed: _isSending ? null : _sendReply,
                    ),
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

class FanPageInboxHubPage extends StatefulWidget {
  final int initialTabIndex;
  const FanPageInboxHubPage({super.key, this.initialTabIndex = 0});

  @override
  State<FanPageInboxHubPage> createState() => _FanPageInboxHubPageState();
}

class _FanPageInboxHubPageState extends State<FanPageInboxHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FanPageService _service = FanPageService();

  List<FanPageModel> _managedPages = [];
  List<FanPageConversationModel> _sentConversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadManagedPages(),
      _loadSentChats(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadManagedPages() async {
    try {
      final res = await _service.getMyPages();
      final list = res['managed'] ?? [];
      if (mounted) {
        setState(() {
          _managedPages = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSentChats() async {
    try {
      final list = await _service.getUserPageChats();
      if (mounted) {
        setState(() {
          _sentConversations = list;
        });
      }
    } catch (_) {}
  }

  int get _unreadSentCount {
    int total = 0;
    for (final c in _sentConversations) {
      total += c.userUnreadCount;
    }
    return total;
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 7) {
      return '${time.day}/${time.month}';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Page Inboxes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 18),
                  SizedBox(width: 6),
                  Text('Page Inbox'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 16),
                  const SizedBox(width: 6),
                  const Text('Sent to Pages'),
                  if (_unreadSentCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadSentCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReceivedTab(),
                _buildSentTab(),
              ],
            ),
    );
  }

  Widget _buildReceivedTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: _managedPages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mail_outline, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No Managed Pages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'You must own or manage a page to access the Page Inbox.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create a Page'),
                      onPressed: () {
                        Get.to(() => const FanPagesListPage(initialTabIndex: 1));
                      },
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _managedPages.length,
              itemBuilder: (context, index) {
                final page = _managedPages[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipOval(
                      child: CustomNetworkImage(
                        imageUrl: page.avatar,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.flag, size: 28, color: Colors.grey),
                        ),
                      ),
                    ),
                    title: Text(page.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text(page.category?.name ?? 'Fan Page', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Get.to(() => FanPageInboxPage(page: page));
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSentTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: _sentConversations.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No Sent Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Messages you send to fan pages and businesses will appear right here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.explore_outlined, size: 18),
                      label: const Text('Explore Fan Pages'),
                      onPressed: () {
                        Get.to(() => const FanPagesListPage());
                      },
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sentConversations.length,
              separatorBuilder: (context, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final conv = _sentConversations[index];
                final page = conv.page;
                final hasUnread = conv.userUnreadCount > 0;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  color: hasUnread ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Stack(
                      children: [
                        ClipOval(
                          child: CustomNetworkImage(
                            imageUrl: page?.avatar,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.flag, size: 28, color: Colors.grey),
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            page?.name ?? 'Fan Page',
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conv.lastMessageAt != null)
                          Text(
                            _formatRelativeTime(conv.lastMessageAt!),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.lastMessage ?? 'No messages yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conv.userUnreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () async {
                      if (page != null) {
                        await Get.to(() => FanPageChatScreen(page: page));
                        _loadSentChats();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
