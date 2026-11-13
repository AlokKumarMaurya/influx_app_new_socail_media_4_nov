import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../utils/app_theme.dart';
import 'message_settings_page.dart';
import 'settings_widgets.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserSettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('privacy_settings'.tr, style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshSettings(2),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsWidgets.buildSectionHeader('privacy_settings'.tr),
              SettingsWidgets.buildDropdown('profile_visibility'.tr, controller.privacyProfile, [
                DropdownMenuItem(value: 'public', child: Text('public'.tr)),
                DropdownMenuItem(value: 'friends', child: Text('friends_only'.tr)),
                DropdownMenuItem(value: 'private', child: Text('private'.tr)),
              ]),
              const SizedBox(height: 15),
              SettingsWidgets.buildDropdown('default_post_privacy'.tr, controller.privacyPosts, [
                DropdownMenuItem(value: 'public', child: Text('public'.tr)),
                DropdownMenuItem(value: 'friends', child: Text('friends'.tr)),
                DropdownMenuItem(value: 'only_me', child: Text('only_me'.tr)),
              ]),
              const SizedBox(height: 15),
              SettingsWidgets.buildDropdown(
                'friends_list_visibility'.tr,
                controller.privacyFriendsList,
                [
                  DropdownMenuItem(value: 'public', child: Text('public'.tr)),
                  DropdownMenuItem(value: 'friends', child: Text('friends'.tr)),
                  DropdownMenuItem(value: 'only_me', child: Text('only_me'.tr)),
                ],
              ),
              const SizedBox(height: 15),
              SettingsWidgets.buildDropdown('photos_and_gallery'.tr, controller.privacyPhotos, [
                DropdownMenuItem(value: 'public', child: Text('public'.tr)),
                DropdownMenuItem(value: 'friends', child: Text('friends'.tr)),
                DropdownMenuItem(value: 'only_me', child: Text('only_me'.tr)),
              ]),

              const SizedBox(height: 20),
              SettingsWidgets.buildSwitchTile(
                'search_visibility'.tr,
                controller.privacySearchVisible,
              ),
              SettingsWidgets.buildSwitchTile('online_status'.tr, controller.privacyOnlineStatus),

              const SizedBox(height: 20),
              InkWell(
                onTap: () => Get.to(() => const MessageSettingsPage()),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_chat_unread_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'message_settings'.tr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'message_delivery_subtitle'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.updatePrivacy(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'save_privacy_settings'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
