import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/support_controller.dart';
import '../../utils/app_theme.dart';
import '../../utils/url_utils.dart';

class TicketDetailsPage extends StatefulWidget {
  final int ticketId;
  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  final SupportController controller = Get.find<SupportController>();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.fetchTicketDetails(widget.ticketId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
          controller.currentTicket.value?.subject ?? 'ticket_details'.tr,
          style: AppTextStyles.h3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.detailsLoading.value && controller.ticketMessages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.ticketMessages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildTicketHeader();
                  
                  final message = controller.ticketMessages[index - 1];
                  return _buildMessageBubble(message);
                },
              );
            }),
          ),
          _buildReplyInput(),
        ],
      ),
    );
  }

  Widget _buildTicketHeader() {
    final ticket = controller.currentTicket.value;
    if (ticket == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ticket_info'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#TK-${ticket.id}',
                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _headerRow('category'.tr, ticket.category),
          const SizedBox(height: 8),
          _headerRow('priority'.tr, ticket.priority),
          const SizedBox(height: 8),
          _headerRow('status'.tr, ticket.status),
          const SizedBox(height: 8),
          _headerRow('created'.tr, ticket.createdAt),
        ],
      ),
    );
  }

  Widget _headerRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    final isAdmin = message.isAdmin;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.support_agent, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin ? AppColors.cardBg : AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAdmin ? 0 : 16),
                      bottomRight: Radius.circular(isAdmin ? 16 : 0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isAdmin ? AppColors.textMain : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: message.attachments.map<Widget>((url) {
                            return GestureDetector(
                              onTap: () {}, // view attachment
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.attach_file, size: 14, color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    message.createdAt,
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage: message.userAvatar != null 
                ? CachedNetworkImageProvider(UrlUtils.getFullUrl(message.userAvatar!)) 
                : null,
              child: message.userAvatar == null ? const Icon(Icons.person, size: 16) : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Obx(() => controller.selectedFiles.isEmpty ? const SizedBox.shrink() : _buildSelectedFilesRow()),
          Row(
            children: [
              IconButton(
                onPressed: () => controller.pickFiles(),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedAttachment01, color: AppColors.primary, size: 24),
              ),
              Expanded(
                child: TextField(
                  controller: _replyController,
                  decoration: InputDecoration(
                    hintText: 'type_your_reply'.tr,
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  maxLines: null,
                ),
              ),
              Obx(() => IconButton(
                onPressed: controller.isSubmitting.value ? null : _sendReply,
                icon: controller.isSubmitting.value 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const HugeIcon(icon: HugeIcons.strokeRoundedSent, color: AppColors.primary, size: 24),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilesRow() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.selectedFiles.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.insert_drive_file, size: 24),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => controller.removeFile(index),
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 10),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sendReply() async {
    final message = _replyController.text;
    final success = await controller.sendReply(widget.ticketId, message);
    if (success) {
      _replyController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
