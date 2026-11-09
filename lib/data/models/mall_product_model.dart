class MallProductModel {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String? description;
  final String? category;
  final String shareableLink;

  const MallProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.shareableLink,
    this.originalPrice,
    this.description,
    this.category,
  });

  factory MallProductModel.fromJson(Map<String, dynamic> json) {
    // The live mall API returns the primary image in "photo" and the
    // complete image gallery in "photos".
    final image = _firstPresent(json, const [
      'photo',
      'photos',
      'image_url',
      'image',
      'product_image_url',
      'product_image',
      'thumbnail_url',
      'thumbnail',
      'primary_image_url',
      'cover_image',
      'featured_image',
      'images',
      'product_images',
      'gallery',
      'media',
    ]);

    // sell_price is the customer-facing price in the supplied API response.
    final rawPrice =
        json['sell_price'] ?? json['discount_price'] ?? json['price'] ?? 0;
    final rawOriginalPrice =
        json['price'] ?? json['original_price'] ?? json['mrp'] ?? json['compare_at_price'];

    final parsedPrice = double.tryParse(rawPrice.toString()) ?? 0;
    final parsedOriginalPrice = rawOriginalPrice == null
        ? null
        : double.tryParse(rawOriginalPrice.toString());

    return MallProductModel(
      id: int.tryParse((json['id'] ?? json['product_id'] ?? '').toString()) ?? 0,
      name: (json['name'] ?? json['title'] ?? json['product_name'] ?? 'Product')
          .toString(),
      imageUrl: _imageUrl(image),
      price: parsedPrice,
      originalPrice: parsedOriginalPrice != null &&
              parsedOriginalPrice > parsedPrice
          ? parsedOriginalPrice
          : null,
      shareableLink: (json['shareable_link'] ?? '').toString().trim(),
      description: json['description']?.toString(),
      category: json['category'] is Map
          ? (json['category']['name'] ?? '').toString()
          : json['category']?.toString(),
    );
  }

  static dynamic _firstPresent(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      return value;
    }
    return null;
  }

  static String _imageUrl(dynamic value) {
    if (value == null) return '';

    if (value is String) {
      var path = value.trim().replaceAll(r'\\/', '/');
      if (path.isEmpty) return '';
      if (path.startsWith('//')) return 'https:$path';
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      path = path.replaceFirst(RegExp(r'^/+'), '');
      return 'https://mall.hmecompany.com/$path';
    }

    if (value is Map) {
      for (final key in const [
        'url', 'original_url', 'file_url', 'image_url',
        'path', 'file_path', 'src', 'image', 'photo',
      ]) {
        final nested = value[key];
        if (nested != null) {
          final result = _imageUrl(nested);
          if (result.isNotEmpty) return result;
        }
      }
      return '';
    }

    if (value is List) {
      for (final item in value) {
        final result = _imageUrl(item);
        if (result.isNotEmpty) return result;
      }
    }
    return '';
  }
}
