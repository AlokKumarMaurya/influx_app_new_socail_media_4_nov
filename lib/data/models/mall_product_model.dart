class MallProductModel {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String? description;
  final String? category;

  const MallProductModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.description,
    this.category,
  });

  factory MallProductModel.fromJson(Map<String, dynamic> json) {
    // Mall responses can expose the image as a direct URL, a relative storage
    // path, or an object/list containing the URL.
    final image = _firstPresent(json, const [
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

    final rawPrice = json['price'] ?? json['selling_price'] ?? 0;
    final rawOriginalPrice =
        json['original_price'] ?? json['mrp'] ?? json['compare_at_price'];

    return MallProductModel(
      id: int.tryParse((json['id'] ?? json['product_id'] ?? '').toString()) ?? 0,
      name: (json['name'] ?? json['title'] ?? json['product_name'] ?? 'Product')
          .toString(),
      imageUrl: _imageUrl(image),
      price: double.tryParse(rawPrice.toString()) ?? 0,
      originalPrice: rawOriginalPrice == null
          ? null
          : double.tryParse(rawOriginalPrice.toString()),
      description: json['description']?.toString(),
      category: json['category'] is Map
          ? (json['category']['name'] ?? '').toString()
          : json['category']?.toString(),
    );
  }

  static dynamic _firstPresent(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
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

      // The API may return Laravel storage paths rather than full URLs.
      path = path.replaceFirst(RegExp(r'^/+'), '');
      return 'https://mall.hmecompany.com/$path';
    }

    if (value is Map) {
      // Handle common Laravel/API media object shapes.
      for (final key in const [
        'url',
        'original_url',
        'file_url',
        'image_url',
        'path',
        'file_path',
        'src',
        'image',
      ]) {
        final nested = value[key];
        if (nested != null && nested.toString().trim().isNotEmpty) {
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
