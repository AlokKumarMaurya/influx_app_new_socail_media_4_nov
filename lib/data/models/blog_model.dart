class BlogModel {
  final int id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String? category;
  final String? tags;
  final String status;
  final String? featuredImage;
  final int viewsCount;
  final int readingTime;
  final String? publishedAt;
  final String? publishedAtHuman;
  final String? publishedAtFormatted;
  final String createdAt;
  final BlogAuthor? author;

  BlogModel({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.content,
    this.category,
    this.tags,
    required this.status,
    this.featuredImage,
    required this.viewsCount,
    required this.readingTime,
    this.publishedAt,
    this.publishedAtHuman,
    this.publishedAtFormatted,
    required this.createdAt,
    this.author,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['id'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'],
      content: json['content'],
      category: json['category'],
      tags: json['tags'],
      status: json['status'] ?? 'draft',
      featuredImage: json['featured_image'],
      viewsCount: json['views_count'] ?? 0,
      readingTime: json['reading_time'] ?? 1,
      publishedAt: json['published_at'],
      publishedAtHuman: json['published_at_human'],
      publishedAtFormatted: json['published_at_formatted'],
      createdAt: json['created_at'] ?? '',
      author: json['author'] != null
          ? BlogAuthor.fromJson(json['author'])
          : null,
    );
  }
}

class BlogAuthor {
  final int id;
  final String name;
  final String? username;
  final String? avatar;
  final String? bio;
  final String? profileType;

  BlogAuthor({
    required this.id,
    required this.name,
    this.username,
    this.avatar,
    this.bio,
    this.profileType,
  });

  factory BlogAuthor.fromJson(Map<String, dynamic> json) {
    return BlogAuthor(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'],
      avatar: json['avatar'],
      bio: json['bio'],
      profileType: json['profile_type'] ?? 'user',
    );
  }
}
