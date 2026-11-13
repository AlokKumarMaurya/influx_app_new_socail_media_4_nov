import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../controllers/user_settings_controller.dart';
import '../../../utils/app_theme.dart';
import 'settings_widgets.dart';

class ProfessionalToolsPage extends StatelessWidget {
  const ProfessionalToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserSettingsController>();

    return Obx(() {
      final kycApproved = controller.kycStatus.value == 'approved';
      final isCreator = controller.profileType.value == 'creator';
      final isBusiness = controller.profileType.value == 'business' || controller.businessStatus.value == 'approved';
      final isPending = controller.businessStatus.value == 'pending';
      final isDark = AppColors.isDark;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('professional_tools'.tr, style: AppTextStyles.h3),
          backgroundColor: AppColors.cardBg,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchProfessionalStatus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatusBanners(controller, kycApproved, isCreator, isBusiness, isPending),
                if (!isBusiness && !isCreator && !isPending) ...[
                  const SizedBox(height: 24),
                  _buildFeaturesGrid(),
                  const SizedBox(height: 24),
                  _buildCreatorSection(controller, kycApproved, isCreator, isBusiness, isPending, isDark),
                  const SizedBox(height: 32),
                  _buildDividerWithText('or_apply_for_business'.tr),
                ],
                if (isCreator && !isBusiness && !isPending) ...[
                   const SizedBox(height: 24),
                   _buildDividerWithText('upgrade_to_business'.tr),
                ],
                const SizedBox(height: 24),
                _buildBusinessSection(controller, kycApproved, isBusiness, isPending, isDark),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('professional_profile'.tr, style: AppTextStyles.h2),
              Text(
                'professional_profile_subtitle'.tr,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanners(UserSettingsController controller, bool kycApproved, bool isCreator, bool isBusiness, bool isPending) {
    if (!kycApproved) {
      return SettingsWidgets.buildInfoBanner(
        'kyc_required_title'.tr,
        'kyc_required_desc'.tr,
        AppColors.primary,
        Colors.blue.shade50,
        HugeIcons.strokeRoundedLicense,
      );
    }
    if (isCreator) {
      return SettingsWidgets.buildInfoBanner(
        'creator_active'.tr,
        'creator_active_desc'.tr,
        Colors.blue,
        Colors.blue.shade50,
        HugeIcons.strokeRoundedUser,
      );
    }
    if (isPending) {
      return SettingsWidgets.buildInfoBanner(
        'review_in_progress'.tr,
        'business_pending_desc'.tr,
        Colors.orange,
        Colors.orange.shade50,
        HugeIcons.strokeRoundedClock01,
      );
    }
    if (isBusiness) {
      return SettingsWidgets.buildInfoBanner(
        'business_active'.tr,
        'business_active_desc'.tr,
        Colors.green,
        Colors.green.shade50,
        HugeIcons.strokeRoundedFolder01,
      );
    }
    return SettingsWidgets.buildInfoBanner(
      'identity_verified_excl'.tr,
      'eligible_for_professional_desc'.tr,
      AppColors.primary,
      Colors.blue.shade50,
      HugeIcons.strokeRoundedTick01,
    );
  }

  Widget _buildFeaturesGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            'advanced_analytics'.tr,
            'advanced_analytics_desc'.tr,
            HugeIcons.strokeRoundedChartHistogram,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFeatureCard(
            'brand_credibility'.tr,
            'brand_credibility_desc'.tr,
            HugeIcons.strokeRoundedShield01,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatorSection(UserSettingsController controller, bool kycApproved, bool isCreator, bool isBusiness, bool isPending, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('creator_profile'.tr, style: AppTextStyles.h3),
                    Text('creator_profile_desc'.tr, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (kycApproved && !isCreator && !isBusiness && !isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.upgradeToCreator(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('become_a_creator'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection(UserSettingsController controller, bool kycApproved, bool isBusiness, bool isPending, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.blue.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blue.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsWidgets.buildSectionHeader('business_details'.tr),
          const SizedBox(height: 8),
          SettingsWidgets.buildTextField('business_name_req'.tr, controller.businessNameController, enabled: !isBusiness && !isPending && kycApproved),
          SettingsWidgets.buildTextField('registration_number_optional'.tr, controller.businessRegController, enabled: !isBusiness && !isPending && kycApproved),
          const SizedBox(height: 24),
          if (kycApproved && !isBusiness && !isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLoading.value ? null : () => controller.upgradeToBusiness(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: controller.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('upgrade_to_business_profile'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, dynamic icon) {
    final isDark = Get.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(description, style: AppTextStyles.bodySmall.copyWith(color: Colors.grey, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
