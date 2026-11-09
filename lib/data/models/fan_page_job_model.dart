class FanPageJobModel {
  final int id;
  final int fanPageId;
  final String? pageName;
  final String? pageSlug;
  final int userId;
  final String title;
  final String jobType;
  final String jobTypeLabel;
  final String workplaceType;
  final String workplaceTypeLabel;
  final String? location;
  final String? category;
  final String? experienceLevel;
  final num? salaryMin;
  final num? salaryMax;
  final String? salaryCurrency;
  final String? salaryPeriod;
  final String salaryRangeLabel;
  final bool isSalaryNegotiable;
  final String description;
  final String? requirements;
  final String? benefits;
  final String? deadline;
  final String status;
  final bool allowEasyApply;
  final String? externalApplyUrl;
  final int viewsCount;
  final int applicationsCount;
  final bool hasApplied;
  final String? image;
  final String? imageUrl;
  final String createdAtHuman;
  final String createdAt;

  FanPageJobModel({
    required this.id,
    required this.fanPageId,
    this.pageName,
    this.pageSlug,
    required this.userId,
    required this.title,
    required this.jobType,
    required this.jobTypeLabel,
    required this.workplaceType,
    required this.workplaceTypeLabel,
    this.location,
    this.category,
    this.experienceLevel,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency,
    this.salaryPeriod,
    required this.salaryRangeLabel,
    required this.isSalaryNegotiable,
    required this.description,
    this.requirements,
    this.benefits,
    this.deadline,
    required this.status,
    required this.allowEasyApply,
    this.externalApplyUrl,
    required this.viewsCount,
    required this.applicationsCount,
    required this.hasApplied,
    this.image,
    this.imageUrl,
    required this.createdAtHuman,
    required this.createdAt,
  });

  factory FanPageJobModel.fromJson(Map<String, dynamic> json) {
    return FanPageJobModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fanPageId: json['fan_page_id'] is int ? json['fan_page_id'] : int.tryParse(json['fan_page_id'].toString()) ?? 0,
      pageName: json['page_name'],
      pageSlug: json['page_slug'],
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      title: json['title'] ?? '',
      jobType: json['job_type'] ?? 'full_time',
      jobTypeLabel: json['job_type_label'] ?? 'Full Time',
      workplaceType: json['workplace_type'] ?? 'on_site',
      workplaceTypeLabel: json['workplace_type_label'] ?? 'On-site',
      location: json['location'],
      category: json['category'],
      experienceLevel: json['experience_level'],
      salaryMin: json['salary_min'],
      salaryMax: json['salary_max'],
      salaryCurrency: json['salary_currency'],
      salaryPeriod: json['salary_period'],
      salaryRangeLabel: json['salary_range_label'] ?? 'Negotiable',
      isSalaryNegotiable: json['is_salary_negotiable'] == true,
      description: json['description'] ?? '',
      requirements: json['requirements'],
      benefits: json['benefits'],
      deadline: json['deadline'],
      status: json['status'] ?? 'active',
      allowEasyApply: json['allow_easy_apply'] != false,
      externalApplyUrl: json['external_apply_url'],
      viewsCount: json['views_count'] is int ? json['views_count'] : int.tryParse(json['views_count']?.toString() ?? '0') ?? 0,
      applicationsCount: json['applications_count'] is int ? json['applications_count'] : int.tryParse(json['applications_count']?.toString() ?? '0') ?? 0,
      hasApplied: json['has_applied'] == true,
      image: json['image'],
      imageUrl: json['image_url'],
      createdAtHuman: json['created_at_human'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

