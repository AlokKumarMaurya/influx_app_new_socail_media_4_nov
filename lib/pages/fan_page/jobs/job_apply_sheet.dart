import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../data/models/fan_page_job_model.dart';
import '../../../data/services/fan_page_job_service.dart';
import '../../../utils/app_theme.dart';

class JobApplySheet extends StatefulWidget {
  final String pageSlug;
  final FanPageJobModel job;
  final VoidCallback? onSuccess;

  const JobApplySheet({
    super.key,
    required this.pageSlug,
    required this.job,
    this.onSuccess,
  });

  @override
  State<JobApplySheet> createState() => _JobApplySheetState();
}

class _JobApplySheetState extends State<JobApplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _expController = TextEditingController();
  final _salaryController = TextEditingController();
  final _coverLetterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _portfolioController = TextEditingController();

  String _noticePeriod = 'Immediate';
  File? _resumeFile;
  String? _resumeFileName;
  bool _isSubmitting = false;

  final FanPageJobService _jobService = FanPageJobService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _expController.dispose();
    _salaryController.dispose();
    _coverLetterController.dispose();
    _linkedinController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result.single.path != null) {
        setState(() {
          _resumeFile = File(result.single.path!);
          _resumeFileName = result.single.name;
        });
      }
    } catch (e) {
      Get.snackbar(
        'File Error',
        'Unable to select file: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_resumeFile == null) {
      Get.snackbar(
        'Resume Required',
        'Please attach your resume in PDF or DOC format.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final expNum = num.tryParse(_expController.text.trim());

      await _jobService.applyToJob(
        widget.pageSlug,
        widget.job.id,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        coverLetter: _coverLetterController.text.trim(),
        experienceYears: expNum,
        expectedSalary: _salaryController.text.trim(),
        noticePeriod: _noticePeriod,
        linkedinUrl: _linkedinController.text.trim(),
        portfolioUrl: _portfolioController.text.trim(),
        resumeFile: _resumeFile,
      );

      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'Application Submitted',
          'Your application was sent successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          colorText: Colors.green,
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        Get.snackbar(
          'Application Failed',
          e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apply for Opening', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text(
                          widget.job.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Full Name
              Text('Full Name *', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'John Doe',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: 14),

              // Email & Phone
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Address *',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'john@mail.com',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedMail01,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          validator: (val) => val == null || !val.contains('@')
                              ? 'Enter a valid email'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone Number', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '+123456789',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedCall02,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Experience & Notice Period
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Experience (Years)',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g. 4',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
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
                        Text('Notice Period', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _noticePeriod,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Immediate',
                              child: Text('Immediate'),
                            ),
                            DropdownMenuItem(
                              value: '1-2 Weeks',
                              child: Text('1-2 Weeks'),
                            ),
                            DropdownMenuItem(
                              value: '1 Month',
                              child: Text('1 Month'),
                            ),
                            DropdownMenuItem(
                              value: '2 Months+',
                              child: Text('2 Months+'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _noticePeriod = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Expected Salary
              Text('Expected Salary', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _salaryController,
                decoration: InputDecoration(
                  hintText: 'e.g. \$80,000 / year or Negotiable',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedWallet01,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Links: LinkedIn & Portfolio
              Text(
                'Professional Links (Optional)',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _linkedinController,
                decoration: InputDecoration(
                  hintText: 'LinkedIn Profile URL',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedLinkedin02,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _portfolioController,
                decoration: InputDecoration(
                  hintText: 'Portfolio / GitHub Website URL',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedGlobe02,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Resume Upload Picker
              Text(
                'Attach Resume (PDF, DOC) *',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickResume,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(
                      color: _resumeFile != null
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: HugeIcon(
                          icon: _resumeFile != null
                              ? HugeIcons.strokeRoundedDocumentAttachment
                              : HugeIcons.strokeRoundedDocumentCode,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _resumeFileName ?? 'Tap to select Resume file',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _resumeFile != null
                                    ? AppColors.textMain
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _resumeFile != null
                                  ? 'File ready to upload'
                                  : 'Max size 10MB (PDF, DOC, DOCX)',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (_resumeFile != null)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Cover Note
              Text('Cover Note / Pitch', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _coverLetterController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Briefly introduce yourself and why you are a great match for this role...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
