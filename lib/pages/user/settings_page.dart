import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../utils/app_theme.dart';
import '../common/hidden_posts_page.dart';
import '../common/my_reports_page.dart';
import 'settings/personal_info_page.dart';
import 'settings/notification_settings_page.dart';
import 'settings/privacy_settings_page.dart';
import 'settings/security_settings_page.dart';
import 'settings/blocked_users_page.dart';
import 'settings/kyc_verification_page.dart';
import 'settings/professional_tools_page.dart';
import 'settings/delete_account_page.dart';
import 'badge_shop_page.dart';

import '../../controllers/language_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _getLanguageName(String code) {
    switch (code) {
      case 'bn':
        return 'Bengali (বাংলা)';
      case 'it':
        return 'Italian (Italiano)';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_language'.tr,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                title: const Text('English'),
                trailing: languageController.currentLocale.value.languageCode == 'en'
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageController.changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇧🇩', style: TextStyle(fontSize: 22)),
                title: const Text('Bengali (বাংলা)'),
                trailing: languageController.currentLocale.value.languageCode == 'bn'
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageController.changeLanguage('bn');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text('🇮🇹', style: TextStyle(fontSize: 22)),
                title: const Text('Italian (Italiano)'),
                trailing: languageController.currentLocale.value.languageCode == 'it'
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  languageController.changeLanguage('it');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(() => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('settings_and_privacy'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'account'.tr,
              description: 'manage_personal_info_desc'.tr,
              items: [
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedUser,
                  title: 'personal_information'.tr,
                  subtitle: 'update_name_email_bio'.tr,
                  onTap: () => Get.to(() => const PersonalInfoPage()),
                ),
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedShield01,
                  title: 'password_and_security'.tr,
                  subtitle: 'change_password_sessions'.tr,
                  onTap: () => Get.to(() => const SecuritySettingsPage()),
                ),
              ],
            ),
            _buildSection(
              title: 'preferences'.tr,
              description: 'customize_experience_desc'.tr,
              items: [
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedGlobal,
                  title: 'language'.tr,
                  subtitle: _getLanguageName(languageController.currentLocale.value.languageCode),
                  onTap: () => _showLanguageBottomSheet(context),
                ),
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedNotification01,
                  title: 'notifications'.tr,
                  subtitle: 'choose_notifications'.tr,
                  onTap: () => Get.to(() => const NotificationSettingsPage()),
                ),
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedAward01,
                  title: 'profile_badges_and_storage'.tr,
                  subtitle: 'buy_badges_manage_storage'.tr,
                  onTap: () => Get.to(() => const BadgeShopPage()),
                ),
              ],
            ),
            _buildSection(
              title: 'audience_and_visibility'.tr,
              description: 'control_visibility_desc'.tr,
              items: [
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedLockPassword,
                  title: 'privacy'.tr,
                  subtitle: 'manage_profile_post_visibility'.tr,
                  onTap: () => Get.to(() => const PrivacySettingsPage()),
                ),
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedUserBlock01,
                  title: 'blocking'.tr,
                  subtitle: 'review_blocked_people'.tr,
                  onTap: () => Get.to(() => const BlockedUsersPage()),
                ),
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedViewOffSlash,
                  title: 'hidden_posts'.tr,
                  subtitle: 'manage_hidden_posts'.tr,
                  onTap: () => Get.to(() => const HiddenPostsPage()),
                ),
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedFlag01,
                  title: 'my_reports'.tr,
                  subtitle: 'track_submitted_reports'.tr,
                  onTap: () => Get.to(() => const MyReportsPage()),
                ),
              ],
            ),
            _buildSection(
              title: 'verification_and_tools'.tr,
              description: 'professional_tools_desc'.tr,
              items: [
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedLicense,
                  title: 'identity_verification'.tr,
                  subtitle: 'kyc_official_id_upload'.tr,
                  onTap: () => Get.to(() => const KycVerificationPage()),
                ),
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedSettings01,
                  title: 'professional_tools'.tr,
                  subtitle: 'creator_business_profile_settings'.tr,
                  onTap: () => Get.to(() => const ProfessionalToolsPage()),
                ),
              ],
            ),
            _buildSection(
              title: 'account_management'.tr,
              items: [
                _buildSettingTile(
                  icon: HugeIcons.strokeRoundedDelete01,
                  title: 'delete_account'.tr,
                  subtitle: 'permanently_remove_account'.tr,
                  onTap: () => Get.to(() => const DeleteAccountPage()),
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ));
  }

  Widget _buildSection({
    required String title,
    String? description,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required dynamic icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: HugeIcon(
          icon: icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade500),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
