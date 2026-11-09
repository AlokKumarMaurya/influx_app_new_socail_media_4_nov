import 'user_model.dart';
import 'comment_model.dart';
import 'fan_page_job_model.dart';
import 'fan_page_model.dart';
import 'live_stream_model.dart';

class PostMediaModel {
  final int id;
  final String filePath;
  final String fileType; // 'image' or 'video'
  final int viewsCount;

  PostMediaModel({required this.id, required this.filePath, required this.fileType, this.viewsCount = 0});

  factory PostMediaModel.fromJson(Map<String, dynamic> json) {
    return PostMediaModel(
      id: json['id'],
      filePath: json['file_path'] ?? json['file_url'] ?? '',
      fileType: json['file_type'] ?? 'image',
      viewsCount: json['views_count'] ?? 0,
    );
  }
}

class PostModel {
  final int id;
  final int userId;
  final int? groupId;
  final int? fanPageId;
  final int? sharedPostId;
  final String? content;
  final String postType; // text, image, video, color
  final String? bgColor;
  final String? feelingAction;
  final String? feelingValue;
  final String? location;
  final String privacy; // public, friends, only_me
  final String? linkUrl;
  final String? linkTitle;
  final String? linkDescription;
  final String? linkImage;
  final String? linkDomain;
  final UserModel? user;
  final FanPageModel? fanPage;
  final String? groupName;
  final List<PostMediaModel> media;
  final List<CommentModel> comments;
  final int reactionsCount;
  final int commentsCount;
  final int sharesCount;
  final String? userReaction;
  final Map<String, int> reactionSummary;
  final PostModel? sharedPost;
  final LiveStreamModel? liveStream;
  final FanPageJobModel? fanPageJob;
  final List<UserModel> tags;
  final bool isSaved;
  final String? createdAt;

  PostModel({
    required this.id,
    required this.userId,
    this.groupId,
    this.fanPageId,
    this.sharedPostId,
    this.content,
    this.postType = 'text',
    this.bgColor,
    this.feelingAction,
    this.feelingValue,
    this.location,
    this.privacy = 'public',
    this.linkUrl,
    this.linkTitle,
    this.linkDescription,
    this.linkImage,
    this.linkDomain,
    this.user,
    this.fanPage,
    this.groupName,
    this.media = const [],
    this.comments = const [],
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.userReaction,
    this.reactionSummary = const {},
    this.sharedPost,
    this.liveStream,
    this.fanPageJob,
    this.tags = const [],
    this.isSaved = false,
    this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      groupId: json['group_id'],
      fanPageId: json['fan_page_id'],
      sharedPostId: json['shared_post_id'],
      content: json['content'],
      postType: json['post_type'] ?? 'text',
      bgColor: json['bg_color'],
      feelingAction: json['feeling_action'],
      feelingValue: json['feeling_value'],
      location: json['location'],
      privacy: json['privacy'] ?? 'public',
      linkUrl: json['link_url'],
      linkTitle: json['link_title'],
      linkDescription: json['link_description'],
      linkImage: json['link_image'],
      linkDomain: json['link_domain'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      fanPage: json['fan_page'] != null ? FanPageModel.fromJson(json['fan_page']) : null,
      groupName: json['group'] != null ? json['group']['name'] : null,
      media: json['media'] != null
          ? (json['media'] as List).map((m) => PostMediaModel.fromJson(m)).toList()
          : [],
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => CommentModel.fromJson(c)).toList()
          : [],
      reactionsCount: json['reactions_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      userReaction: json['user_reaction'],
      reactionSummary: (json['reaction_summary'] is Map)
          ? Map<String, int>.from(json['reaction_summary'])
          : {},
      sharedPost: json['shared_post'] != null
          ? PostModel.fromJson(json['shared_post'])
          : null,
      liveStream: json['live_stream'] is Map
          ? LiveStreamModel.fromJson(Map<String, dynamic>.from(json['live_stream']))
          : null,
      fanPageJob: json['fan_page_job'] is Map
          ? FanPageJobModel.fromJson(Map<String, dynamic>.from(json['fan_page_job']))
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as List).map((u) => UserModel.fromJson(u)).toList()
          : [],
      isSaved: json['is_saved'] ?? false,
      createdAt: json['created_at'],
    );
  }

  /// Copy with updated fields (for reactive state updates).
  PostModel copyWith({
    String? userReaction,
    bool clearUserReaction = false,
    int? reactionsCount,
    Map<String, int>? reactionSummary,
    int? commentsCount,
    int? sharesCount,
    bool? isSaved,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      groupId: groupId,
      sharedPostId: sharedPostId,
      content: content,
      postType: postType,
      bgColor: bgColor,
      feelingAction: feelingAction,
      feelingValue: feelingValue,
      location: location,
      privacy: privacy,
      user: user,
      groupName: groupName,
      media: media,
      comments: comments,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      userReaction: clearUserReaction ? null : (userReaction ?? this.userReaction),
      reactionSummary: reactionSummary ?? this.reactionSummary,
      sharedPost: sharedPost,
      liveStream: liveStream,
      fanPageJob: fanPageJob,
      tags: tags,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt,
    );
  }
}

