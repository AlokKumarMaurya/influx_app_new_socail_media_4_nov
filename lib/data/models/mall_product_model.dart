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
    final image = json['image'] ??
        json['image_url'] ??
        json['thumbnail'] ??
        json['primary_image_url'] ??
        json['cover_image'];
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
      category: (json['category'] is Map)
          ? (json['category']['name'] ?? '').toString()
          : json['category']?.toString(),
    );
  }

  static String _imageUrl(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      return (value['url'] ?? value['path'] ?? value['file_url'] ?? '')
          .toString();
    }
    if (value is List && value.isNotEmpty) return _imageUrl(value.first);
    return '';
  }
}