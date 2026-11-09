import '../../config/app_config.dart';

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  return int.tryParse(val.toString()) ?? 0;
}

class ForumCategoryModel {
  final int id;
  final int? parentId;
  final String name;
  final String slug;
  final String? description;
  final String icon;
  final String color;
  final int topicsCount;
  final List<ForumCategoryModel> subcategories;

  ForumCategoryModel({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    this.description,
    required this.icon,
    required this.color,
    required this.topicsCount,
    this.subcategories = const [],
  });

  factory ForumCategoryModel.fromJson(Map<String, dynamic> json) {
    var subcatsList = (json['subcategories'] as List? ?? [])
        .map((s) => ForumCategoryModel.fromJson(s))
        .toList();

    return ForumCategoryModel(
      id: _toInt(json['id']),
      parentId: json['parent_id'] != null ? _toInt(json['parent_id']) : null,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'] ?? 'hgi-stroke hgi-bubble-chat-delay',
      color: json['color'] ?? '#7c3aed',
      topicsCount: _toInt(json['topics_count']),
      subcategories: subcatsList,
    );
  }
}

class ForumTopicModel {
  final int id;
  final int categoryId;
  final int? subcategoryId;
  final int userId;
  final String title;
  final String slug;
  final String content;
  final bool isPinned;
  final bool isLocked;
  final bool isSolved;
  final int viewsCount;
  final int repliesCount;
  final int likesCount;
  final String createdAt;
  final String? authorName;
  final String? authorAvatar;
  final ForumCategoryModel? category;
  final ForumCategoryModel? subcategory;
  final List<ForumMediaModel> media;
  final ForumReplyModel? solvedReply;
  final List<ForumReplyModel> replies;

  ForumTopicModel({
    required this.id,
    required this.categoryId,
    this.subcategoryId,
    required this.userId,
    required this.title,
    required this.slug,
    required this.content,
    required this.isPinned,
    required this.isLocked,
    required this.isSolved,
    required this.viewsCount,
    required this.repliesCount,
    required this.likesCount,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.category,
    this.subcategory,
    this.media = const [],
    this.solvedReply,
    this.replies = const [],
  });

  factory ForumTopicModel.fromJson(Map<String, dynamic> json) {
    var userJson = json['user'] ?? {};
    var categoryJson = json['category'];
    var subcategoryJson = json['subcategory'];
    var mediaList = (json['media'] as List? ?? []).map((m) => ForumMediaModel.fromJson(m)).toList();
    var repliesList = (json['replies'] as List? ?? []).map((r) => ForumReplyModel.fromJson(r)).toList();
    var solvedJson = json['solved_reply'];

    return ForumTopicModel(
      id: _toInt(json['id']),
      categoryId: _toInt(json['category_id']),
      subcategoryId: json['subcategory_id'] != null ? _toInt(json['subcategory_id']) : null,
      userId: _toInt(json['user_id']),
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      isPinned: json['is_pinned'] == 1 || json['is_pinned'] == true,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isSolved: json['is_solved'] == 1 || json['is_solved'] == true,
      viewsCount: _toInt(json['views_count']),
      repliesCount: _toInt(json['replies_count']),
      likesCount: _toInt(json['likes_count']),
      createdAt: json['created_at'] ?? '',
      authorName: userJson['name'],
      authorAvatar: userJson['avatar_url'],
      category: categoryJson != null ? ForumCategoryModel.fromJson(categoryJson) : null,
      subcategory: subcategoryJson != null ? ForumCategoryModel.fromJson(subcategoryJson) : null,
      media: mediaList,
      solvedReply: solvedJson != null ? ForumReplyModel.fromJson(solvedJson) : null,
      replies: repliesList,
    );
  }
}

class ForumReplyModel {
  final int id;
  final int topicId;
  final int userId;
  final int? parentId;
  final String content;
  final bool isSolution;
  final int likesCount;
  final String createdAt;
  final String? authorName;
  final String? authorAvatar;
  final List<ForumMediaModel> media;
  final List<ForumReplyModel> children;

  ForumReplyModel({
    required this.id,
    required this.topicId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.isSolution,
    required this.likesCount,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.media = const [],
    this.children = const [],
  });

  factory ForumReplyModel.fromJson(Map<String, dynamic> json) {
    var userJson = json['user'] ?? {};
    var mediaList = (json['media'] as List? ?? []).map((m) => ForumMediaModel.fromJson(m)).toList();
    var childrenList = (json['children'] as List? ?? []).map((c) => ForumReplyModel.fromJson(c)).toList();

    return ForumReplyModel(
      id: _toInt(json['id']),
      topicId: _toInt(json['topic_id']),
      userId: _toInt(json['user_id']),
      parentId: json['parent_id'] != null ? _toInt(json['parent_id']) : null,
      content: json['content'] ?? '',
      isSolution: json['is_solution'] == 1 || json['is_solution'] == true,
      likesCount: _toInt(json['likes_count']),
      createdAt: json['created_at'] ?? '',
      authorName: userJson['name'],
      authorAvatar: userJson['avatar_url'],
      media: mediaList,
      children: childrenList,
    );
  }
}

class ForumMediaModel {
  final int id;
  final String url;
  final String fileName;
  final String fileType;
  final int fileSize;

  ForumMediaModel({
    required this.id,
    required this.url,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });

  factory ForumMediaModel.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['url'] ?? json['file_path'] ?? '';
    if (rawUrl.isNotEmpty && !rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      final base = AppConfig.baseUrl.replaceAll('/api', '');
      final cleanPath = rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl;
      rawUrl = '$base/$cleanPath';
    }

    return ForumMediaModel(
      id: _toInt(json['id']),
      url: rawUrl,
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? 'file',
      fileSize: _toInt(json['file_size']),
    );
  }
}
