import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../utils/app_theme.dart';
import 'settings_widgets.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserSettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('notifications'.tr, style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshSettings(1),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsWidgets.buildSectionHeader('notification_preferences'.tr),
              SettingsWidgets.buildSwitchTile('friend_requests'.tr, controller.notifyFriendRequests),
              SettingsWidgets.buildSwitchTile('messages'.tr, controller.notifyMessages),
              SettingsWidgets.buildSwitchTile('comments'.tr, controller.notifyComments),
              SettingsWidgets.buildSwitchTile('likes'.tr, controller.notifyLikes),
              SettingsWidgets.buildSwitchTile('shares'.tr, controller.notifyShares),
              SettingsWidgets.buildSwitchTile('group_activity'.tr, controller.notifyGroupActivity),
              SettingsWidgets.buildSwitchTile('mentions'.tr, controller.notifyMentions),
              SettingsWidgets.buildSwitchTile('email_notifications'.tr, controller.notifyEmail),

              const SizedBox(height: 30),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.updateNotifications(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'save_preferences'.tr,
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
