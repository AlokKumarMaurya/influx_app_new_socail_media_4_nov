import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../controllers/feed_controller.dart';
import '../../utils/app_theme.dart';

class ReportPostBottomSheet extends StatefulWidget {
  final int postId;
  const ReportPostBottomSheet({super.key, required this.postId});

  @override
  State<ReportPostBottomSheet> createState() => _ReportPostBottomSheetState();
}

class _ReportPostBottomSheetState extends State<ReportPostBottomSheet> {
  String _selectedReason = 'spam';
  final TextEditingController _detailsController = TextEditingController();
  final FeedController feedController = Get.find<FeedController>();

  List<Map<String, String>> get _reasons => [
    {'value': 'spam', 'title': 'spam_misleading'.tr, 'desc': 'spam_misleading_desc'.tr},
    {'value': 'harassment', 'title': 'harassment_bullying'.tr, 'desc': 'harassment_bullying_desc'.tr},
    {'value': 'inappropriate', 'title': 'inappropriate_explicit'.tr, 'desc': 'inappropriate_explicit_desc'.tr},
    {'value': 'violence', 'title': 'violence_dangerous'.tr, 'desc': 'violence_dangerous_desc'.tr},
    {'value': 'false_information', 'title': 'false_information'.tr, 'desc': 'false_information_desc'.tr},
    {'value': 'other', 'title': 'something_else'.tr, 'desc': 'something_else_desc'.tr},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: Colors.red, size: 24),
                const SizedBox(width: 10),
                Text('report_post'.tr, style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'report_post_anonymous_desc'.tr,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ..._reasons.map((r) => _buildReasonTile(r)),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'additional_details_optional'.tr,
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  feedController.reportPost(
                    widget.postId,
                    _selectedReason,
                    _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('submit_report'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonTile(Map<String, String> r) {
    final isSelected = _selectedReason == r['value'];
    return InkWell(
      onTap: () {
        setState(() {
          _selectedReason = r['value']!;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['title']!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r['desc']!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: r['value']!,
              groupValue: _selectedReason,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedReason = val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
