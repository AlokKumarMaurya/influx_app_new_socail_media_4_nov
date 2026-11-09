import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/fan_page_job_application_model.dart';
import '../../../data/models/fan_page_job_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';

class FanPageJobBoardPage extends StatefulWidget {
  final String pageSlug;
  final FanPageJobModel job;

  const FanPageJobBoardPage({
    super.key,
    required this.pageSlug,
    required this.job,
  });

  @override
  State<FanPageJobBoardPage> createState() => _FanPageJobBoardPageState();
}

class _FanPageJobBoardPageState extends State<FanPageJobBoardPage> with SingleTickerProviderStateMixin {
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
      final list = await _jobService.getJobApplications(widget.pageSlug, widget.job.id);
      if (mounted) {
        setState(() {
          _allApplications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar('Error', 'Failed to load candidates: $e', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  List<FanPageJobApplicationModel> _getFiltered(String stage) {
    if (stage == 'all') return _allApplications;
    return _allApplications.where((a) => a.stage.toLowerCase() == stage.toLowerCase()).toList();
  }

  int _countFor(String stage) {
    if (stage == 'all') return _allApplications.length;
    return _allApplications.where((a) => a.stage.toLowerCase() == stage.toLowerCase()).length;
  }

  void _showCandidateDetails(FanPageJobApplicationModel app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CandidateDetailSheet(
        pageSlug: widget.pageSlug,
        jobId: widget.job.id,
        application: app,
        onUpdated: _loadApplications,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Candidate Pipeline', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(widget.job.title, style: TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
        ),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textMain,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedReload, color: AppColors.textMain, size: 20),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _stages.map((stage) {
            final count = _countFor(stage);
            final label = stage == 'all'
                ? 'All'
                : stage == 'offer'
                    ? 'Offered'
                    : stage[0].toUpperCase() + stage.substring(1);
            return Tab(
              child: Row(
                children: [
                  Text(label),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: count > 0 ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: count > 0 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _stages.map((stage) {
                final list = _getFiltered(stage);
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, color: Colors.grey.shade400, size: 48),
                        const SizedBox(height: 12),
                        Text('No candidates in this stage', style: AppTextStyles.h4),
                        const SizedBox(height: 4),
                        Text('Applicants will appear here as they apply.', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final app = list[i];
                    return _buildCandidateCard(app);
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildCandidateCard(FanPageJobApplicationModel app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showCandidateDetails(app),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: app.applicant?.avatarUrl != null
                        ? NetworkImage(app.applicant!.avatarUrl!)
                        : null,
                    child: app.applicant?.avatarUrl == null
                        ? Text(
                            app.fullName.isNotEmpty ? app.fullName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(app.email, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  _buildStageBadge(app.stage),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (app.experienceYears != null) ...[
                    HugeIcon(icon: HugeIcons.strokeRoundedAward01, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text('${app.experienceYears} yrs exp', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                  ],
                  if (app.noticePeriod != null) ...[
                    HugeIcon(icon: HugeIcons.strokeRoundedClock01, color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: 4),
                    Text(app.noticePeriod!, style: AppTextStyles.bodySmall),
                  ],
                  const Spacer(),
                  if (app.rating != null && app.rating! > 0)
                    Row(
                      children: List.generate(
                        app.rating!,
                        (_) => const Icon(Icons.star, size: 14, color: Colors.amber),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageBadge(String stage) {
    Color bg = Colors.grey.withValues(alpha: 0.15);
    Color text = Colors.grey.shade800;

    switch (stage.toLowerCase()) {
      case 'new':
        bg = Colors.blue.withValues(alpha: 0.12);
        text = Colors.blue.shade800;
        break;
      case 'shortlisted':
        bg = Colors.cyan.withValues(alpha: 0.12);
        text = Colors.cyan.shade900;
        break;
      case 'interview':
        bg = Colors.orange.withValues(alpha: 0.12);
        text = Colors.orange.shade900;
        break;
      case 'offer':
        bg = Colors.purple.withValues(alpha: 0.12);
        text = Colors.purple.shade800;
        break;
      case 'hired':
        bg = Colors.green.withValues(alpha: 0.12);
        text = Colors.green.shade800;
        break;
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.12);
        text = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        stage.toUpperCase(),
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CandidateDetailSheet extends StatefulWidget {
  final String pageSlug;
  final int jobId;
  final FanPageJobApplicationModel application;
  final VoidCallback onUpdated;

  const _CandidateDetailSheet({
    required this.pageSlug,
    required this.jobId,
    required this.application,
    required this.onUpdated,
  });

  @override
  State<_CandidateDetailSheet> createState() => _CandidateDetailSheetState();
}

class _CandidateDetailSheetState extends State<_CandidateDetailSheet> {
  final FanPageJobService _jobService = FanPageJobService();

  late String _currentStage;
  late int _rating;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentStage = widget.application.stage.toLowerCase();
    _rating = widget.application.rating ?? 0;
    _notesController = TextEditingController(text: widget.application.internalNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await _jobService.updateApplicationStage(
        widget.pageSlug,
        widget.jobId,
        widget.application.id,
        stage: _currentStage,
        notes: _notesController.text.trim(),
        rating: _rating > 0 ? _rating : null,
      );

      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'Updated',
          'Candidate status updated to ${_currentStage.toUpperCase()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        Get.snackbar('Error', '$e', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  void _openResume(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Unable to open resume link', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Candidate Header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: app.applicant?.avatarUrl != null
                      ? NetworkImage(app.applicant!.avatarUrl!)
                      : null,
                  child: app.applicant?.avatarUrl == null
                      ? Text(app.fullName.isNotEmpty ? app.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.fullName, style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text('Applied ${app.createdAtHuman}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Contact info
            _buildContactRow(HugeIcons.strokeRoundedMail01, app.email),
            if (app.phone != null && app.phone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContactRow(HugeIcons.strokeRoundedCall02, app.phone!),
            ],
            if (app.expectedSalary != null && app.expectedSalary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContactRow(HugeIcons.strokeRoundedWallet01, 'Expected: ${app.expectedSalary}'),
            ],
            const SizedBox(height: 14),

            // External Links (LinkedIn, Portfolio)
            if (app.linkedinUrl != null || app.portfolioUrl != null)
              Wrap(
                spacing: 8,
                children: [
                  if (app.linkedinUrl != null)
                    OutlinedButton.icon(
                      onPressed: () => _openResume(app.linkedinUrl!),
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedLinkedin02, color: AppColors.primary, size: 16),
                      label: const Text('LinkedIn'),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                  if (app.portfolioUrl != null)
                    OutlinedButton.icon(
                      onPressed: () => _openResume(app.portfolioUrl!),
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedGlobe02, color: AppColors.primary, size: 16),
                      label: const Text('Portfolio'),
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    ),
                ],
              ),

            // Resume Button
            if (app.resumeUrl != null && app.resumeUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openResume(app.resumeUrl!),
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedDocumentAttachment, color: Colors.white, size: 18),
                  label: const Text('Download / View Resume', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            // Cover Letter
            if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Cover Letter / Pitch', style: AppTextStyles.h4),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  app.coverLetter!,
                  style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMain),
                ),
              ),
            ],

            const Divider(height: 32),

            // Stage Pipeline Selector
            Text('Update Candidate Stage', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currentStage,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'new', child: Text('New')),
                DropdownMenuItem(value: 'shortlisted', child: Text('Shortlisted')),
                DropdownMenuItem(value: 'interview', child: Text('Interview')),
                DropdownMenuItem(value: 'offer', child: Text('Offer Extended')),
                DropdownMenuItem(value: 'hired', child: Text('Hired')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _currentStage = val);
              },
            ),
            const SizedBox(height: 16),

            // Candidate Rating (1 - 5 stars)
            Text('Rating', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  icon: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 28,
                  ),
                  onPressed: () => setState(() => _rating = starIndex),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Internal Hiring Notes
            Text('Private Hiring Notes', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add team feedback or interview notes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 22),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Candidate Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(dynamic icon, String text) {
    return Row(
      children: [
        HugeIcon(icon: icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.textMain))),
      ],
    );
  }
}
