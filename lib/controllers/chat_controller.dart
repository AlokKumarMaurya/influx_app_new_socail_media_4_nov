import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import '../data/models/conversation_model.dart';
import '../data/models/chat_message_model.dart';
import '../data/services/chat_service.dart';
import '../utils/app_theme.dart';
import '../pages/chat/chat_page.dart';

class ChatController extends GetxController {
  final ChatService _service = ChatService();

  // ─── Observable State ───
  var conversations = <ConversationModel>[].obs;
  var messages = <ChatMessageModel>[].obs;
  var isLoading = false.obs;
  var isMessagesLoading = false.obs;
  var isMoreLoading = false.obs;
  var isSending = false.obs;
  var searchResults = <Map<String, dynamic>>[].obs;
  var unreadCount = 0.obs;
  var requestsCount = 0.obs;
  var spamCount = 0.obs;
  var currentBox = 'inbox'.obs;

  // ─── Computed State ───
  List<ConversationModel> get onlineConversations =>
      conversations.where((c) => c.user.isOnline).toList();

  // ─── Active conversation ───
  int? activeConversationId;
  String activeChatKind = 'direct';
  bool activeCanPost = true;
  String? activeRoomType;
  String? activeMyRole;
  String? activeRoomDescription;
  ChatUser? activeUser;
  int lastMessageId = 0;
  String? _pollSince;
  var otherUserTyping = false.obs;
  final replyTo = Rxn<ChatMessageModel>();
  bool viewOnceNext = false;

  // ─── Block Status ───
  bool isBlockedByMe(int conversationId) {
    final conv = conversations.firstWhereOrNull((c) => c.id == conversationId);
    if (conv == null) return false;
    return conv.settings['blocked_by_$currentUserId'] == true;
  }

  bool isBlockedByOther(int conversationId, int otherUserId) {
    final conv = conversations.firstWhereOrNull((c) => c.id == conversationId);
    if (conv == null) return false;
    return conv.settings['blocked_by_$otherUserId'] == true;
  }

  // ─── Pagination ───
  String? _nextConversationsUrl;
  String? _nextMessagesUrl;
  bool canLoadMoreConversations = true;
  int _conversationsPage = 1;

  // ─── Polling timers ───
  Timer? _messagePollingTimer;
  Timer? _listPollingTimer;

  // ─── Scroll controller for messages ───
  final ScrollController messagesScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    loadConversations();
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    stopAllPolling();
    messagesScrollController.dispose();
    super.onClose();
  }

  // ═══════════════════════════════════════════════
  // Conversation List
  // ═══════════════════════════════════════════════

  Future<void> loadConversations({
    String box = 'inbox',
    bool showLoading = true,
  }) async {
    if (showLoading) isLoading.value = true;
    currentBox.value = box;
    _conversationsPage = 1;
    canLoadMoreConversations = true;

    try {
      final result = await _service.getConversations(page: 1, box: box);
      conversations.assignAll(result['items'] as List<ConversationModel>);
      _nextConversationsUrl = result['nextPageUrl'];
      canLoadMoreConversations = _nextConversationsUrl != null;

      final counts = result['counts'] as Map<String, dynamic>?;
      if (counts != null) {
        requestsCount.value = counts['requests'] is int
            ? counts['requests']
            : int.tryParse(counts['requests'].toString()) ?? 0;
        spamCount.value = counts['spam'] is int
            ? counts['spam']
            : int.tryParse(counts['spam'].toString()) ?? 0;
      }

      // Also fetch unread count
      await _fetchUnreadCount();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreConversations() async {
    if (isMoreLoading.value || !canLoadMoreConversations) return;
    isMoreLoading.value = true;
    _conversationsPage++;

    try {
      final result = await _service.getConversations(
        page: _conversationsPage,
        box: currentBox.value,
      );
      conversations.addAll(result['items'] as List<ConversationModel>);
      _nextConversationsUrl = result['nextPageUrl'];
      canLoadMoreConversations = _nextConversationsUrl != null;
    } catch (e) {
      _conversationsPage--;
      debugPrint('Error loading more conversations: $e');
    } finally {
      isMoreLoading.value = false;
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      unreadCount.value = await _service.getUnreadCount();
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // Open / Leave Conversation
  // ═══════════════════════════════════════════════

  Future<void> openConversation(
    int conversationId,
    ChatUser user, {
    ConversationModel? conversation,
  }) async {
    // Stop any existing polling
    stopMessagePolling();

    activeConversationId = conversationId;
    activeChatKind = conversation?.isRoom == true ? 'room' : 'direct';
    activeCanPost = conversation?.canPost ?? true;
    activeRoomType = conversation?.roomType;
    activeMyRole = conversation?.myRole;
    activeRoomDescription = conversation?.roomTitle;
    activeUser = user;
    lastMessageId = 0;
    messages.clear();
    _nextMessagesUrl = null;

    isMessagesLoading.value = true;

    try {
      final result = activeChatKind == 'room'
          ? await _service.getRoomMessages(conversationId)
          : await _service.getMessages(conversationId);
      final items = result['items'] as List<ChatMessageModel>;
      _nextMessagesUrl = result['nextPageUrl'];

      if (activeChatKind == 'room' && result['room'] is Map) {
        final room = result['room'] as Map<String, dynamic>;
        activeCanPost = room['can_post'] != false;
        activeRoomType = room['type']?.toString();
        activeMyRole = room['my_role']?.toString();
        activeRoomDescription = room['description']?.toString();
      }

      // Messages come newest-first from API — reverse for display
      messages.assignAll(items.reversed.toList());

      if (items.isNotEmpty) {
        // lastMessageId = max id from all messages
        lastMessageId = items
            .where((m) => m.id is int)
            .fold<int>(0, (max, m) => m.id > max ? m.id : max);
      }

      if (activeChatKind != 'room') {
        // Mark as read
        await _service.markRead(conversationId);
        _updateConversationUnread(conversationId, 0);
      }

      // Scroll to bottom after build
      _scrollToBottom();

      // Start message polling (3-5 seconds)
      startMessagePolling();
    } catch (e) {
      debugPrint('Error opening conversation: $e');
    } finally {
      isMessagesLoading.value = false;
    }
  }

  void leaveConversation() {
    stopMessagePolling();
    activeConversationId = null;
    activeUser = null;
    lastMessageId = 0;
    messages.clear();
  }

  // ═══════════════════════════════════════════════
  // Messages — Load More (scroll up)
  // ═══════════════════════════════════════════════

  Future<void> loadMoreMessages() async {
    if (isMoreLoading.value ||
        _nextMessagesUrl == null ||
        activeConversationId == null)
      return;
    isMoreLoading.value = true;

    try {
      // Parse page from nextMessagesUrl
      final uri = Uri.parse(_nextMessagesUrl!);
      final page = int.tryParse(uri.queryParameters['page'] ?? '2') ?? 2;

      final result = activeChatKind == 'room'
          ? await _service.getRoomMessages(activeConversationId!, page: page)
          : await _service.getMessages(
              activeConversationId!,
              page: page,
            );
      final items = result['items'] as List<ChatMessageModel>;
      _nextMessagesUrl = result['nextPageUrl'];

      if (items.isNotEmpty) {
        // Prepend older messages (they come newest-first, reverse them)
        messages.insertAll(0, items.reversed.toList());
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      isMoreLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════
  // Search Messages in Conversation
  // ═══════════════════════════════════════════════

  Future<void> searchMessages(String query) async {
    if (activeConversationId == null) return;
    isMessagesLoading.value = true;

    try {
      final result = activeChatKind == 'room'
          ? await _service.getRoomMessages(activeConversationId!, query: query)
          : await _service.getMessages(
              activeConversationId!,
              query: query,
            );
      final items = result['items'] as List<ChatMessageModel>;
      messages.assignAll(items.reversed.toList());
    } catch (e) {
      debugPrint('Error searching messages: $e');
    } finally {
      isMessagesLoading.value = false;
    }
  }

  // ═══════════════════════════════════════════════
  // Send Message
  // ═══════════════════════════════════════════════

  Future<void> sendMessage({
    String? body,
    File? attachment,
    bool viewOnce = false,
    bool isVoiceNote = false,
    int? voiceDuration,
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) async {
    final hasLocation = latitude != null && longitude != null;
    if ((body == null || body.trim().isEmpty) &&
        attachment == null &&
        !hasLocation)
      return;
    if (activeConversationId == null && activeUser == null) return;
    if (activeChatKind == 'room' && !activeCanPost) return;

    isSending.value = true;

    // Create optimistic message
    final userId = currentUserId;
    String? attachmentPreview;
    String? attachType;
    if (attachment != null) {
      if (attachment.lengthSync() > 25 * 1024 * 1024) {
        Get.snackbar(
          'File Too Large',
          'Selected file exceeds the 25MB size limit.',
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
        isSending.value = false;
        return;
      }
      final isImage = _isImageFile(attachment);
      final isVideo = _isVideoFile(attachment);
      attachmentPreview = (isImage || isVideo) ? attachment.path : null;
      attachType = isVoiceNote
          ? 'voice'
          : (isImage ? 'image' : (isVideo ? 'video' : 'file'));
    } else if (hasLocation) {
      attachType = 'location';
    }

    final optimistic = ChatMessageModel.optimistic(
      body: body?.trim(),
      senderId: userId,
      attachmentPreview: attachmentPreview,
      attachmentType: attachType,
    );

    messages.add(optimistic);
    _scrollToBottom();

    try {
      final replyId = replyTo.value?.id is int
          ? replyTo.value!.id as int
          : null;
      final result = activeChatKind == 'room'
          ? await _service.sendRoomMessage(
              roomId: activeConversationId!,
              body: body?.trim(),
              attachment: attachment,
              replyToMessageId: replyId,
              viewOnce: viewOnce,
              isVoiceNote: isVoiceNote,
              voiceDuration: voiceDuration,
              latitude: latitude,
              longitude: longitude,
              locationLabel: locationLabel,
            )
          : await _service.sendMessage(
              conversationId: activeConversationId,
              userId: activeUser?.id,
              body: body?.trim(),
              attachment: attachment,
              replyToMessageId: replyId,
              viewOnce: viewOnce,
              isVoiceNote: isVoiceNote,
              voiceDuration: voiceDuration,
              latitude: latitude,
              longitude: longitude,
              locationLabel: locationLabel,
            );

      if (result['success'] == true) {
        // Remove optimistic message
        messages.removeWhere((m) => m.id == optimistic.id);

        // Add real message
        final msgRaw = result['message'];
        final realMessage = msgRaw is Map
            ? ChatMessageModel.fromJson(Map<String, dynamic>.from(msgRaw))
            : optimistic;
        messages.add(realMessage);

        if (realMessage.id is int && realMessage.id > lastMessageId) {
          lastMessageId = realMessage.id;
        }

        // Update conversation_id if it was a new conversation
        if (activeConversationId == null && result['conversation_id'] != null) {
          activeConversationId = result['conversation_id'];
          startMessagePolling();
        }

        // Refresh conversation list
        replyTo.value = null;
        viewOnceNext = false;
        loadConversations(showLoading: false);

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      final serverMessage = e is DioException ? _dioErrorMessage(e) : null;
      if (serverMessage != null &&
          serverMessage.isNotEmpty &&
          e is DioException &&
          e.response?.statusCode != 403) {
        Get.snackbar('error'.tr, serverMessage);
      }
      if (e is DioException && e.response?.statusCode == 403) {
        Get.snackbar(
          'Message Blocked',
          e.response?.data['error'] ?? 'You cannot send messages to this user.',
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          colorText: AppColors.error,
        );
      }
      // Mark optimistic as failed
      final idx = messages.indexWhere((m) => m.id == optimistic.id);
      if (idx != -1) {
        messages[idx] = ChatMessageModel(
          id: optimistic.id,
          body: optimistic.body,
          senderId: optimistic.senderId,
          isMine: true,
          senderName: '',
          senderAvatar: '',
          attachment: optimistic.attachment,
          attachmentType: optimistic.attachmentType,
          isRead: false,
          time: 'Failed',
          date: optimistic.date,
          createdAt: optimistic.createdAt,
          isOptimistic: true,
        );
      }
    } finally {
      isSending.value = false;
    }
  }

  // ═══════════════════════════════════════════════
  // Start Conversation
  // ═══════════════════════════════════════════════

  void setReply(ChatMessageModel message) {
    if (message.id is! int) return;
    replyTo.value = message;
  }

  void clearReply() => replyTo.value = null;

  void _replaceMessage(ChatMessageModel message) {
    final idx = messages.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      messages[idx] = message;
    }
  }

  Future<void> reactToMessage(int messageId, String emoji) async {
    try {
      final updated = activeChatKind == 'room'
          ? await _service.reactRoomMessage(messageId, emoji)
          : await _service.reactMessage(messageId, emoji);
      _replaceMessage(updated);
    } catch (e) {
      Get.snackbar('error'.tr, 'react_failed'.tr);
    }
  }

  Future<void> editMessage(int messageId, String body) async {
    try {
      final updated = await _service.editMessage(messageId, body);
      _replaceMessage(updated);
    } catch (e) {
      Get.snackbar('error'.tr, 'edit_failed'.tr);
    }
  }

  Future<void> deleteMessage(int messageId, {required String scope}) async {
    try {
      final result = await _service.deleteMessage(messageId, scope: scope);
      if (scope == 'me') {
        messages.removeWhere((m) => m.id == messageId);
      } else if (result['message'] != null) {
        _replaceMessage(
          ChatMessageModel.fromJson(
            Map<String, dynamic>.from(result['message']),
          ),
        );
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'delete_failed'.tr);
    }
  }

  Future<Map<String, dynamic>?> openViewOnce(int messageId) async {
    try {
      return await _service.openViewOnce(messageId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 410) {
        markViewOnceOpened(messageId);
        Get.snackbar('view_once'.tr, 'view_once_already_opened'.tr);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void markViewOnceOpened(int messageId) {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0 || messages[idx].isMine) return;
    messages[idx] = messages[idx].withViewOnceOpened();
  }

  Future<bool> forwardMessage(int messageId, List<int> userIds) async {
    try {
      await _service.forwardMessage(messageId, userIds);
      Get.snackbar('forward'.tr, 'message_forwarded'.tr);
      return true;
    } catch (e) {
      final msg = e is DioException ? _dioErrorMessage(e) : null;
      Get.snackbar('error'.tr, msg ?? 'forward_failed'.tr);
      return false;
    }
  }

  Future<void> sendGift(int giftId) async {
    if (activeChatKind == 'room') return;
    if (activeConversationId == null && activeUser == null) return;
    try {
      final result = await _service.sendGift(
        giftId: giftId,
        conversationId: activeConversationId,
        userId: activeConversationId == null ? activeUser?.id : null,
      );
      if (result['message'] != null) {
        final real = ChatMessageModel.fromJson(
          Map<String, dynamic>.from(result['message']),
        );
        if (!messages.any((m) => m.id == real.id)) {
          messages.add(real);
        }
        if (real.id is int && real.id > lastMessageId) lastMessageId = real.id;
        _scrollToBottom();
        loadConversations(showLoading: false);
      }
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data['message']?.toString() ?? 'gift_failed'.tr)
          : 'gift_failed'.tr;
      Get.snackbar('gift'.tr, msg);
    }
  }

  Future<void> muteConversation(String duration) async {
    if (activeConversationId == null) return;
    await _service.muteConversation(activeConversationId!, duration);
    await loadConversations(showLoading: false);
  }

  Future<void> unmuteConversation() async {
    if (activeConversationId == null) return;
    await _service.unmuteConversation(activeConversationId!);
    await loadConversations(showLoading: false);
  }

  Timer? _typingTimer;
  Future<void> notifyTyping() async {
    if (activeConversationId == null) return;
    if (_typingTimer?.isActive == true) return;
    _typingTimer = Timer(const Duration(seconds: 2), () {});
    try {
      await _service.sendTyping(activeConversationId!);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> startConversationWith(int userId) async {
    try {
      final result = await _service.startConversation(userId);
      if (result['error'] != null) {
        Get.snackbar('Error', result['error']);
        return null;
      }
      return result;
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      return null;
    }
  }

  /// Start a conversation and auto-send a greeting message.
  /// Used by Marketplace "Message Seller" to auto-send an inquiry.
  Future<void> startConversationAndSendGreeting(
    int userId,
    String greeting,
  ) async {
    try {
      // Start/get conversation
      final result = await startConversationWith(userId);
      if (result == null) return;

      final conversationId = result['conversation_id'] as int?;
      final user = result['user'] as Map<String, dynamic>?;

      if (user != null) {
        final chatUser = ChatUser(
          id: user['id'],
          name: user['name'] ?? 'User',
          avatar: user['avatar_url'] ?? '',
          isOnline: user['is_online'] ?? false,
        );

        // Open the conversation
        await openConversation(conversationId!, chatUser);

        // Auto-send the greeting
        await sendMessage(body: greeting);

        // Navigate to chat page
        Get.off(() => ChatPage(conversationId: conversationId, user: chatUser));
      }
    } catch (e) {
      debugPrint('Error starting conversation with greeting: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // Search Users
  // ═══════════════════════════════════════════════

  Future<void> searchUsers(String query) async {
    try {
      final users = await _service.searchUsers(query);
      searchResults.assignAll(users);
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // Conversation Settings
  // ═══════════════════════════════════════════════

  Future<void> updateSetting(
    int conversationId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _service.updateSettings(conversationId, data);
      if (result['success'] == true) {
        // Update local conversation settings
        final idx = conversations.indexWhere((c) => c.id == conversationId);
        if (idx != -1) {
          final conv = conversations[idx];
          conversations[idx] = ConversationModel(
            id: conv.id,
            user: conv.user,
            lastMessage: conv.lastMessage,
            unreadCount: conv.unreadCount,
            settings: Map<String, dynamic>.from(result['settings'] ?? {}),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // 3-Tier Context-Aware Polling
  // ═══════════════════════════════════════════════

  /// Chat screen open → poll every 3-5 seconds for new messages
  void startMessagePolling() {
    stopMessagePolling();
    if (activeConversationId == null) return;

    _messagePollingTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollNewMessages(),
    );
  }

  void stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
  }

  /// Chat list screen → poll every 10-15 seconds for conversation updates + unread count
  void startListPolling() {
    stopListPolling();

    _listPollingTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _pollConversationList(),
    );
  }

  void stopListPolling() {
    _listPollingTimer?.cancel();
    _listPollingTimer = null;
  }

  /// Stop all polling (when leaving chat-related pages entirely)
  void stopAllPolling() {
    stopMessagePolling();
    stopListPolling();
  }

  Future<bool> deleteConversation(int conversationId) async {
    try {
      final success = await _service.deleteConversation(conversationId);
      if (success) {
        conversations.removeWhere((c) => c.id == conversationId);
        if (activeConversationId == conversationId) {
          stopMessagePolling();
          activeConversationId = null;
          activeUser = null;
          messages.clear();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      return false;
    }
  }

  Future<void> reportUser(int conversationId, String reason) async {
    await updateSetting(conversationId, {'report': reason});
    Get.snackbar(
      'Report Submitted',
      'The user has been reported for: $reason',
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
    );
  }

  Future<void> _pollNewMessages() async {
    if (activeConversationId == null) return;

    try {
      if (activeChatKind == 'room') {
        final result = await _service.getRoomMessages(activeConversationId!);
        final items = result['items'] as List<ChatMessageModel>;
        for (final msg in items.where((m) => m.id is int && m.id > lastMessageId)) {
          if (!messages.any((m) => m.id == msg.id)) {
            messages.add(msg);
          }
          if (msg.id is int && msg.id > lastMessageId) {
            lastMessageId = msg.id;
          }
        }
        return;
      }

      final result = await _service.pollMessages(
        activeConversationId!,
        afterId: lastMessageId,
        since: _pollSince,
      );

      otherUserTyping.value = result['typing'] == true;

      final updates = result['updates'] as List<ChatMessageModel>;
      for (final upd in updates) {
        final idx = messages.indexWhere((m) => m.id == upd.id);
        if (idx >= 0) {
          messages[idx] = messages[idx].copyWithMerged(upd);
        }
      }

      final newMessages = result['messages'] as List<ChatMessageModel>;
      if (newMessages.isNotEmpty || updates.isNotEmpty) {
        _pollSince = DateTime.now().toUtc().toIso8601String();
      }

      for (final msg in newMessages) {
        if (!messages.any((m) => m.id == msg.id)) {
          messages.add(msg);
        }
        if (msg.id is int && msg.id > lastMessageId) {
          lastMessageId = msg.id;
        }
      }

      _scrollToBottomIfNear();
      loadConversations(showLoading: false);
    } catch (e) {
      debugPrint('Message polling error: $e');
    }
  }

  Future<void> _pollConversationList() async {
    try {
      final result = await _service.getConversations(
        page: 1,
        box: currentBox.value,
      );
      conversations.assignAll(result['items'] as List<ConversationModel>);
      final counts = result['counts'] as Map<String, dynamic>?;
      if (counts != null) {
        requestsCount.value = counts['requests'] is int
            ? counts['requests']
            : int.tryParse(counts['requests'].toString()) ?? 0;
        spamCount.value = counts['spam'] is int
            ? counts['spam']
            : int.tryParse(counts['spam'].toString()) ?? 0;
      }
      await _fetchUnreadCount();
    } catch (e) {
      debugPrint('List polling error: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // Request Operations & Settings
  // ═══════════════════════════════════════════════

  Future<bool> acceptRequest(int conversationId) async {
    final success = await _service.acceptRequest(conversationId);
    if (success) {
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        conversations[idx] = conversations[idx].copyWith(
          status: 'inbox',
          isPendingRequest: false,
          isSpam: false,
        );
      }
      if (requestsCount.value > 0) requestsCount.value--;
      await loadConversations(box: 'inbox', showLoading: false);
    }
    return success;
  }

  Future<bool> declineRequest(int conversationId) async {
    final success = await _service.declineRequest(conversationId);
    if (success) {
      conversations.removeWhere((c) => c.id == conversationId);
      if (requestsCount.value > 0) requestsCount.value--;
      if (spamCount.value > 0) spamCount.value--;
    }
    return success;
  }

  Future<bool> markSpam(int conversationId) async {
    final success = await _service.markSpam(conversationId);
    if (success) {
      final idx = conversations.indexWhere((c) => c.id == conversationId);
      if (idx != -1) {
        conversations[idx] = conversations[idx].copyWith(
          status: 'spam',
          isPendingRequest: false,
          isSpam: true,
        );
      }
      if (requestsCount.value > 0) requestsCount.value--;
      spamCount.value++;
    }
    return success;
  }

  Future<Map<String, dynamic>?> getMessageSettings() async {
    return await _service.getMessageSettings();
  }

  Future<bool> updateMessageSettings({
    required String privacy,
    required bool spamFilter,
    String? spamKeywords,
  }) async {
    return await _service.updateMessageSettings(
      privacy: privacy,
      spamFilter: spamFilter,
      spamKeywords: spamKeywords,
    );
  }

  // ═══════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════

  void _updateConversationUnread(int conversationId, int count) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final conv = conversations[idx];
      conversations[idx] = conv.copyWith(unreadCount: count);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!messagesScrollController.hasClients) return;
      final positions = messagesScrollController.positions;
      if (positions.isEmpty) return;
      final position = positions.last;
      if (!position.hasContentDimensions) return;
      position.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToBottomIfNear() {
    if (!messagesScrollController.hasClients) return;
    final positions = messagesScrollController.positions;
    if (positions.isEmpty) return;
    final position = positions.last;
    if (!position.hasContentDimensions) return;
    final isNearBottom = position.pixels >= position.maxScrollExtent - 150;
    if (isNearBottom) {
      _scrollToBottom();
    }
  }

  int get currentUserId {
    try {
      final storage = GetStorage();
      final userData = storage.read('user');
      if (userData != null) {
        return int.tryParse(userData['id'].toString()) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isImageFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext);
  }

  bool _isVideoFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'flv'].contains(ext);
  }

  String? _dioErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is Map) {
      for (final entry in errors.values) {
        if (entry is List && entry.isNotEmpty) {
          return entry.first.toString();
        }
      }
    }
    final message = data['message']?.toString();
    return message != null && message.isNotEmpty ? message : null;
  }
}
