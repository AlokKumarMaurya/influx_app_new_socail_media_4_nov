import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/fan_page_chat_model.dart';
import '../../data/models/fan_page_model.dart';
import '../../data/services/fan_page_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/custom_network_image.dart';

class FanPageChatScreen extends StatefulWidget {
  final FanPageModel page;

  const FanPageChatScreen({super.key, required this.page});

  @override
  State<FanPageChatScreen> createState() => _FanPageChatScreenState();
}

class _FanPageChatScreenState extends State<FanPageChatScreen> {
  final FanPageService _service = FanPageService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<FanPageMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedMedia;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    try {
      final res = await _service.getCustomerChat(widget.page.slug);
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty && _selectedMedia == null) return;

    setState(() => _isSending = true);
    final media = _selectedMedia;

    _msgController.clear();
    setState(() => _selectedMedia = null);

    try {
      final res = await _service.sendCustomerMessage(
        widget.page.slug,
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
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                imageUrl: widget.page.avatar,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.flag, size: 20, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.page.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.page.category?.name ?? 'Fan Page',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipOval(
                                child: CustomNetworkImage(
                                  imageUrl: widget.page.avatar,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(widget.page.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                'Send a message to contact ${widget.page.name}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = !msg.isFromPage;

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser) ...[
                                    Text(
                                      widget.page.name,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  if (msg.message != null && msg.message!.isNotEmpty)
                                    Text(
                                      msg.message!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isUser ? Colors.white : Colors.black87,
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
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.page.name}...',
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
                      onPressed: _isSending ? null : _sendMessage,
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
