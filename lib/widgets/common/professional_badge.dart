import 'package:material_ui/material_ui.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:influx_app/controllers/feature_controller.dart';

class ProfessionalBadge extends StatelessWidget {
  final String? profileType;
  final String? badgeIconUrl;
  final String? customBadgeIconUrl;
  final bool isBadgePrivate;
  final int equippedBadgeCount;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;

  const ProfessionalBadge({
    super.key,
    this.profileType,
    this.badgeIconUrl,
    this.customBadgeIconUrl,
    this.isBadgePrivate = false,
    this.equippedBadgeCount = 1,
    this.size = 18,
    this.showLabel = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Check if custom equipped badge URL is present
    final String? customUrl =
        customBadgeIconUrl ??
        (badgeIconUrl != null &&
                !badgeIconUrl!.contains('assets/img') &&
                !badgeIconUrl!.contains('creator_badge') &&
                !badgeIconUrl!.contains('business_badge')
            ? badgeIconUrl
            : null);

    final bool hasTypeBadge =
        profileType == 'creator' || profileType == 'business';
    final bool isBadgeFeatureEnabled = Get.isRegistered<FeatureController>()
        ? FeatureController.to.isFeatureEnabled('badge_system')
        : true;
    final bool hasCustomBadge =
        isBadgeFeatureEnabled && customUrl != null && customUrl.isNotEmpty;

    if (!hasTypeBadge && !hasCustomBadge) {
      return const SizedBox.shrink();
    }

    final double effectiveSize = isBadgePrivate ? (size * 1.4).clamp(22.0, 32.0) : (size * 1.25);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasTypeBadge) _buildOriginalProfileTypeBadge(size),
        if (hasTypeBadge && hasCustomBadge) const SizedBox(width: 4),
        if (hasCustomBadge)
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isBadgePrivate ? Colors.amber : Colors.blue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Image.network(
                    customUrl,
                    width: effectiveSize,
                    height: effectiveSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                if (equippedBadgeCount > 1) ...[
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${equippedBadgeCount}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOriginalProfileTypeBadge([double? customSize]) {
    final double badgeSize = customSize ?? size;
    final isCreator = profileType == 'creator';
    final color = isCreator ? Colors.blue : Colors.blue.shade700;

    final icon = Image.asset(
      isCreator
          ? 'assets/images/img/creator_badge.png'
          : 'assets/images/img/business_badge.png',
      width: badgeSize,
      height: badgeSize,
    );

    if (!showLabel) {
      return icon;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            isCreator ? 'creator' : 'business',
            style: TextStyle(
              color: color,
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
