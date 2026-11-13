import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../utils/app_theme.dart';
import '../common/country_picker_sheet.dart';
import '../../controllers/feature_controller.dart';
import '../../controllers/feed_controller.dart';

class FeedFilterBar extends StatelessWidget {
  const FeedFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final featureCtrl = FeatureController.to;
    
    return Obx(() {
      final isCountryFilterEnabled = featureCtrl.isFeatureEnabled('country_filter');
      
      // Ensure theme reactivity
      AppColors.isDark;

      if (!isCountryFilterEnabled) {
        return const SizedBox.shrink();
      }

      final countryCode = CountryPickerSheet.getSelectedCountryCode();
      final countryName = CountryPickerSheet.getSelectedCountryName();
      final countryFlag = CountryPickerSheet.getSelectedCountryFlag();

      // Listen to feed loading state for seamless refresh indicator
      if (Get.isRegistered<FeedController>()) {
        Get.find<FeedController>().isLoading.value;
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Sleek Filter Icon Only
              HugeIcon(
                icon: HugeIcons.strokeRoundedSlidersVertical,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),

              // Divider Line
              Container(
                height: 18,
                width: 1,
                color: AppColors.isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 10),

              // Country Filter Chip (Sleek Pill Button)
              InkWell(
                onTap: () => CountryPickerSheet.show(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: countryCode != 'all'
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (AppColors.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: countryCode != 'all'
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(countryFlag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        countryName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: countryCode != 'all' ? FontWeight.w700 : FontWeight.w600,
                          color: countryCode != 'all' ? AppColors.primary : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(width: 4),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        color: countryCode != 'all' ? AppColors.primary : AppColors.textSecondary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

              // Placeholder slot for future filters (e.g. Topic, Category, Sort)
              /* 
              const SizedBox(width: 8),
              _buildFutureFilterChip(context, label: 'Latest', icon: HugeIcons.strokeRoundedClock01),
              */
            ],
          ),
        ),
      );
    });
  }
}
