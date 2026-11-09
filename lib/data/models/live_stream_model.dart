class LiveStreamModel {
  final int id;
  final String uuid;
  final int? postId;
  final String channelName;
  final String title;
  final String? description;
  final String category;
  final String thumbnailUrl;
  final String status;
  final bool isPaid;
  final double entryFee;
  final bool isUnlocked;
  final int viewerCount;
  final int peakViewerCount;
  final int durationSeconds;
  final String durationLabel;
  final int totalReactionsCount;
  final int eventsCount;
  final double totalEarnings;
  final String broadcasterName;
  final String broadcasterAvatar;
  final bool broadcasterVerified;
  final int userId;
  final int? fanPageId;
  final String? startedAt;
  final String? endedAt;
  final String? currencySymbol;

  bool get isLive => status == 'live';

  LiveStreamModel({
    required this.id,
    required this.uuid,
    this.postId,
    required this.channelName,
    required this.title,
    this.description,
    this.category = 'general',
    required this.thumbnailUrl,
    this.status = 'live',
    this.isPaid = false,
    this.entryFee = 0.0,
    this.isUnlocked = true,
    this.viewerCount = 0,
    this.peakViewerCount = 0,
    this.durationSeconds = 0,
    this.durationLabel = '0s',
    this.totalReactionsCount = 0,
    this.eventsCount = 0,
    this.totalEarnings = 0.0,
    required this.broadcasterName,
    required this.broadcasterAvatar,
    this.broadcasterVerified = false,
    required this.userId,
    this.fanPageId,
    this.startedAt,
    this.endedAt,
    this.currencySymbol,
  });

  factory LiveStreamModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      uuid: (json['uuid'] ?? '').toString(),
      postId: (json['post_id'] as num?)?.toInt(),
      channelName: (json['channel_name'] ?? '').toString(),
      title: (json['title'] ?? 'Live Broadcast').toString(),
      description: json['description']?.toString(),
      category: (json['category'] ?? 'general').toString(),
      thumbnailUrl: (json['thumbnail_url'] ?? '').toString(),
      status: (json['status'] ?? 'live').toString(),
      isPaid: json['is_paid'] == true || json['is_paid'] == 1,
      entryFee: double.tryParse((json['entry_fee'] ?? 0).toString()) ?? 0.0,
      isUnlocked: json['is_unlocked'] == null
          ? true
          : (json['is_unlocked'] == true || json['is_unlocked'] == 1),
      viewerCount: (json['viewer_count'] as num?)?.toInt() ?? 0,
      peakViewerCount: (json['peak_viewer_count'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      durationLabel: (json['duration_label'] ?? '0s').toString(),
      totalReactionsCount: (json['total_reactions_count'] as num?)?.toInt() ?? 0,
      eventsCount: (json['events_count'] as num?)?.toInt() ?? 0,
      totalEarnings: double.tryParse((json['total_earnings'] ?? 0).toString()) ?? 0.0,
      broadcasterName: (json['broadcaster_name'] ?? 'Streamer').toString(),
      broadcasterAvatar: (json['broadcaster_avatar'] ?? '').toString(),
      broadcasterVerified:
          json['broadcaster_verified'] == true || json['broadcaster_verified'] == 1,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      fanPageId: (json['fan_page_id'] as num?)?.toInt(),
      startedAt: json['started_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      currencySymbol: json['currency_symbol']?.toString(),
    );
  }
}

class LiveGiftModel {
  final int id;
  final String name;
  final String icon;
  final String? imageUrl;
  final String animationType;
  final double price;
  final bool isFree;

  LiveGiftModel({
    required this.id,
    required this.name,
    required this.icon,
    this.imageUrl,
    this.animationType = 'floating_burst',
    this.price = 0.0,
    this.isFree = true,
  });

  factory LiveGiftModel.fromJson(Map<String, dynamic> json) {
    final p = double.tryParse((json['price'] ?? 0).toString()) ?? 0.0;
    return LiveGiftModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? 'Gift').toString(),
      icon: (json['icon'] ?? '🎁').toString(),
      imageUrl: json['image_url']?.toString(),
      animationType: (json['animation_type'] ?? 'floating_burst').toString(),
      price: p,
      isFree: json['is_free'] == true || p <= 0,
    );
  }
}

class SuperChatTierModel {
  final String name;
  final double minAmount;
  final String color;
  final int durationSeconds;

  SuperChatTierModel({
    required this.name,
    required this.minAmount,
    required this.color,
    required this.durationSeconds,
  });

  factory SuperChatTierModel.fromJson(Map<String, dynamic> json) {
    return SuperChatTierModel(
      name: (json['name'] ?? 'Super Chat').toString(),
      minAmount: double.tryParse((json['min_amount'] ?? 1).toString()) ?? 1.0,
      color: (json['color'] ?? '#8B5CF6').toString(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 60,
    );
  }
}

class LiveEventModel {
  final int id;
  final String type; // comment, super_chat, gift, tip, reaction, system
  final String? message;
  final double amount;
  final Map<String, dynamic> meta;
  final bool isPinned;
  final String? pinnedUntil;
  final String? createdAt;
  final int? userId;
  final String userName;
  final String userAvatar;
  final bool userVerified;

  LiveEventModel({
    required this.id,
    required this.type,
    this.message,
    this.amount = 0.0,
    this.meta = const {},
    this.isPinned = false,
    this.pinnedUntil,
    this.createdAt,
    this.userId,
    required this.userName,
    required this.userAvatar,
    this.userVerified = false,
  });

  factory LiveEventModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};
    final metaMap = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : <String, dynamic>{};

    return LiveEventModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'comment').toString(),
      message: json['message']?.toString(),
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
      meta: metaMap,
      isPinned: json['is_pinned'] == true || json['is_pinned'] == 1,
      pinnedUntil: json['pinned_until']?.toString(),
      createdAt: json['created_at']?.toString(),
      userId: (userMap['id'] as num?)?.toInt(),
      userName: (userMap['name'] ?? 'Viewer').toString(),
      userAvatar: (userMap['avatar_url'] ?? '').toString(),
      userVerified: userMap['is_verified'] == true || userMap['is_verified'] == 1,
    );
  }
}

