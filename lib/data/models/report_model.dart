import 'post_model.dart';

class ReportModel {
  final int id;
  final int postId;
  final String reason;
  final String? details;
  final String status;
  final String createdAt;
  final PostModel? post;

  ReportModel({
    required this.id,
    required this.postId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    this.post,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      postId: json['post_id'],
      reason: json['reason'] ?? 'other',
      details: json['details'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      post: json['post'] != null ? PostModel.fromJson(json['post']) : null,
    );
  }
}
