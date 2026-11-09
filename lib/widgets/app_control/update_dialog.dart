import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/app_control_model.dart';
import '../../pages/app_control/force_update_screen.dart';
import '../../utils/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final AppControlModel appControl;
  final String currentVersion;
  final bool isForced;
  final VoidCallback? onOptionalContinue;

  const UpdateDialog({
    super.key,
    required this.appControl,
    required this.currentVersion,
    required this.isForced,
    this.onOptionalContinue,
  });

  static Future<void> show({
    required AppControlModel appControl,
    required String currentVersion,
    required bool isForced,
    VoidCallback? onOptionalContinue,
  }) async {
    await Get.dialog(
      UpdateDialog(
        appControl: appControl,
        currentVersion: currentVersion,
        isForced: isForced,
        onOptionalContinue: onOptionalContinue,
      ),
      barrierDismissible: !isForced,
    );
  }

  Future<void> _launchStore() async {
    String url = '';
    if (Platform.isAndroid) {
      url = appControl.playStoreUrl.trim();
      if (url.isEmpty) {
        url = 'https://play.google.com/store/apps/details?id=com.mhquickdev.influx_app';
      }
    } else if (Platform.isIOS) {
      url = appControl.appStoreUrl.trim();
      if (url.isEmpty) {
        url = 'https://apps.apple.com';
      }
    } else {
      url = appControl.playStoreUrl.isNotEmpty
          ? appControl.playStoreUrl
          : appControl.appStoreUrl;
    }

    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _handleDismiss() {
    Get.back(); // close dialog
    if (isForced) {
      // User dismissed the popup when update is required -> load up the forced page!
      Get.offAll(() => ForceUpdateScreen(
            appControl: appControl,
            currentVersion: currentVersion,
          ));
    } else {
      onOptionalContinue?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = appControl.updateTitle.isNotEmpty
        ? appControl.updateTitle
        : (isForced ? 'Update Required' : 'New Version Available');
    final message = appControl.updateMessage.isNotEmpty
        ? appControl.updateMessage
        : 'Please update your app, to continue using the app.';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),

            // Version Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'v$currentVersion → v${appControl.latestVersion}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            if (appControl.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  appControl.releaseNotes,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _handleDismiss,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isForced ? 'Later' : 'Dismiss',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
