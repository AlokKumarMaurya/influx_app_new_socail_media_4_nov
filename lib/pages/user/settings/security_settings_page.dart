import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../data/services/settings_service.dart';
import '../../../utils/app_theme.dart';
import 'settings_widgets.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserSettingsController>();
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('password_and_security'.tr, style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchSessions(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsWidgets.buildSectionHeader('login'.tr),
              _buildPasswordSection(controller, currentPassController, newPassController, confirmPassController),
              
              const SizedBox(height: 30),
              SettingsWidgets.buildSectionHeader('where_youre_logged_in'.tr),
              _buildSessionsSection(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection(
    UserSettingsController controller,
    TextEditingController currentPass,
    TextEditingController newPass,
    TextEditingController confirmPass,
  ) {
    return Column(
      children: [
        SettingsWidgets.buildTextField('current_password'.tr, currentPass, isPassword: true),
        SettingsWidgets.buildTextField('new_password'.tr, newPass, isPassword: true),
        SettingsWidgets.buildTextField('confirm_new_password'.tr, confirmPass, isPassword: true),
        const SizedBox(height: 15),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () async {
                      if (newPass.text != confirmPass.text) {
                        Get.snackbar('error'.tr, 'passwords_do_not_match'.tr);
                        return;
                      }
                      final result = await Get.find<SettingsService>().changePassword({
                        'current_password': currentPass.text,
                        'password': newPass.text,
                        'password_confirmation': confirmPass.text,
                      });
                      if (result['success']) {
                        currentPass.clear();
                        newPass.clear();
                        confirmPass.clear();
                        Get.snackbar('success'.tr, 'password_changed_successfully'.tr);
                      } else {
                        final rawMsg = result['message']?.toString() ?? 'failed_to_change_password'.tr;
                        Get.snackbar('error'.tr, rawMsg.tr);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'update_password'.tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsSection(UserSettingsController controller) {
    return Obx(() {
      if (controller.sessions.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('no_active_sessions_found'.tr),
          ),
        );
      }

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => SettingsWidgets.confirmAction(
                  'log_out_all_other_sessions_question'.tr,
                  () => controller.revokeAllOthers(),
                ),
                child: Text('log_out_all_others'.tr, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.sessions.length,
            itemBuilder: (context, index) {
              final session = controller.sessions[index];
              bool isCurrent = session['is_current'] == true;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    _getDeviceIcon(session['device_type']),
                    color: AppColors.primary,
                  ),
                ),
                title: Text('${session['platform'] ?? 'Unknown'} • ${session['browser'] ?? 'Unknown'}'),
                subtitle: Text(
                  '${session['ip_address']} • ${isCurrent ? "Active Now" : "Last active: ${session['last_activity'] ?? ''}"}',
                ),
                trailing: isCurrent
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.logout, color: Colors.grey),
                        onPressed: () => SettingsWidgets.confirmAction(
                          'Revoke this session?',
                          () => controller.revokeSession(session['id']),
                        ),
                      ),
              );
            },
          ),
        ],
      );
    });
  }

  IconData _getDeviceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet_android;
      default:
        return Icons.desktop_windows;
    }
  }
}
