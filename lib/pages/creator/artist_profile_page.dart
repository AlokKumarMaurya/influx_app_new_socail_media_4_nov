import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_settings_controller.dart';
import '../../utils/app_theme.dart';
import '../creator/creator_dashboard_page.dart';
import 'settings/kyc_verification_page.dart';

/// A single entry point for users who want to enable their artist/creator profile.
///
/// The backend currently exposes this as the existing professional-profile
/// upgrade flow. KYC approval is required before the upgrade can be submitted.
class ArtistProfilePage extends StatefulWidget {
  const ArtistProfilePage({super.key});

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage> {
  late final UserSettingsController _settingsController;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _settingsController = Get.find<UserSettingsController>();
    _authController = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsController.fetchProfessionalStatus();
    });
  }

  Future<void> _createArtistProfile() async {
    await _settingsController.upgradeToCreator();
    await _settingsController.fetchProfessionalStatus();
    await _settingsController.refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Create Artist Profile', style: AppTextStyles.h3),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        final user = _authController.user.value;
        final isCreator = _settingsController.profileType.value == 'creator';
        final isBusiness =
            _settingsController.profileType.value == 'business' ||
            _settingsController.businessStatus.value == 'approved';
        final isBusinessPending =
            _settingsController.businessStatus.value == 'pending';
        final isKycApproved = _settingsController.kycStatus.value == 'approved';

        return RefreshIndicator(
          onRefresh: _settingsController.fetchProfessionalStatus,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _buildHero(isCreator),
              const SizedBox(height: 20),
              _buildAccountCard(
                name: user?.name ?? '',
                username: user?.username ?? '',
                email: user?.email ?? '',
              ),
              const SizedBox(height: 20),
              _buildBenefits(),
              const SizedBox(height: 24),
              if (isCreator)
                _buildStatusCard(
                  icon: HugeIcons.strokeRoundedTick01,
                  title: 'Your artist profile is active',
                  message:
                      'Your account is already enabled as a creator. You can open your creator dashboard to manage your performance.',
                  color: Colors.green,
                )
              else if (isBusiness || isBusinessPending)
                _buildStatusCard(
                  icon: HugeIcons.strokeRoundedClock01,
                  title: isBusinessPending
                      ? 'Business profile under review'
                      : 'Business profile already active',
                  message:
                      'This account currently has a business profile. Artist profile creation is not available for this account state.',
                  color: Colors.orange,
                )
              else if (!isKycApproved)
                _buildStatusCard(
                  icon: HugeIcons.strokeRoundedShield01,
                  title: 'Identity verification required',
                  message:
                      'Complete identity verification before creating an artist profile. Once your KYC is approved, return here to continue.',
                  color: AppColors.primary,
                )
              else
                _buildStatusCard(
                  icon: HugeIcons.strokeRoundedUserMultiple02,
                  title: 'You are ready to become an artist',
                  message:
                      'Your identity is verified. Continue to enable creator tools and make your account discoverable as an artist.',
                  color: AppColors.primary,
                ),
              const SizedBox(height: 20),
              if (isCreator)
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Get.to(() => const CreatorDashboardPage()),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedChartHistogram,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text('Open Creator Dashboard'),
                    style: _primaryButtonStyle(),
                  ),
                )
              else if (!isBusiness && !isBusinessPending && !isKycApproved)
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Get.to(() => const KycVerificationPage()),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedShield01,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    label: Text(
                      'Complete identity verification',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              else if (!isBusiness && !isBusinessPending)
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _settingsController.isLoading.value
                        ? null
                        : _createArtistProfile,
                    style: _primaryButtonStyle(),
                    child: _settingsController.isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create Artist Profile'),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Your existing account, posts, followers and profile details stay connected. This step enables the creator profile type using the platform’s professional-profile process.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHero(bool isCreator) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedUserMultiple02,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isCreator ? 'Your Artist Profile' : 'Build your artist presence',
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCreator
                ? 'Your creator tools are ready.'
                : 'Turn your existing account into a creator profile and grow your audience.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard({
    required String name,
    required String username,
    required String email,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account that will become your artist profile',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              )),
          const SizedBox(height: 14),
          _accountLine(HugeIcons.strokeRoundedUser, name),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 10),
            _accountLine(Icons.alternate_email, '@$username'),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _accountLine(HugeIcons.strokeRoundedMail01, email),
          ],
        ],
      ),
    );
  }

  Widget _accountLine(dynamic icon, String value) {
    return Row(
      children: [
        icon is IconData
            ? Icon(icon, color: AppColors.primary, size: 19)
            : HugeIcon(icon: icon, color: AppColors.primary, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      (
        HugeIcons.strokeRoundedChartHistogram,
        'Creator insights',
        'Access creator performance and audience analytics.',
      ),
      (
        HugeIcons.strokeRoundedMegaphone02,
        'Campaign opportunities',
        'Explore creator campaigns and collaboration opportunities.',
      ),
      (
        HugeIcons.strokeRoundedUserGroup,
        'Creator discovery',
        'Make your account available in creator discovery.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you get as an artist',
            style: AppTextStyles.h3.copyWith(color: AppColors.textMain),
          ),
          const SizedBox(height: 16),
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HugeIcon(
                    icon: benefit.$1,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit.$2,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          benefit.$3,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required dynamic icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
