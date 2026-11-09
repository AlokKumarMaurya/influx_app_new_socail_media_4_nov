import 'user_model.dart';

class CommentModel {
  final int id;
  final int userId;
  final String? content;
  final String? mediaUrl;
  final UserModel? user;
  final int likesCount;
  final String? userReaction;
  final Map<String, int> reactionSummary;
  final List<CommentModel> replies;
  final String? createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    this.content,
    this.mediaUrl,
    this.user,
    this.likesCount = 0,
    this.userReaction,
    this.reactionSummary = const {},
    this.replies = const [],
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      mediaUrl: json['media_url'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      likesCount: json['likes_count'] ?? 0,
      userReaction: json['user_reaction'],
      reactionSummary: (json['reaction_summary'] is Map)
          ? Map<String, int>.from(json['reaction_summary'])
          : {},
      replies: json['replies'] != null
          ? (json['replies'] as List).map((r) => CommentModel.fromJson(r)).toList()
          : [],
      createdAt: json['created_at'],
    );
  }

  CommentModel copyWith({
    int? id,
    int? userId,
    String? content,
    String? mediaUrl,
    UserModel? user,
    int? likesCount,
    String? userReaction,
    Object? userReactionValue = const Object(), // Use an object to handle null overrides
    Map<String, int>? reactionSummary,
    List<CommentModel>? replies,
    String? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      user: user ?? this.user,
      likesCount: likesCount ?? this.likesCount,
      userReaction: userReactionValue != const Object() ? (userReactionValue as String?) : (userReaction ?? this.userReaction),
      reactionSummary: reactionSummary ?? this.reactionSummary,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
