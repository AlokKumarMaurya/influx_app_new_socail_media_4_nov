import 'user_model.dart';

class StoryModel {
  final int id;
  final int userId;
  final String? mediaUrl;
  final String mediaType; // 'image', 'video', 'text'
  final String? content;
  final String? bgColor;
  final String? fontStyle;
  final UserModel? user;
  final String? createdAt;

  StoryModel({
    required this.id,
    required this.userId,
    this.mediaUrl,
    this.mediaType = 'image',
    this.content,
    this.bgColor,
    this.fontStyle,
    this.user,
    this.createdAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    String mediaType = json['media_type'] ?? json['type'] ?? json['file_type'] ?? 'image';

    final url = json['media_url'] as String?;
    
    // Robust detection: if URL ends in video extension, force it to video
    if (url != null && (url.toLowerCase().endsWith('.mp4') || 
        url.toLowerCase().endsWith('.mov') || 
        url.toLowerCase().endsWith('.avi') || 
        url.toLowerCase().endsWith('.m4v'))) {
      mediaType = 'video';
    }

    return StoryModel(
      id: json['id'],
      userId: json['user_id'],
      mediaUrl: url,
      mediaType: mediaType,
      content: json['content'],
      bgColor: json['bg_color'],
      fontStyle: json['font_style'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      createdAt: json['created_at'],
    );
  }

  StoryModel copyWith({
    int? id,
    int? userId,
    String? mediaUrl,
    String? mediaType,
    String? content,
    String? bgColor,
    String? fontStyle,
    UserModel? user,
    String? createdAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      content: content ?? this.content,
      bgColor: bgColor ?? this.bgColor,
      fontStyle: fontStyle ?? this.fontStyle,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class StoryGroup {
  final UserModel user;
  final List<StoryModel> stories;
  final bool hasUnseenStories;

  StoryGroup({
    required this.user,
    required this.stories,
    this.hasUnseenStories = true,
  });
}
