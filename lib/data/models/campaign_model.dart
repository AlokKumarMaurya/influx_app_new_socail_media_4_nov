import 'user_model.dart';

class CampaignModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String? niche;
  final String type; // portfolio, campaign, collab
  final double? budgetFrom;
  final double? budgetTo;
  final List<String> platforms;
  final String mediaType; // image, video, both, none
  final String status; // active, draft, closed
  final DateTime? createdAt;
  final UserModel? user;
  final List<CampaignMediaModel> media;

  CampaignModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.niche,
    required this.type,
    this.budgetFrom,
    this.budgetTo,
    required this.platforms,
    required this.mediaType,
    required this.status,
    this.createdAt,
    this.user,
    required this.media,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    var rawPlatforms = json['platforms'];
    List<String> parsedPlatforms = [];
    if (rawPlatforms is List) {
      parsedPlatforms = List<String>.from(rawPlatforms);
    } else if (rawPlatforms is String) {
      // Sometimes it could be string-encoded json or comma-separated
      parsedPlatforms = [rawPlatforms];
    }

    var rawMedia = json['media'] as List?;
    List<CampaignMediaModel> parsedMedia = rawMedia != null
        ? rawMedia.map((m) => CampaignMediaModel.fromJson(m)).toList()
        : [];

    return CampaignModel(
      id: json['id'],
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      title: json['title'] ?? '',
      description: json['description'],
      niche: json['niche'],
      type: json['type'] ?? 'campaign',
      budgetFrom: json['budget_from'] != null ? double.tryParse(json['budget_from'].toString()) : null,
      budgetTo: json['budget_to'] != null ? double.tryParse(json['budget_to'].toString()) : null,
      platforms: parsedPlatforms,
      mediaType: json['media_type'] ?? 'none',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      media: parsedMedia,
    );
  }
}

class CampaignMediaModel {
  final int id;
  final int campaignId;
  final String filePath;
  final String type; // image, video
  final int order;

  CampaignMediaModel({
    required this.id,
    required this.campaignId,
    required this.filePath,
    required this.type,
    required this.order,
  });

  factory CampaignMediaModel.fromJson(Map<String, dynamic> json) {
    return CampaignMediaModel(
      id: json['id'],
      campaignId: json['campaign_id'] is int ? json['campaign_id'] : int.parse(json['campaign_id'].toString()),
      filePath: json['file_path'] ?? '',
      type: json['type'] ?? 'image',
      order: json['order'] is int ? json['order'] : int.parse(json['order']?.toString() ?? '0'),
    );
  }
}
