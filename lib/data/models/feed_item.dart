import 'post_model.dart';

enum FeedItemType { post, ad, suggestedGroups, suggestedPages, suggestedPeople, suggestedProducts, suggestedLives }

class AdModel {
  final int id;
  final String title;
  final String description;
  final String? image;
  final List<AdMediaModel> media;
  final String? link;
  final String? cta;
  final String? advertiserName;
  final String? adType;
  final int? postId;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    required this.media,
    this.link,
    this.cta,
    this.advertiserName,
    this.adType,
    this.postId,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      media: json['media'] != null
          ? (json['media'] as List).map((m) => AdMediaModel.fromJson(m)).toList()
          : [],
      link: json['link'],
      cta: json['cta'],
      advertiserName: json['advertiser_name'] ?? 'Sponsored',
      adType: json['ad_type'],
      postId: json['post_id'],
    );
  }
}

class AdMediaModel {
  final int id;
  final String fileUrl;
  final String type;

  AdMediaModel({
    required this.id,
    required this.fileUrl,
    required this.type,
  });

  factory AdMediaModel.fromJson(Map<String, dynamic> json) {
    return AdMediaModel(
      id: json['id'],
      fileUrl: json['file_url'] ?? '',
      type: json['type'] ?? 'image',
    );
  }
}

class FeedItem {
  final FeedItemType type;
  final PostModel? post;
  final AdModel? ad;
  final List<dynamic>? suggestions;

  FeedItem({
    required this.type,
    this.post,
    this.ad,
    this.suggestions,
  });

  factory FeedItem.post(PostModel post) => FeedItem(type: FeedItemType.post, post: post);
  factory FeedItem.ad(AdModel ad) => FeedItem(type: FeedItemType.ad, ad: ad);
  factory FeedItem.groups(List<dynamic> groups) => FeedItem(type: FeedItemType.suggestedGroups, suggestions: groups);
  factory FeedItem.pages(List<dynamic> pages) => FeedItem(type: FeedItemType.suggestedPages, suggestions: pages);
  factory FeedItem.people(List<dynamic> people) => FeedItem(type: FeedItemType.suggestedPeople, suggestions: people);
  factory FeedItem.products(List<dynamic> products) => FeedItem(type: FeedItemType.suggestedProducts, suggestions: products);
  factory FeedItem.lives(List<dynamic> lives) => FeedItem(type: FeedItemType.suggestedLives, suggestions: lives);
}
