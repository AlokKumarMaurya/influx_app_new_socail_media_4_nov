import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/campaign_controller.dart';
import '../../data/models/campaign_model.dart';
import '../../utils/app_theme.dart';
import '../../controllers/settings_controller.dart';

class CampaignCreatePage extends StatefulWidget {
  final CampaignModel? campaign;

  const CampaignCreatePage({super.key, this.campaign});

  @override
  State<CampaignCreatePage> createState() => _CampaignCreatePageState();
}

class _CampaignCreatePageState extends State<CampaignCreatePage> {
  late CampaignController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<CampaignController>()
        ? Get.find<CampaignController>()
        : Get.put(CampaignController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initForm(widget.campaign);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.campaign != null;
    final List<String> availablePlatforms = [
      'instagram',
      'tiktok',
      'youtube',
      'twitter',
      'facebook',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text(isEdit ? 'edit_campaign'.tr : 'create_campaign'.tr, style: AppTextStyles.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildSectionTitle('${'campaign_title'.tr} *'),
            TextField(
              controller: controller.titleController,
              decoration: _buildInputDecoration('eg_summer_fashion_collab'.tr),
            ),
            const SizedBox(height: 16),

            // Description
            _buildSectionTitle('description_offer_details'.tr),
            TextField(
              controller: controller.descriptionController,
              maxLines: 4,
              decoration: _buildInputDecoration('describe_campaign_requirements'.tr),
            ),
            const SizedBox(height: 16),

            // Niche & Campaign Type
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('niche_category'.tr),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedCategoryField.value,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'Fashion', child: Text('fashion'.tr)),
                                  DropdownMenuItem(value: 'Tech', child: Text('tech'.tr)),
                                  DropdownMenuItem(value: 'Food', child: Text('food'.tr)),
                                  DropdownMenuItem(value: 'Travel', child: Text('travel'.tr)),
                                  DropdownMenuItem(value: 'Fitness', child: Text('fitness'.tr)),
                                  DropdownMenuItem(value: 'Beauty', child: Text('beauty'.tr)),
                                  DropdownMenuItem(value: 'Finance', child: Text('finance'.tr)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.selectedCategoryField.value = val;
                                  }
                                },
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('pitch_type'.tr),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedTypeField.value,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'campaign', child: Text('brand_campaign'.tr)),
                                  DropdownMenuItem(value: 'portfolio', child: Text('creator_pitch'.tr)),
                                  DropdownMenuItem(value: 'collab', child: Text('collab_offer'.tr)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.selectedTypeField.value = val;
                                  }
                                },
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Budget Range
            _buildSectionTitle('${'estimated_budget'.tr} (${Get.find<SettingsController>().currency.value})'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.budgetFromController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('${'from'.tr} (${Get.find<SettingsController>().currencySymbol.value})'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: controller.budgetToController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('${'to'.tr} (${Get.find<SettingsController>().currencySymbol.value})'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Platforms Checkbox Wrap
            _buildSectionTitle('target_social_platforms'.tr),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availablePlatforms.map((platform) {
                    final isSelected = controller.selectedPlatforms.contains(platform);
                    return FilterChip(
                      label: Text(platform.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) => controller.togglePlatform(platform),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textMain,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
                      ),
                    );
                  }).toList(),
                )),
            const SizedBox(height: 16),

            // Media Type & Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('content_media_type'.tr),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedMediaType.value,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'image', child: Text('image_portfolio'.tr)),
                                  DropdownMenuItem(value: 'video', child: Text('video_work'.tr)),
                                  DropdownMenuItem(value: 'both', child: Text('both'.tr)),
                                  DropdownMenuItem(value: 'none', child: Text('text_only'.tr)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.selectedMediaType.value = val;
                                  }
                                },
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('status'.tr),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedStatus.value,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'active', child: Text('active_public'.tr)),
                                  DropdownMenuItem(value: 'draft', child: Text('draft_private'.tr)),
                                  if (isEdit) DropdownMenuItem(value: 'closed', child: Text('closed'.tr)),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.selectedStatus.value = val;
                                  }
                                },
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Media Files Uploader
            _buildSectionTitle('attach_media_creative_work'.tr),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: AppColors.primary, size: 36),
                    onPressed: () => controller.pickMedia(),
                  ),
                  const SizedBox(height: 8),
                  Text('upload_images_videos_work'.tr, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal view of currently selected files
            Obx(() {
              if (controller.mediaFiles.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.mediaFiles.length,
                  itemBuilder: (context, index) {
                    final file = controller.mediaFiles[index];
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12, top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => controller.mediaFiles.removeAt(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }),

            // If editing, list currently uploaded media that can be deleted
            if (isEdit && widget.campaign!.media.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('existing_campaign_media'.tr),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.campaign!.media.length,
                  itemBuilder: (context, index) {
                    final mediaItem = widget.campaign!.media[index];
                    final isVideo = mediaItem.type == 'video';
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12, top: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isVideo
                                ? const Center(child: Icon(Icons.play_circle_fill, size: 24))
                                : Image.network(
                                    mediaItem.filePath.startsWith('http')
                                        ? mediaItem.filePath
                                        : 'https://influx.mhquickdev.com/storage/${mediaItem.filePath}',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => controller.deleteMedia(widget.campaign!.id, mediaItem.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.delete, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () => isEdit ? controller.updateCampaign(widget.campaign!.id) : controller.createCampaign(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isSubmitting.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEdit ? 'save_changes'.tr : 'publish_pitch'.tr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                )),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.isDark ? Colors.white10 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
