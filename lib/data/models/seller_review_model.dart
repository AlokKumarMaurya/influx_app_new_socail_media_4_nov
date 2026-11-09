class SellerReviewModel {
  final int id;
  final int rating;
  final String? review;
  final List<String> images;
  final String? reply;
  final DateTime createdAt;
  final int buyerId;
  final String buyerName;
  final String buyerUsername;
  final String? buyerAvatar;

  SellerReviewModel({
    required this.id,
    required this.rating,
    this.review,
    this.images = const [],
    this.reply,
    required this.createdAt,
    required this.buyerId,
    required this.buyerName,
    required this.buyerUsername,
    this.buyerAvatar,
  });

  factory SellerReviewModel.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] != null ? Map<String, dynamic>.from(json['buyer']) : {};
    final rawImages = json['images'] as List?;
    final imagesList = rawImages != null ? rawImages.map((e) => e.toString()).toList() : <String>[];

    return SellerReviewModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 5,
      review: json['review']?.toString(),
      images: imagesList,
      reply: json['reply']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      buyerId: int.tryParse(buyer['id']?.toString() ?? '') ?? 0,
      buyerName: buyer['name']?.toString() ?? 'User',
      buyerUsername: buyer['username']?.toString() ?? '',
      buyerAvatar: buyer['avatar_url']?.toString(),
    );
  }
}
