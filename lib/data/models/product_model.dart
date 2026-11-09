import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

class ProductModel {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final double price;
  final double? salePrice;
  final String currency;
  final String? location;
  final String condition;
  final String status;
  final int categoryId;
  final int userId;
  final String? primaryImageUrl;
  final List<ProductMediaModel> media;
  final ProductSellerModel? seller;
  final ProductCategoryModel? category;
  final bool isSaved;
  final bool isNew;
  final DateTime createdAt;
  final Map<String, dynamic> customFieldsData;

  final String? formattedPriceRaw;

  ProductModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.price,
    this.salePrice,
    required this.currency,
    this.formattedPriceRaw,
    this.location,
    required this.condition,
    required this.status,
    required this.categoryId,
    required this.userId,
    this.primaryImageUrl,
    this.media = const [],
    this.seller,
    this.category,
    this.isSaved = false,
    this.isNew = false,
    this.customFieldsData = const {},
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      salePrice: json['sale_price'] != null
          ? double.tryParse(json['sale_price'].toString())
          : null,
      currency: json['currency']?.toString() ?? '\$',
      formattedPriceRaw: json['formatted_price']?.toString(),
      location: json['location']?.toString(),
      condition: json['condition']?.toString() ?? 'new',
      status: json['status']?.toString() ?? 'available',
      categoryId: int.tryParse(json['category_id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      primaryImageUrl: json['primary_image_url']?.toString(),
      media: json['media'] != null
          ? (json['media'] as List)
              .map((m) => ProductMediaModel.fromJson(m))
              .toList()
          : [],
      seller: json['seller'] != null
          ? ProductSellerModel.fromJson(json['seller'])
          : null,
      category: json['category'] != null
          ? ProductCategoryModel.fromJson(json['category'])
          : null,
      isSaved: json['is_saved'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      customFieldsData: json['custom_fields_data'] != null && json['custom_fields_data'] is Map
          ? Map<String, dynamic>.from(json['custom_fields_data'])
          : {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get formattedPrice {
    if (formattedPriceRaw != null && formattedPriceRaw!.isNotEmpty) {
      return formattedPriceRaw!;
    }
    String symbol = '\$';
    try {
      if (Get.isRegistered<SettingsController>()) {
        symbol = Get.find<SettingsController>().currencySymbol.value;
      }
    } catch (_) {}
    return '$symbol${price.toStringAsFixed(2)}';
  }

  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Brand New';
      case 'used_like_new':
        return 'Used - Like New';
      case 'used_good':
        return 'Used - Good';
      case 'used_fair':
        return 'Used - Fair';
      default:
        return condition;
    }
  }

  ProductModel copyWith({
    bool? isSaved,
    String? status,
  }) {
    return ProductModel(
      id: id,
      title: title,
      slug: slug,
      description: description,
      price: price,
      salePrice: salePrice,
      currency: currency,
      location: location,
      condition: condition,
      status: status ?? this.status,
      categoryId: categoryId,
      userId: userId,
      primaryImageUrl: primaryImageUrl,
      media: media,
      seller: seller,
      category: category,
      isSaved: isSaved ?? this.isSaved,
      isNew: isNew,
      createdAt: createdAt,
    );
  }
}

class ProductMediaModel {
  final int id;
  final String fileUrl;
  final bool isPrimary;

  ProductMediaModel({
    required this.id,
    required this.fileUrl,
    required this.isPrimary,
  });

  factory ProductMediaModel.fromJson(Map<String, dynamic> json) {
    return ProductMediaModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fileUrl: json['file_url'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class ProductSellerModel {
  final int id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime createdAt;

  ProductSellerModel({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    this.isOnline = false,
    required this.createdAt,
  });

  factory ProductSellerModel.fromJson(Map<String, dynamic> json) {
    return ProductSellerModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class ProductCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? path;

  ProductCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.path,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
      path: json['path'] as String?,
    );
  }
}
