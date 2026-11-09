import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/thread_controller.dart';
import '../../data/models/thread_model.dart';
import '../../utils/app_theme.dart';

class ThreadDetailPage extends StatefulWidget {
  final int threadId;

  const ThreadDetailPage({super.key, required this.threadId});

  @override
  State<ThreadDetailPage> createState() => _ThreadDetailPageState();
}

class _ThreadDetailPageState extends State<ThreadDetailPage> {
  final ThreadController controller = Get.find<ThreadController>();
  final TextEditingController replyController = TextEditingController();
  final List<File> selectedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    controller.loadThreadDetail(widget.threadId);
  }

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  void _showEditThreadDialog(BuildContext context, ThreadModel thread) {
    final contentEditController = TextEditingController(text: thread.content);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('edit_thread'.tr, style: AppTextStyles.h3),
          content: TextField(
            controller: contentEditController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'thread_content'.tr,
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
                  await controller.updateThread(
                    threadId: thread.id,
                    content: newContent,
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

  void _showEditReplyDialog(BuildContext context, ThreadModel reply, int mainThreadId) {
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
                    threadId: mainThreadId,
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
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
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
        title: Text('thread_discussion'.tr, style: AppTextStyles.h3),
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final thread = controller.currentThread.value;
        if (thread == null) {
          return Center(child: Text('thread_not_found'.tr));
        }

        final canEditMainThread = currentUser != null && (currentUser.id == thread.userId || currentUser.isAdmin);

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Thread Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: thread.authorAvatar != null ? NetworkImage(thread.authorAvatar!) : null,
                                child: thread.authorAvatar == null ? const Icon(Icons.person, size: 18) : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  thread.authorName ?? 'User',
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_formatDate(thread.createdAt), style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                              if (canEditMainThread) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showEditThreadDialog(context, thread),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.edit_note_outlined, color: AppColors.primary, size: 20),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _confirmDeleteThread(context, thread.id),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(thread.content, style: AppTextStyles.bodyLarge.copyWith(height: 1.4)),
                          if (thread.media.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: thread.media.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, idx) {
                                  final m = thread.media[idx];
                                  return GestureDetector(
                                    onTap: () => _showImagePreview(context, m.url),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        m.url,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 100,
                                          height: 100,
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
                    const SizedBox(height: 20),

                    // Replies
                    Text('${'replies'.tr} (${thread.replies.length})', style: AppTextStyles.h3.copyWith(fontSize: 16)),
                    const SizedBox(height: 12),

                    if (thread.replies.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text('no_replies_yet'.tr, style: AppTextStyles.bodyMedium),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: thread.replies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final r = thread.replies[index];
                          final canEditReply = currentUser != null && (currentUser.id == r.userId || currentUser.isAdmin);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.12)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundImage: r.authorAvatar != null ? NetworkImage(r.authorAvatar!) : null,
                                      child: r.authorAvatar == null ? const Icon(Icons.person, size: 12) : null,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        r.authorName ?? 'User',
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(_formatDate(r.createdAt), style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                                    if (canEditReply) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _showEditReplyDialog(context, r, thread.id),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(Icons.edit_note_outlined, color: AppColors.primary, size: 18),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _confirmDeleteReply(context, r.id, thread.id),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r.content, style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                                if (r.media.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 70,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: r.media.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                                      itemBuilder: (context, mIdx) {
                                        final m = r.media[mIdx];
                                        final isImg = m.fileType == 'image' || m.url.contains('.jpg') || m.url.contains('.png') || m.url.contains('.jpeg') || m.url.contains('.webp');
                                        if (isImg) {
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
                                        }
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const HugeIcon(icon: HugeIcons.strokeRoundedAttachment, color: AppColors.primary, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                m.fileName.isNotEmpty ? m.fileName : 'attachment'.tr,
                                                style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Reply input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedFiles.isNotEmpty) ...[
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedFiles.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(selectedFiles[index], width: 60, height: 60, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: InkWell(
                                    onTap: () => setState(() => selectedFiles.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, color: Colors.white, size: 10),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAttachment, color: AppColors.primary, size: 20),
                          onPressed: _pickImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: replyController,
                            decoration: InputDecoration(
                              hintText: 'reply_to_thread'.tr,
                              hintStyle: AppTextStyles.bodySmall,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSent, color: AppColors.primary, size: 24),
                          onPressed: () async {
                            final txt = replyController.text.trim();
                            if (txt.isNotEmpty || selectedFiles.isNotEmpty) {
                              final filesToUpload = List<File>.from(selectedFiles);
                              replyController.clear();
                              setState(() => selectedFiles.clear());
                              await controller.replyThread(threadId: widget.threadId, content: txt, attachments: filesToUpload);
                            }
                          },
                        ),
                      ],
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

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just_now'.tr;
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }

  void _confirmDeleteThread(BuildContext context, int threadId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('delete_thread'.tr),
        content: Text('delete_thread_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await controller.deleteThread(threadId);
              if (success && context.mounted) {
                Navigator.of(context).pop();
                Get.snackbar(
                  'success'.tr,
                  'thread_deleted_successfully'.tr,
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

  void _confirmDeleteReply(BuildContext context, int replyId, int threadId) {
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
              await controller.deleteReply(replyId, threadId);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
