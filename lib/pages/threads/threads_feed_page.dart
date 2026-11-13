import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/thread_controller.dart';
import '../../data/models/thread_model.dart';
import '../../utils/app_theme.dart';
import 'thread_detail_page.dart';

class ThreadsFeedPage extends StatefulWidget {
  const ThreadsFeedPage({super.key});

  @override
  State<ThreadsFeedPage> createState() => _ThreadsFeedPageState();
}

class _ThreadsFeedPageState extends State<ThreadsFeedPage> {
  final ThreadController controller = Get.put(ThreadController());
  final TextEditingController composerController = TextEditingController();
  final List<File> selectedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    composerController.dispose();
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
                        Text('image_failed_load'.tr, style: const TextStyle(color: Colors.white70)),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text('micro_threads_feed'.tr, style: AppTextStyles.h3),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadThreads,
          child: Column(
            children: [
              // Composer Box
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: composerController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "whats_happening".tr,
                        hintStyle: AppTextStyles.bodySmall,
                        border: InputBorder.none,
                      ),
                    ),
                    if (selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
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
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedAttachment, color: AppColors.primary, size: 20),
                          onPressed: _pickImage,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () async {
                            final txt = composerController.text.trim();
                            if (txt.isNotEmpty || selectedFiles.isNotEmpty) {
                              final filesToUpload = List<File>.from(selectedFiles);
                              composerController.clear();
                              setState(() => selectedFiles.clear());
                              await controller.createThread(content: txt, attachments: filesToUpload);
                            }
                          },
                          child: Text('post'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: controller.threads.isEmpty
                    ? Center(
                        child: Text('no_threads_yet'.tr, style: AppTextStyles.bodyMedium),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: controller.threads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final thread = controller.threads[index];
                          return _buildThreadCard(context, thread, controller);
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildThreadCard(BuildContext context, ThreadModel thread, ThreadController controller) {
    final currentUser = Get.find<AuthController>().user.value;
    final canEditThread = currentUser != null && (currentUser.id == thread.userId || currentUser.isAdmin);

    return InkWell(
      onTap: () => Get.to(() => ThreadDetailPage(threadId: thread.id)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  radius: 16,
                  backgroundImage: thread.authorAvatar != null ? NetworkImage(thread.authorAvatar!) : null,
                  child: thread.authorAvatar == null ? const Icon(Icons.person, size: 16) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thread.authorName ?? 'user'.tr,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(_formatDate(thread.createdAt), style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
                if (canEditThread) ...[
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
            const SizedBox(height: 10),
            Text(thread.content, style: AppTextStyles.bodyMedium.copyWith(height: 1.4)),
            if (thread.media.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: thread.media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final m = thread.media[idx];
                    return GestureDetector(
                      onTap: () => _showImagePreview(context, m.url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          m.url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.withOpacity(0.15),
                            child: const Icon(Icons.broken_image, size: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: () => controller.toggleReaction(thread.id),
                  child: Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedFavourite, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text('${thread.likesCount}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text('${thread.repliesCount}', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteThread(BuildContext context, int threadId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('delete_thread'.tr),
        content: Text('delete_thread_confirm'.tr),
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
              if (success) {
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

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just_now'.tr;
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}
