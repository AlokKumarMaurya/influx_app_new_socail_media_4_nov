import 'post_model.dart';

class WatchVideoModel {
  final int mediaId;
  final String videoUrl;
  final int viewsCount;
  final PostModel post;

  WatchVideoModel({
    required this.mediaId,
    required this.videoUrl,
    required this.viewsCount,
    required this.post,
  });

  factory WatchVideoModel.fromJson(Map<String, dynamic> json) {
    return WatchVideoModel(
      mediaId: json['media_id'],
      videoUrl: json['video_url'] ?? '',
      viewsCount: json['views_count'] ?? 0,
      post: PostModel.fromJson(json['post']),
    );
  }
}
