import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/extra_controller.dart';
import '../../data/models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/string_utils.dart';
import '../../widgets/feed/post_card.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final ExtraController controller = Get.put(ExtraController());

  @override
  void initState() {
    super.initState();
    controller.fetchMyReports(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('my_reports'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.myReportsLoading.value && controller.myReports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.myReports.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchMyReports(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                controller.fetchMyReports();
              }
              return true;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.myReports.length + (controller.hasMoreMyReports.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.myReports.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final report = controller.myReports[index];
                return _buildReportItem(report);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReportItem(ReportModel report) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (report.status.toLowerCase()) {
      case 'reviewed':
      case 'action_taken':
      case 'resolved':
        statusColor = AppColors.success;
        statusText = 'action_taken'.tr;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'dismissed':
      case 'rejected':
        statusColor = Colors.grey;
        statusText = 'dismissed'.tr;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'pending_review'.tr;
        statusIcon = Icons.access_time_filled_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const HugeIcon(icon: HugeIcons.strokeRoundedFlag01, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          report.reason.replaceAll('_', ' ').capitalizeFirst ?? report.reason,
                          style: AppTextStyles.h4,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (report.details != null && report.details!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    report.details!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${'reported_on'.tr}: ${report.createdAt}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (report.post != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PostCard(post: report.post!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedFlag01,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text('no_submitted_reports'.tr, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'reports_submitted_moderation_tracked_here'.tr,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
