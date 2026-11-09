import 'forum_model.dart';

class ThreadModel {
  final int id;
  final int userId;
  final int? parentThreadId;
  final int? rethreadId;
  final String content;
  final int likesCount;
  final int repliesCount;
  final String createdAt;
  final String? authorName;
  final String? authorAvatar;
  final List<ForumMediaModel> media;
  final List<ThreadModel> replies;

  ThreadModel({
    required this.id,
    required this.userId,
    this.parentThreadId,
    this.rethreadId,
    required this.content,
    required this.likesCount,
    required this.repliesCount,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.media = const [],
    this.replies = const [],
  });

  factory ThreadModel.fromJson(Map<String, dynamic> json) {
    var userJson = json['user'] ?? {};
    var mediaList = (json['media'] as List? ?? []).map((m) => ForumMediaModel.fromJson(m)).toList();
    var repliesList = (json['replies'] as List? ?? []).map((r) => ThreadModel.fromJson(r)).toList();

    return ThreadModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      parentThreadId: json['parent_thread_id'],
      rethreadId: json['rethread_id'],
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      repliesCount: json['replies_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
      authorName: userJson['name'],
      authorAvatar: userJson['avatar_url'],
      media: mediaList,
      replies: repliesList,
    );
  }
}
