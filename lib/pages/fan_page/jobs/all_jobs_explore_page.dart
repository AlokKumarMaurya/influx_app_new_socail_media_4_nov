import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../utils/external_app_launcher.dart';
import '../../../data/models/fan_page_job_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';
import 'job_post_card.dart';
import 'my_job_applications_page.dart';

class AllJobsExplorePage extends StatefulWidget {
  const AllJobsExplorePage({super.key});

  @override
  State<AllJobsExplorePage> createState() => _AllJobsExplorePageState();
}

class _AllJobsExplorePageState extends State<AllJobsExplorePage> {
  final FanPageJobService _jobService = FanPageJobService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<FanPageJobModel> _jobs = [];
  String _selectedType = 'all';

  final List<Map<String, String>> _typeOptions = [
    {'key': 'all', 'label': 'All Roles'},
    {'key': 'full_time', 'label': 'Full-Time'},
    {'key': 'part_time', 'label': 'Part-Time'},
    {'key': 'contract', 'label': 'Contract'},
    {'key': 'internship', 'label': 'Internship'},
    {'key': 'remote', 'label': 'Remote Only'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);
    final isRemote = _selectedType == 'remote';
    try {
      final list = await _jobService.exploreAllJobs(
        type: (_selectedType != 'all' && !isRemote) ? _selectedType : null,
        workplace: isRemote ? 'remote' : null,
        query: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _jobs = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Jobs & Careers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textMain,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: () => Get.to(() => const MyJobApplicationsPage()),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDocumentValidation,
              color: AppColors.primary,
              size: 18,
            ),
            label: Text(
              'My Applications',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: AppColors.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Quick Portal Banner for My Applications
                InkWell(
                  onTap: () => Get.to(() => const MyJobApplicationsPage()),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedDocumentValidation,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Job Applications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Track the real-time status of your applied jobs',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _fetchJobs(),
                  decoration: InputDecoration(
                    hintText: 'Search title, company, or skills...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: AppColors.textSecondary, size: 20),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchJobs();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Type Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _typeOptions.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final opt = _typeOptions[i];
                      final isSelected = _selectedType == opt['key'];
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
                          setState(() => _selectedType = opt['key']!);
                          _fetchJobs();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Job list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchJobs,
                    child: _jobs.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, color: Colors.grey.shade400, size: 48),
                                      const SizedBox(height: 16),
                                      Text('No Job Openings Found', style: AppTextStyles.h3),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Try adjusting your search keywords or clearing filter criteria.',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _selectedType = 'all');
                                          _fetchJobs();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: const Text('Reset Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 32),
                            itemCount: _jobs.length,
                            itemBuilder: (ctx, index) {
                              final job = _jobs[index];
                              return JobPostCard(
                                job: job,
                                pageSlug: job.pageSlug ?? '',
                                pageName: job.pageName ?? 'Company',
                                canManage: false,
                                onRefresh: _fetchJobs,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ExternalAppLauncher.launch(
          context,
          url: ExternalAppLinks.hamiMitr,
          appName: 'Hami Mitr',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Hami Mitr'),
      ),
    );
  }
}
