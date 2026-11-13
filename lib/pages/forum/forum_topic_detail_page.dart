import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/forum_controller.dart';
import '../../data/models/forum_model.dart';
import '../../utils/app_theme.dart';

class ForumTopicDetailPage extends StatefulWidget {
  final String slug;

  const ForumTopicDetailPage({super.key, required this.slug});

  @override
  State<ForumTopicDetailPage> createState() => _ForumTopicDetailPageState();
}

class _ForumTopicDetailPageState extends State<ForumTopicDetailPage> {
  final ForumController controller = Get.find<ForumController>();
  final TextEditingController replyTextController = TextEditingController();
  final List<File> selectedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    controller.loadTopicDetail(widget.slug);
  }

  @override
  void dispose() {
    replyTextController.dispose();
    super.dispose();
  }

  void _showEditTopicDialog(BuildContext context, ForumTopicModel topic) {
    final titleEditController = TextEditingController(text: topic.title);
    final contentEditController = TextEditingController(text: topic.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('edit_topic'.tr, style: AppTextStyles.h3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleEditController,
                  decoration: InputDecoration(
                    labelText: 'topic_title'.tr,
                    labelStyle: AppTextStyles.bodySmall,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentEditController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'topic_content'.tr,
                    labelStyle: AppTextStyles.bodySmall,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newTitle = titleEditController.text.trim();
                final newContent = contentEditController.text.trim();
                if (newTitle.isNotEmpty && newContent.isNotEmpty) {
                  Navigator.of(context).pop();
                  await controller.updateTopic(
                    topicId: topic.id,
                    title: newTitle,
                    categoryId: topic.categoryId,
                    content: newContent,
                    topicSlug: topic.slug,
                  );
                }
              },
              child: Text('save'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditReplyDialog(BuildContext context, ForumReplyModel reply, String topicSlug) {
    final contentEditController = TextEditingController(text: reply.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('edit_reply'.tr, style: AppTextStyles.h3),
          content: TextField(
            controller: contentEditController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'reply_content'.tr,
              labelStyle: AppTextStyles.bodySmall,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newContent = contentEditController.text.trim();
                if (newContent.isNotEmpty) {
                  Navigator.of(context).pop();
                  await controller.updateReply(
                    replyId: reply.id,
                    content: newContent,
                    topicSlug: topicSlug,
                  );
                }
              },
              child: Text('save'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        selectedFiles.add(File(picked.path));
      });
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade900,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image, color: Colors.white70, size: 48),
                        const SizedBox(height: 8),
                        Text('image_failed_to_load'.tr, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Get.find<AuthController>().user.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text('topic_discussion'.tr, style: AppTextStyles.h3),
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final topic = controller.currentTopic.value;
        if (topic == null) {
          return Center(child: Text('topic_not_found'.tr));
        }

        final canEditTopic = currentUser != null && (currentUser.id == topic.userId || currentUser.isAdmin);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (topic.category != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    topic.category!.name,
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              if (topic.subcategory != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '↳ ${topic.subcategory!.name}',
                                    style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                              if (topic.isSolved)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const HugeIcon(icon: HugeIcons.strokeRoundedTick01, color: Colors.green, size: 14),
                                      const SizedBox(width: 4),
                                      Text('solved'.tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(topic.title, style: AppTextStyles.h2.copyWith(fontSize: 18)),
                              ),
                              if (canEditTopic) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_note_outlined, color: AppColors.primary, size: 22),
                                  onPressed: () => _showEditTopicDialog(context, topic),
                                  tooltip: 'edit_topic'.tr,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDeleteTopic(context, topic.id),
                                  tooltip: 'delete_topic'.tr,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: topic.authorAvatar != null ? NetworkImage(topic.authorAvatar!) : null,
                                child: topic.authorAvatar == null ? const Icon(Icons.person, size: 16) : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  topic.authorName ?? 'user'.tr,
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_formatDate(topic.createdAt), style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(topic.content, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),

                          // Media attachments
                          if (topic.media.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: topic.media.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final m = topic.media[index];
                                  return GestureDetector(
                                    onTap: () => _showImagePreview(context, m.url),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        m.url,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.withOpacity(0.15),
                                          child: const Icon(Icons.broken_image, size: 24),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Replies Section Header
                    Row(
                      children: [
                        const Icon(Icons.forum_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${'replies'.tr} (${topic.replies.length})',
                          style: AppTextStyles.h3.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (topic.replies.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'no_replies_yet_be_first'.tr,
                            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topic.replies.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final reply = topic.replies[index];
                          return _buildReplyCard(context, reply, topic.slug);
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Reply input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: AppColors.textSecondary, size: 22),
                      onPressed: _pickImage,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: replyTextController,
                        decoration: InputDecoration(
                          hintText: 'write_a_reply'.tr,
                          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => controller.isSubmitting.value
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const HugeIcon(icon: HugeIcons.strokeRoundedSent, color: AppColors.primary, size: 24),
                              onPressed: () async {
                                final txt = replyTextController.text.trim();
                                if (txt.isNotEmpty || selectedFiles.isNotEmpty) {
                                  final filesToUpload = List<File>.from(selectedFiles);
                                  replyTextController.clear();
                                  setState(() => selectedFiles.clear());
                                  await controller.replyToTopic(topicSlug: topic.slug, content: txt, attachments: filesToUpload);
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildReplyCard(BuildContext context, ForumReplyModel reply, String topicSlug) {
    final authController = Get.find<AuthController>();
    final currentUser = authController.user.value;
    final canEditReply = currentUser != null && (currentUser.id == reply.userId || currentUser.isAdmin);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reply.isSolution ? Colors.green.withOpacity(0.05) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reply.isSolution ? Colors.green : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: reply.authorAvatar != null ? NetworkImage(reply.authorAvatar!) : null,
                child: reply.authorAvatar == null ? const Icon(Icons.person, size: 14) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reply.authorName ?? 'user'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (reply.isSolution) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                  child: Text('best_answer'.tr, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(width: 6),
              Text(_formatDate(reply.createdAt), style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
              if (canEditReply) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showEditReplyDialog(context, reply, topicSlug),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.edit_note_outlined, color: AppColors.primary, size: 18),
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDeleteReply(context, reply.id, topicSlug),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(reply.content, style: AppTextStyles.bodyMedium),
          if (reply.media.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: reply.media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, idx) {
                  final m = reply.media[idx];
                  return GestureDetector(
                    onTap: () => _showImagePreview(context, m.url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        m.url,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.withOpacity(0.15),
                          child: const Icon(Icons.broken_image, size: 18),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteTopic(BuildContext context, int topicId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('delete_topic'.tr),
        content: Text('delete_topic_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await controller.deleteTopic(topicId);
              if (success && context.mounted) {
                Navigator.of(context).pop();
                Get.snackbar(
                  'success'.tr,
                  'topic_deleted_successfully'.tr,
                  backgroundColor: AppColors.success,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReply(BuildContext context, int replyId, String topicSlug) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_reply'.tr),
        content: Text('delete_reply_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteReply(replyId, topicSlug);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
