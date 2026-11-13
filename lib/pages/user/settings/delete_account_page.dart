import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../utils/app_theme.dart';
import 'settings_widgets.dart';

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserSettingsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('delete_account'.tr, style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningCard(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard(UserSettingsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFBABA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'warning_permanent_action'.tr,
                  style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('delete_account_warning_desc'.tr),
          const SizedBox(height: 24),
          Text('enter_password_to_delete'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SettingsWidgets.buildTextField('current_password'.tr, controller.deletePasswordController, isPassword: true),
          const SizedBox(height: 16),
          Text('type_delete_to_confirm'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SettingsWidgets.buildTextField('confirmation'.tr, controller.deleteConfirmController),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => SettingsWidgets.confirmAction(
                'confirm_delete_account_msg'.tr,
                () => controller.deleteAccount(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('permanently_delete_my_account'.tr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
