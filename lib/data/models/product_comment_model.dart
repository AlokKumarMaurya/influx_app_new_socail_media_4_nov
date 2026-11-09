class ProductCommentModel {
  final int id;
  final int productId;
  final int? parentId;
  final String? content;
  final String? imageUrl;
  final DateTime createdAt;
  final int userId;
  final String userName;
  final String userUsername;
  final String? userAvatar;
  final List<ProductCommentModel> replies;

  ProductCommentModel({
    required this.id,
    required this.productId,
    this.parentId,
    this.content,
    this.imageUrl,
    required this.createdAt,
    required this.userId,
    required this.userName,
    required this.userUsername,
    this.userAvatar,
    this.replies = const [],
  });

  factory ProductCommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] != null ? Map<String, dynamic>.from(json['user']) : {};
    final rawReplies = json['replies'] as List?;
    final repliesList = rawReplies != null
        ? rawReplies.map((r) => ProductCommentModel.fromJson(Map<String, dynamic>.from(r))).toList()
        : <ProductCommentModel>[];

    return ProductCommentModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      parentId: int.tryParse(json['parent_id']?.toString() ?? ''),
      content: json['content']?.toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      userId: int.tryParse(user['id']?.toString() ?? '') ?? 0,
      userName: user['name']?.toString() ?? 'User',
      userUsername: user['username']?.toString() ?? '',
      userAvatar: user['avatar_url']?.toString(),
      replies: repliesList,
    );
  }
}
