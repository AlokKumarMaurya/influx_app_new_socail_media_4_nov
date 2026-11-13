import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import '../../../utils/app_theme.dart';

class SettingsWidgets {
  static Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(color: AppColors.primary),
      ),
    );
  }

  static Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool isPassword = false,
    bool enabled = true,
    Widget? trailingLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              ?trailingLabel,
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            obscureText: isPassword,
            enabled: enabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildDropdown(
    String label,
    Rx<String?> value,
    List<DropdownMenuItem<String>> items, {
    Widget? trailingLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            ?trailingLabel,
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.any((item) => item.value == value.value)
                    ? value.value
                    : null,
                isExpanded: true,
                items: items,
                onChanged: (v) => value.value = v,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildPrivacySelector(String field, dynamic controller) {
    return Obx(() {
      final current = controller.getFieldPrivacy(field);
      final icon = current == 'only_me'
          ? Icons.lock_outline
          : (current == 'friends' ? Icons.people_outline : Icons.public);
      final title = current == 'only_me'
          ? 'privacy_only_me'.tr
          : (current == 'friends' ? 'privacy_friends'.tr : 'privacy_public'.tr);

      return PopupMenuButton<String>(
        tooltip: 'who_can_see_this'.tr,
        initialValue: current,
        onSelected: (val) => controller.setFieldPrivacy(field, val),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.isDark ? Colors.white10 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.isDark ? Colors.white70 : Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade600),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'public',
            child: Row(
              children: [
                const Icon(Icons.public, size: 16),
                const SizedBox(width: 8),
                Text('privacy_public'.tr),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'friends',
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 8),
                Text('privacy_friends'.tr),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'only_me',
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16),
                const SizedBox(width: 8),
                Text('privacy_only_me'.tr),
              ],
            ),
          ),
        ],
      );
    });
  }

  static Widget buildSwitchTile(String title, RxBool value) {
    return Obx(
      () => SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 15)),
        value: value.value,
        activeThumbColor: AppColors.primary,
        onChanged: (v) => value.value = v,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  static Widget buildInfoBanner(
    String title,
    String message,
    Color borderColor,
    Color bgColor,
    dynamic icon,
  ) {
    final isDark = AppColors.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [borderColor, borderColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h4.copyWith(
                    color: isDark ? Colors.white : borderColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.grey : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildImagePickerTile(
    String label,
    Rx<File?> file,
    VoidCallback onTap, {
    bool isWide = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Obx(
          () => InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: isWide ? 150 : 120,
              decoration: BoxDecoration(
                color: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  style: BorderStyle.solid,
                ),
                image: file.value != null
                    ? DecorationImage(
                        image: FileImage(file.value!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: file.value == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: Colors.grey,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'select_image'.tr,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  static void confirmAction(String message, VoidCallback onConfirm) {
    Get.dialog(
      AlertDialog(
        title: Text('confirm'.tr),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            child: Text('confirm'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
