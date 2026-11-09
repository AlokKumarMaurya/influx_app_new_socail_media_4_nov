import 'fan_page_job_model.dart';

class JobApplicantProfile {
  final int id;
  final String name;
  final String? avatarUrl;

  JobApplicantProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory JobApplicantProfile.fromJson(Map<String, dynamic> json) {
    return JobApplicantProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class FanPageJobApplicationModel {
  final int id;
  final int fanPageJobId;
  final int fanPageId;
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? resumeUrl;
  final String? resumeFilename;
  final String? coverLetter;
  final num? experienceYears;
  final String? expectedSalary;
  final String? noticePeriod;
  final String? portfolioUrl;
  final String? linkedinUrl;
  final String? githubUrl;
  String stage;
  final String stageLabel;
  final String stageBadgeClass;
  int? rating;
  String? internalNotes;
  final JobApplicantProfile? applicant;
  final FanPageJobModel? job;
  final String createdAtHuman;
  final String createdAt;

  FanPageJobApplicationModel({
    required this.id,
    required this.fanPageJobId,
    required this.fanPageId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.resumeUrl,
    this.resumeFilename,
    this.coverLetter,
    this.experienceYears,
    this.expectedSalary,
    this.noticePeriod,
    this.portfolioUrl,
    this.linkedinUrl,
    this.githubUrl,
    required this.stage,
    required this.stageLabel,
    required this.stageBadgeClass,
    this.rating,
    this.internalNotes,
    this.applicant,
    this.job,
    required this.createdAtHuman,
    required this.createdAt,
  });

  factory FanPageJobApplicationModel.fromJson(Map<String, dynamic> json) {
    return FanPageJobApplicationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fanPageJobId: json['fan_page_job_id'] is int ? json['fan_page_job_id'] : int.tryParse(json['fan_page_job_id'].toString()) ?? 0,
      fanPageId: json['fan_page_id'] is int ? json['fan_page_id'] : int.tryParse(json['fan_page_id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      resumeUrl: json['resume_url'],
      resumeFilename: json['resume_filename'] ?? json['resume_name'],
      coverLetter: json['cover_letter'],
      experienceYears: json['experience_years'],
      expectedSalary: json['expected_salary']?.toString(),
      noticePeriod: json['notice_period'],
      portfolioUrl: json['portfolio_url'],
      linkedinUrl: json['linkedin_url'],
      githubUrl: json['github_url'],
      stage: json['stage'] ?? 'new',
      stageLabel: json['stage_label'] ?? 'New',
      stageBadgeClass: json['stage_badge_class'] ?? 'bg-secondary',
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating']?.toString() ?? ''),
      internalNotes: json['internal_notes'],
      applicant: json['applicant'] != null ? JobApplicantProfile.fromJson(json['applicant']) : null,
      job: json['job'] != null ? FanPageJobModel.fromJson(json['job']) : null,
      createdAtHuman: json['created_at_human'] ?? json['created_at'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

