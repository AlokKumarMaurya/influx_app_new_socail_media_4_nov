import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/models/fan_page_job_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';
import 'fan_page_job_board_page.dart';
import 'job_apply_sheet.dart';
import 'job_details_page.dart';
import 'my_job_applications_page.dart';

class JobPostCard extends StatefulWidget {
  final FanPageJobModel job;
  final String pageSlug;
  final String pageName;
  final bool canManage;
  final VoidCallback? onRefresh;
  final Function(FanPageJobModel)? onEdit;
  final Function(int)? onDelete;

  const JobPostCard({
    super.key,
    required this.job,
    required this.pageSlug,
    required this.pageName,
    required this.canManage,
    this.onRefresh,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<JobPostCard> createState() => _JobPostCardState();
}

class _JobPostCardState extends State<JobPostCard> {
  bool _isExpanded = false;

  void _openApplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobApplySheet(
        pageSlug: widget.pageSlug,
        job: widget.job,
        onSuccess: widget.onRefresh,
      ),
    );
  }

  void _openJobBoard() {
    Get.to(() => FanPageJobBoardPage(
      pageSlug: widget.pageSlug,
      job: widget.job,
    ))?.then((_) => widget.onRefresh?.call());
  }

  final FanPageJobService _jobService = FanPageJobService();

  void _showStatusPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: AppColors.cardBg,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Job Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              const SizedBox(height: 4),
              Text('Update whether this listing is active, paused, or closed', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _buildStatusItem('active', 'Active (Accepting Applications)', Colors.green, HugeIcons.strokeRoundedCheckmarkCircle01),
              const SizedBox(height: 8),
              _buildStatusItem('paused', 'Paused (On Hold)', Colors.orange, HugeIcons.strokeRoundedPause),
              const SizedBox(height: 8),
              _buildStatusItem('closed', 'Closed (Archived)', Colors.red, HugeIcons.strokeRoundedCancelCircle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String status, String title, Color color, List<List<dynamic>> icon) {
    final isSelected = widget.job.status == status;
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (isSelected) return;
        try {
          await _jobService.updateJobStatus(widget.job.id, status, pageSlug: widget.pageSlug);
          widget.onRefresh?.call();
          Get.snackbar('Success', 'Status changed to ${status.capitalizeFirst}', snackPosition: SnackPosition.BOTTOM);
        } catch (e) {
          Get.snackbar('Error', 'Failed to update job status', snackPosition: SnackPosition.BOTTOM);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title & Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Get.to(() => JobDetailsPage(
                        job: job,
                        pageSlug: widget.pageSlug,
                        pageName: widget.pageName,
                        canManage: widget.canManage,
                      ));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pageName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.canManage)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                    onSelected: (val) {
                      if (val == 'view') {
                        Get.to(() => JobDetailsPage(
                          job: job,
                          pageSlug: widget.pageSlug,
                          pageName: widget.pageName,
                          canManage: widget.canManage,
                        ));
                      } else if (val == 'board') {
                        _openJobBoard();
                      } else if (val == 'status') {
                        _showStatusPickerSheet();
                      } else if (val == 'edit') {
                        widget.onEdit?.call(job);
                      } else if (val == 'delete') {
                        widget.onDelete?.call(job.id);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedView, color: AppColors.textMain, size: 18),
                            const SizedBox(width: 8),
                            const Text('View Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedToggleOff, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            const Text('Change Status'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'board',
                        child: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedTask01, color: AppColors.textMain, size: 18),
                            const SizedBox(width: 8),
                            const Text('Candidate Board'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.textMain, size: 18),
                            const SizedBox(width: 8),
                            const Text('Edit Job'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            const Text('Delete Job', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (job.imageUrl != null && job.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Get.to(() => JobDetailsPage(
                    job: job,
                    pageSlug: widget.pageSlug,
                    pageName: widget.pageName,
                    canManage: widget.canManage,
                  ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    job.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Badges: Workplace, Job Type, Salary
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildBadge(
                  icon: HugeIcons.strokeRoundedBriefcase02,
                  label: job.jobTypeLabel,
                  color: Colors.indigo,
                ),
                _buildBadge(
                  icon: HugeIcons.strokeRoundedHome01,
                  label: job.workplaceTypeLabel,
                  color: Colors.teal,
                ),
                if (job.salaryRangeLabel.isNotEmpty)
                  _buildBadge(
                    icon: HugeIcons.strokeRoundedWallet01,
                    label: job.salaryRangeLabel,
                    color: const Color(0xFF059669),
                  ),
                if (job.location != null && job.location!.isNotEmpty)
                  _buildBadge(
                    icon: HugeIcons.strokeRoundedLocation01,
                    label: job.location!,
                    color: Colors.blueGrey,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Description preview / expand
            Text(
              job.description,
              maxLines: _isExpanded ? null : 2,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (job.requirements != null && job.requirements!.isNotEmpty && _isExpanded) ...[
              const SizedBox(height: 8),
              const Text(
                'Requirements:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                job.requirements!,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],

            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(
                _isExpanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Footer Row: Metadata & Action CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedClock01, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      job.createdAtHuman,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${job.applicationsCount} applicants',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),

                // Button depending on manager or candidate
                if (widget.canManage)
                  ElevatedButton.icon(
                    onPressed: _openJobBoard,
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedKanban, color: Colors.white, size: 15),
                    label: Text(
                      'Pipeline (${job.applicationsCount})',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else if (job.hasApplied)
                  InkWell(
                    onTap: () => Get.to(() => const MyJobApplicationsPage()),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Applied',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _openApplySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required dynamic icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
