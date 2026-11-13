import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/fan_page_job_application_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';
import 'job_details_page.dart';

class MyJobApplicationsPage extends StatefulWidget {
  const MyJobApplicationsPage({super.key});

  @override
  State<MyJobApplicationsPage> createState() => _MyJobApplicationsPageState();
}

class _MyJobApplicationsPageState extends State<MyJobApplicationsPage> with SingleTickerProviderStateMixin {
  final FanPageJobService _jobService = FanPageJobService();

  late TabController _tabController;
  final List<String> _stages = ['all', 'new', 'shortlisted', 'interview', 'offer', 'hired', 'rejected'];

  bool _isLoading = true;
  List<FanPageJobApplicationModel> _allApplications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final list = await _jobService.getMyApplications();
      if (mounted) {
        setState(() {
          _allApplications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FanPageJobApplicationModel> _filteredApplications(String stage) {
    if (stage == 'all') return _allApplications;
    return _allApplications.where((app) => app.stage == stage).toList();
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'shortlisted':
        return Colors.cyan;
      case 'interview':
        return Colors.orange;
      case 'offer':
        return Colors.purple;
      case 'hired':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Applications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _stages.map((stage) {
            final count = _filteredApplications(stage).length;
            final label = stage == 'all'
                ? 'All'
                : stage == 'new'
                    ? 'In Review'
                    : stage.capitalizeFirst ?? stage;
            return Tab(text: '$label ($count)');
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadApplications,
              child: TabBarView(
                controller: _tabController,
                children: _stages.map((stage) {
                  final apps = _filteredApplications(stage);
                  if (apps.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedBriefcase02,
                                size: 54,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No ${stage == 'all' ? '' : stage} applications found',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your submitted job applications will appear here.',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: apps.length,
                    separatorBuilder: (context, itemIndex) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      final stageColor = _getStageColor(app.stage);

                      return InkWell(
                        onTap: () {
                          if (app.job != null) {
                            Get.to(() => JobDetailsPage(job: app.job!));
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Company / Job Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: HugeIcon(
                                        icon: HugeIcons.strokeRoundedBriefcase02,
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.job?.title ?? 'Job Opening',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textMain,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          app.job?.pageName ?? 'Company',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Stage Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: stageColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      app.stageLabel,
                                      style: TextStyle(
                                        color: stageColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Applied ${app.createdAtHuman}',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                  if (app.resumeUrl != null && app.resumeUrl!.isNotEmpty)
                                    InkWell(
                                      onTap: () async {
                                        final uri = Uri.parse(app.resumeUrl!);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedAttachment01,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Resume',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
    );
  }
}
