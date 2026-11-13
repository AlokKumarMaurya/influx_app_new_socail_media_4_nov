import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/fan_page_job_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';

class FanPagePostJobPage extends StatefulWidget {
  final String pageSlug;
  final FanPageJobModel? existingJob;

  const FanPagePostJobPage({
    super.key,
    required this.pageSlug,
    this.existingJob,
  });

  @override
  State<FanPagePostJobPage> createState() => _FanPagePostJobPageState();
}

class _FanPagePostJobPageState extends State<FanPagePostJobPage> {
  final _formKey = GlobalKey<FormState>();
  final FanPageJobService _jobService = FanPageJobService();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _salaryMinController;
  late TextEditingController _salaryMaxController;
  late TextEditingController _descController;
  late TextEditingController _reqController;
  late TextEditingController _benefitsController;

  String _jobType = 'full_time';
  String _workplaceType = 'on_site';
  String _experienceLevel = 'mid';
  String _salaryPeriod = 'monthly';
  String _currency = 'USD';
  bool _isNegotiable = false;
  bool _isSaving = false;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  @override
  void initState() {
    super.initState();
    final j = widget.existingJob;
    _titleController = TextEditingController(text: j?.title ?? '');
    _locationController = TextEditingController(text: j?.location ?? '');
    _salaryMinController = TextEditingController(text: j?.salaryMin?.toString() ?? '');
    _salaryMaxController = TextEditingController(text: j?.salaryMax?.toString() ?? '');
    _descController = TextEditingController(text: j?.description ?? '');
    _reqController = TextEditingController(text: j?.requirements ?? '');
    _benefitsController = TextEditingController(text: j?.benefits ?? '');

    if (j != null) {
      _jobType = j.jobType;
      _workplaceType = j.workplaceType;
      _experienceLevel = j.experienceLevel ?? 'mid';
      _salaryPeriod = j.salaryPeriod ?? 'monthly';
      _currency = j.salaryCurrency ?? 'USD';
      _isNegotiable = j.isSalaryNegotiable;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _descController.dispose();
    _reqController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'title': _titleController.text.trim(),
      'job_type': _jobType,
      'workplace_type': _workplaceType,
      'location': _locationController.text.trim(),
      'experience_level': _experienceLevel,
      'salary_min': num.tryParse(_salaryMinController.text.trim()),
      'salary_max': num.tryParse(_salaryMaxController.text.trim()),
      'salary_currency': _currency,
      'salary_period': _salaryPeriod,
      'is_salary_negotiable': _isNegotiable,
      'description': _descController.text.trim(),
      'requirements': _reqController.text.trim(),
      'benefits': _benefitsController.text.trim(),
      'status': 'active',
    };

    try {
      if (widget.existingJob != null) {
        await _jobService.updateJob(widget.pageSlug, widget.existingJob!.id, data, imageFile: _imageFile);
        Get.snackbar('Success', 'Job listing updated successfully!', snackPosition: SnackPosition.BOTTOM);
      } else {
        await _jobService.createJob(widget.pageSlug, data, imageFile: _imageFile);
        Get.snackbar('Success', 'Job opening published!', snackPosition: SnackPosition.BOTTOM);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''), snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingJob != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Job Opening' : 'Post New Job'),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textMain,
        elevation: 0.5,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Job Title
            Text('Job Title *', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Senior Frontend Developer',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedBriefcase02, color: AppColors.textSecondary, size: 20),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Enter job title' : null,
            ),
            const SizedBox(height: 16),

            // Job Type & Workplace Type
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Job Type', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _jobType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'full_time', child: Text('Full-Time')),
                          DropdownMenuItem(value: 'part_time', child: Text('Part-Time')),
                          DropdownMenuItem(value: 'contract', child: Text('Contract')),
                          DropdownMenuItem(value: 'internship', child: Text('Internship')),
                          DropdownMenuItem(value: 'remote', child: Text('Remote Only')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _jobType = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Workplace', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _workplaceType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'on_site', child: Text('On-site')),
                          DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                          DropdownMenuItem(value: 'remote', child: Text('Remote')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _workplaceType = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            Text('Office Location', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. San Francisco, CA or Remote',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: AppColors.textSecondary, size: 20),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Experience Level & Salary Period
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Experience Level', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _experienceLevel,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'entry', child: Text('Entry Level')),
                          DropdownMenuItem(value: 'mid', child: Text('Mid Level')),
                          DropdownMenuItem(value: 'senior', child: Text('Senior Level')),
                          DropdownMenuItem(value: 'lead', child: Text('Lead / Manager')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _experienceLevel = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pay Frequency', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _salaryPeriod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                          DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _salaryPeriod = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Salary Range
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Min Salary', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _salaryMinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 3000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max Salary', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _salaryMaxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 5000',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Salary is negotiable', style: TextStyle(fontSize: 14)),
              value: _isNegotiable,
              onChanged: (val) => setState(() => _isNegotiable = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),

            // Description
            Text('Job Description *', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the role, responsibilities, team culture, etc...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Provide job description' : null,
            ),
            const SizedBox(height: 16),

            // Requirements
            Text('Key Requirements & Skills', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reqController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. 3+ years Flutter experience, Git, REST APIs...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Benefits
            Text('Perks & Benefits', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _benefitsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Health insurance, flexible hours, equipment budget...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Job Banner / Promotional Image
            Text('Job Banner / Image (Optional)', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: _imageFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, width: double.infinity, height: 140, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                onPressed: () => setState(() => _imageFile = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    : (widget.existingJob?.imageUrl != null && widget.existingJob!.imageUrl!.isNotEmpty)
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(widget.existingJob!.imageUrl!, width: double.infinity, height: 140, fit: BoxFit.cover),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Change Image', style: TextStyle(color: Colors.white, fontSize: 11)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: AppColors.textSecondary, size: 32),
                              const SizedBox(height: 6),
                              Text('Select banner or poster image', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        isEdit ? 'Update Job Posting' : 'Publish Job Opening',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
