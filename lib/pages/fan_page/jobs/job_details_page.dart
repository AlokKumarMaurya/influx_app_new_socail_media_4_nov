import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/fan_page_job_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';
import 'fan_page_job_board_page.dart';
import 'job_apply_sheet.dart';
import 'my_job_applications_page.dart';

class JobDetailsPage extends StatefulWidget {
  final int? jobId;
  final FanPageJobModel? job;
  final String? pageSlug;
  final String? pageName;
  final bool? canManage;

  const JobDetailsPage({
    super.key,
    this.jobId,
    this.job,
    this.pageSlug,
    this.pageName,
    this.canManage,
  });

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final FanPageJobService _jobService = FanPageJobService();

  late FanPageJobModel _job;
  late String _pageSlug;
  late String _pageName;
  late bool _canManage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _job = widget.job!;
      _pageSlug = widget.pageSlug ?? widget.job!.pageSlug ?? '';
      _pageName = widget.pageName ?? widget.job!.pageName ?? 'Company';
      _canManage = widget.canManage ?? false;
      _isLoading = false;
      _refreshJob();
    } else if (widget.jobId != null) {
      _fetchInitialJob();
    }
  }

  Future<void> _fetchInitialJob() async {
    setState(() => _isLoading = true);
    try {
      final res = await _jobService.getJobById(widget.jobId!);
      if (mounted) {
        setState(() {
          _job = res['job'];
          _canManage = res['can_manage'] == true;
          _pageSlug = _job.pageSlug ?? '';
          _pageName = _job.pageName ?? 'Company';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshJob() async {
    try {
      final res = await _jobService.getJobById(_job.id);
      if (mounted) {
        setState(() {
          _job = res['job'];
          _canManage = widget.canManage ?? (res['can_manage'] == true);
        });
      }
    } catch (_) {}
  }

  void _openApplySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobApplySheet(
        pageSlug: _pageSlug,
        job: _job,
        onSuccess: _refreshJob,
      ),
    );
  }

  void _openJobBoard() {
    Get.to(() => FanPageJobBoardPage(
      pageSlug: _pageSlug,
      job: _job,
    ));
  }

  void _shareJob() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out this job opening: ${_job.title} at $_pageName!\nEmployment: ${_job.jobTypeLabel} • ${_job.workplaceTypeLabel}',
        subject: _job.title,
      ),
    );
  }

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
              Text('Job Post Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              const SizedBox(height: 4),
              Text('Control visibility and application acceptance for this opening', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _buildStatusOption(
                status: 'active',
                title: 'Active (Accepting Applications)',
                subtitle: 'Visible to all job seekers in feed and careers directory',
                color: Colors.green,
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                status: 'paused',
                title: 'Paused (Temporarily On Hold)',
                subtitle: 'Hidden from exploration; applications paused',
                color: Colors.orange,
                icon: HugeIcons.strokeRoundedPause,
              ),
              const SizedBox(height: 8),
              _buildStatusOption(
                status: 'closed',
                title: 'Closed (Archived)',
                subtitle: 'No longer accepting candidates',
                color: Colors.red,
                icon: HugeIcons.strokeRoundedCancelCircle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOption({
    required String status,
    required String title,
    required String subtitle,
    required Color color,
    required List<List<dynamic>> icon,
  }) {
    final isSelected = _job.status == status;
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (isSelected) return;
        try {
          final updated = await _jobService.updateJobStatus(_job.id, status, pageSlug: _pageSlug);
          if (mounted) {
            setState(() => _job = updated);
            Get.snackbar('Success', 'Status changed to ${status.capitalizeFirst}', snackPosition: SnackPosition.BOTTOM);
          }
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
            HugeIcon(icon: icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Job Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: AppColors.cardBg,
          foregroundColor: AppColors.textMain,
          elevation: 0.5,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _job.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textMain,
        elevation: 0.5,
        actions: [
          if (_canManage)
            IconButton(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedToggleOff, color: AppColors.primary, size: 22),
              onPressed: _showStatusPickerSheet,
              tooltip: 'Change Status',
            ),
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedShare01, color: AppColors.textMain, size: 20),
            onPressed: _shareJob,
            tooltip: 'Share Job',
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Image Banner
            if (_job.imageUrl != null && _job.imageUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.black12,
                child: Image.network(
                  _job.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),

            // Header Box
            Container(
              color: AppColors.cardBg,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedBriefcase02,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _job.title,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pageName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_job.location != null && _job.location!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedLocation01,
                                    color: AppColors.textSecondary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _job.location!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pill Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(
                        icon: HugeIcons.strokeRoundedBriefcase02,
                        label: _job.jobTypeLabel,
                        color: AppColors.primary,
                      ),
                      _badge(
                        icon: HugeIcons.strokeRoundedHome01,
                        label: _job.workplaceTypeLabel,
                        color: Colors.teal,
                      ),
                      _badge(
                        icon: HugeIcons.strokeRoundedWallet01,
                        label: _job.salaryRangeLabel,
                        color: Colors.green,
                      ),
                      if (_job.experienceLevel != null && _job.experienceLevel != 'any')
                        _badge(
                          icon: HugeIcons.strokeRoundedUserStar01,
                          label: _job.experienceLevel ?? '',
                          color: Colors.blueGrey,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Statistics Row
            Container(
              color: AppColors.cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Applicants', '${_job.applicationsCount}', HugeIcons.strokeRoundedUserMultiple),
                  _divider(),
                  _statItem('Views', '${_job.viewsCount}', HugeIcons.strokeRoundedView),
                  _divider(),
                  InkWell(
                    onTap: _canManage ? _showStatusPickerSheet : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Column(
                        children: [
                          HugeIcon(
                            icon: _job.status == 'active'
                                ? HugeIcons.strokeRoundedCheckmarkCircle01
                                : (_job.status == 'paused' ? HugeIcons.strokeRoundedPause : HugeIcons.strokeRoundedCancelCircle),
                            color: _job.status == 'active' ? Colors.green : (_job.status == 'paused' ? Colors.orange : Colors.red),
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(_job.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _job.status == 'active' ? Colors.green : (_job.status == 'paused' ? Colors.orange : Colors.red))),
                          const SizedBox(height: 2),
                          Text(_canManage ? 'Status (Tap)' : 'Status', style: TextStyle(fontSize: 11, color: _canManage ? AppColors.primary : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Description Section
            Container(
              width: double.infinity,
              color: AppColors.cardBg,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About the Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _job.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),

            // Requirements Section
            if (_job.requirements != null && _job.requirements!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                color: AppColors.cardBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirements & Qualifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _job.requirements!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Benefits Section
            if (_job.benefits != null && _job.benefits!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                color: AppColors.cardBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perks & Benefits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _job.benefits!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Deadline Section
            if (_job.deadline != null && _job.deadline!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                color: AppColors.cardBg,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Application Deadline: ${_job.deadline}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _badge({required List<List<dynamic>> icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, List<List<dynamic>> icon) {
    return Column(
      children: [
        HugeIcon(icon: icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textMain)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.2));
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_canManage) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openJobBoard,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedKanban, color: Colors.white, size: 18),
                  label: Text('Manage Applicants (${_job.applicationsCount})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else if (_job.hasApplied) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const MyJobApplicationsPage()),
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, color: Colors.green, size: 18),
                  label: const Text('Applied • Track Status', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else if (_job.status == 'active') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openApplySheet,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedSent, color: Colors.white, size: 18),
                  label: const Text('Apply for this Position', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Listing Closed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
