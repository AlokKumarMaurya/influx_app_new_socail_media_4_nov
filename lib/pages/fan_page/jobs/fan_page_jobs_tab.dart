import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/models/fan_page_job_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';
import 'fan_page_post_job_page.dart';
import 'job_post_card.dart';

class FanPageJobsTab extends StatefulWidget {
  final String pageSlug;
  final String pageName;
  final bool canManage;

  const FanPageJobsTab({
    super.key,
    required this.pageSlug,
    required this.pageName,
    required this.canManage,
  });

  @override
  State<FanPageJobsTab> createState() => _FanPageJobsTabState();
}

class _FanPageJobsTabState extends State<FanPageJobsTab> {
  final FanPageJobService _jobService = FanPageJobService();

  bool _isLoading = true;
  List<FanPageJobModel> _jobs = [];
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filterOptions = [
    {'key': 'all', 'label': 'All Roles'},
    {'key': 'full_time', 'label': 'Full-Time'},
    {'key': 'remote', 'label': 'Remote'},
    {'key': 'part_time', 'label': 'Part-Time'},
    {'key': 'contract', 'label': 'Contract'},
    {'key': 'internship', 'label': 'Internship'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    try {
      final res = await _jobService.getJobs(
        widget.pageSlug,
        type: _selectedFilter != 'all' ? _selectedFilter : null,
      );
      if (mounted) {
        setState(() {
          _jobs = res['jobs'] as List<FanPageJobModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToCreateJob({FanPageJobModel? existingJob}) async {
    final result = await Get.to(() => FanPagePostJobPage(
      pageSlug: widget.pageSlug,
      existingJob: existingJob,
    ));
    if (result == true) {
      _fetchJobs();
    }
  }

  void _confirmDeleteJob(int jobId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Job Opening?'),
        content: const Text('Are you sure you want to delete this job posting? All candidate applications will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await _jobService.deleteJob(widget.pageSlug, jobId);
                Get.snackbar('Deleted', 'Job opening deleted successfully.', snackPosition: SnackPosition.BOTTOM);
                _fetchJobs();
              } catch (e) {
                Get.snackbar('Error', 'Failed to delete job: $e', snackPosition: SnackPosition.BOTTOM);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        children: [
          // If Manager: Show "Post a Job" quick CTA banner
          if (widget.canManage)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hire Top Talent',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Post openings and track candidates directly.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _navigateToCreateJob(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Post Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // Filters list
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final opt = _filterOptions[i];
                final isSelected = _selectedFilter == opt['key'];
                return ChoiceChip(
                  label: Text(opt['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMain,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedFilter = opt['key']!);
                    _fetchJobs();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Jobs List or Empty State
          if (_jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, color: Colors.grey.shade400, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text('No Job Openings Right Now', style: AppTextStyles.h3),
                    const SizedBox(height: 6),
                    Text(
                      widget.canManage
                          ? 'Publish your first opening to attract candidates from our community.'
                          : 'This page currently has no active hiring positions. Check back later!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (widget.canManage) ...[
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToCreateJob(),
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedPlusSign, color: Colors.white, size: 18),
                        label: const Text('Post First Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ..._jobs.map((job) => JobPostCard(
                  job: job,
                  pageSlug: widget.pageSlug,
                  pageName: widget.pageName,
                  canManage: widget.canManage,
                  onRefresh: _fetchJobs,
                  onEdit: (j) => _navigateToCreateJob(existingJob: j),
                  onDelete: _confirmDeleteJob,
                )),
        ],
      ),
    );
  }
}
