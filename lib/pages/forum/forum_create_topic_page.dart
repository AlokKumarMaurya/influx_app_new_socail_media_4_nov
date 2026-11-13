import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/forum_controller.dart';
import '../../utils/app_theme.dart';

class ForumCreateTopicPage extends StatefulWidget {
  const ForumCreateTopicPage({super.key});

  @override
  State<ForumCreateTopicPage> createState() => _ForumCreateTopicPageState();
}

class _ForumCreateTopicPageState extends State<ForumCreateTopicPage> {
  final ForumController controller = Get.find<ForumController>();

  int? selectedCategoryId;
  int? selectedSubcategoryId;
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final List<File> selectedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        selectedFiles.add(File(picked.path));
      });
    }
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
        title: Text('start_new_topic'.tr, style: AppTextStyles.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Subcategory Dropdowns
            Text('category'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: Text('select_a_category'.tr),
                    value: selectedCategoryId,
                    items: controller.categories.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedCategoryId = val;
                        selectedSubcategoryId = null;
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Subcategory Dropdown
            Obx(() {
              final selectedCat = controller.categories.firstWhereOrNull((c) => c.id == selectedCategoryId);
              final hasSubcats = selectedCat != null && selectedCat.subcategories.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('subcategory_optional'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: hasSubcats ? AppColors.cardBg : Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: Text(hasSubcats ? 'select_a_subcategory'.tr : 'none_available'.tr),
                        value: selectedSubcategoryId,
                        items: hasSubcats
                            ? selectedCat.subcategories.map((sub) {
                                return DropdownMenuItem<int>(
                                  value: sub.id,
                                  child: Text(sub.name),
                                );
                              }).toList()
                            : [],
                        onChanged: hasSubcats
                            ? (val) => setState(() => selectedSubcategoryId = val)
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Title
            Text('topic_title'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'what_is_question_or_topic'.tr,
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Text('content_details'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'explain_in_detail'.tr,
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
            ),
            const SizedBox(height: 16),

            // Media Attachments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('attachments'.tr, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedAttachment, color: AppColors.primary, size: 18),
                  label: Text('add_media'.tr, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedFiles.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(selectedFiles[index], width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => setState(() => selectedFiles.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Submit Button
            Obx(() {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () async {
                          if (selectedCategoryId == null || titleController.text.isEmpty || contentController.text.isEmpty) {
                            Get.snackbar('error'.tr, 'please_fill_all_required_fields'.tr);
                            return;
                          }

                          final success = await controller.createTopic(
                            categoryId: selectedCategoryId!,
                            subcategoryId: selectedSubcategoryId,
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            attachments: selectedFiles,
                          );

                          if (success) {
                            Get.back();
                            Get.snackbar(
                              'success'.tr,
                              'topic_published_successfully'.tr,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                              duration: const Duration(seconds: 3),
                            );
                          }
                        },
                  child: controller.isSubmitting.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('publish_topic'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
