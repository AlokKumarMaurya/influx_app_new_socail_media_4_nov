class BadgeModel {
  final int id;
  final String name;
  final String? description;
  final String iconUrl;
  final double price;
  final String formattedPrice;
  final int extraStorageMb;
  final bool isVisibleOnProfile;
  final bool isPublic;
  final bool allowRepurchase;
  final bool isOwned;
  final int ownedCount;

  BadgeModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconUrl,
    required this.price,
    required this.formattedPrice,
    required this.extraStorageMb,
    this.isVisibleOnProfile = true,
    this.isPublic = true,
    this.allowRepurchase = false,
    this.isOwned = false,
    this.ownedCount = 0,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      iconUrl: json['icon_url'] ?? '',
      price: (json['price'] != null) ? double.parse(json['price'].toString()) : 0.0,
      formattedPrice: json['formatted_price'] ?? '\$0.00',
      extraStorageMb: json['extra_storage_mb'] ?? 0,
      isVisibleOnProfile: json['is_visible_on_profile'] ?? true,
      isPublic: json['is_public'] ?? true,
      allowRepurchase: json['allow_repurchase'] ?? false,
      isOwned: json['is_owned'] ?? false,
      ownedCount: json['owned_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'price': price,
      'formatted_price': formattedPrice,
      'extra_storage_mb': extraStorageMb,
      'is_visible_on_profile': isVisibleOnProfile,
      'is_public': isPublic,
      'allow_repurchase': allowRepurchase,
      'is_owned': isOwned,
      'owned_count': ownedCount,
    };
  }
}

class UserBadgeModel {
  final int id;
  final int badgeId;
  final double pricePaid;
  final bool isEquipped;
  final DateTime? purchasedAt;
  final BadgeModel badge;

  UserBadgeModel({
    required this.id,
    required this.badgeId,
    required this.pricePaid,
    required this.isEquipped,
    this.purchasedAt,
    required this.badge,
  });

  factory UserBadgeModel.fromJson(Map<String, dynamic> json) {
    return UserBadgeModel(
      id: json['id'],
      badgeId: json['badge_id'],
      pricePaid: (json['price_paid'] != null) ? double.parse(json['price_paid'].toString()) : 0.0,
      isEquipped: json['is_equipped'] ?? false,
      purchasedAt: json['purchased_at'] != null ? DateTime.parse(json['purchased_at']) : null,
      badge: BadgeModel.fromJson(json['badge']),
    );
  }
}

class StorageInfoModel {
  final int usedBytes;
  final double usedMb;
  final int maxBytes;
  final int maxMb;
  final bool isUnlimited;
  final double usagePercentage;
  final String formattedUsed;
  final String formattedMax;

  StorageInfoModel({
    required this.usedBytes,
    required this.usedMb,
    required this.maxBytes,
    required this.maxMb,
    required this.isUnlimited,
    required this.usagePercentage,
    required this.formattedUsed,
    required this.formattedMax,
  });

  factory StorageInfoModel.fromJson(Map<String, dynamic> json) {
    return StorageInfoModel(
      usedBytes: json['used_bytes'] ?? 0,
      usedMb: (json['used_mb'] != null) ? double.parse(json['used_mb'].toString()) : 0.0,
      maxBytes: json['max_bytes'] ?? 0,
      maxMb: json['max_mb'] ?? 0,
      isUnlimited: json['is_unlimited'] ?? false,
      usagePercentage: (json['usage_percentage'] != null) ? double.parse(json['usage_percentage'].toString()) : 0.0,
      formattedUsed: json['formatted_used'] ?? '0 MB',
      formattedMax: json['formatted_max'] ?? 'Unlimited',
    );
  }
}
