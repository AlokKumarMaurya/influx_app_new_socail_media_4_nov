import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../providers/api_client.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/product_comment_model.dart';

class MarketplaceService {
  final Dio _dio = ApiClient().dio;
  final GetStorage _storage = GetStorage();

  /// Get categories list.
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get('/marketplace/categories');
    final data = response.data['data'] as List;
    return data
        .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }

  /// Get applicable custom fields for category (or global).
  Future<List<Map<String, dynamic>>> getCustomFields([int? categoryId]) async {
    try {
      final response = await _dio.get(
        '/marketplace/custom-fields',
        queryParameters: categoryId != null ? {'category_id': categoryId} : null,
      );
      if (response.data['success'] == true && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get paginated products with filters.
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int? categoryId,
    String? categorySlug,
    String? query,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    String? username,
  }) async {
    final selectedCountry = _storage.read('selected_country') ?? 'all';
    final params = <String, dynamic>{'page': page, 'country': selectedCountry};
    if (categoryId != null) params['category_id'] = categoryId;
    if (categorySlug != null) params['category_slug'] = categorySlug;
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (minPrice != null) params['min_price'] = minPrice;
    if (maxPrice != null) params['max_price'] = maxPrice;
    if (condition != null) params['condition'] = condition;
    if (location != null && location.isNotEmpty) params['location'] = location;
    if (username != null && username.isNotEmpty) params['username'] = username;

    final response = await _dio.get(
      '/marketplace/products',
      queryParameters: params,
    );
    final data = response.data;

    final products = (data['data'] as List)
        .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    return {
      'products': products,
      'nextPageUrl': data['next_page_url'],
      'currentPage': data['current_page'],
      'lastPage': data['last_page'],
      'total': data['total'],
    };
  }

  /// Get single product detail.
  Future<Map<String, dynamic>> getProductDetail(int productId) async {
    final response = await _dio.get('/marketplace/products/$productId');
    final data = response.data['data'] ?? response.data;

    final product = ProductModel.fromJson(Map<String, dynamic>.from(data));
    final List<ProductModel> relatedProducts = [];

    if (data['related_products'] != null && data['related_products'] is List) {
      for (final item in data['related_products'] as List) {
        try {
          relatedProducts.add(ProductModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }

    return {
      'product': product,
      'relatedProducts': relatedProducts,
    };
  }

  /// Create a new listing.
  Future<Map<String, dynamic>> createProduct({
    required String title,
    required String description,
    required double price,
    required int categoryId,
    required String condition,
    String? location,
    Map<String, dynamic>? customFields,
    List<File>? images,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'condition': condition,
      if (location != null && location.isNotEmpty) 'location': location,
    });

    if (customFields != null && customFields.isNotEmpty) {
      customFields.forEach((key, val) {
        if (val != null) {
          formData.fields.add(MapEntry('custom_fields[$key]', val.toString()));
        }
      });
    }

    if (images != null) {
      for (final image in images) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          ),
        ));
      }
    }

    final response = await _dio.post('/marketplace/products', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  /// Update own listing.
  Future<Map<String, dynamic>> updateProduct(
    int productId, {
    String? title,
    String? description,
    double? price,
    int? categoryId,
    String? condition,
    String? location,
    String? status,
    Map<String, dynamic>? customFields,
    List<File>? images,
  }) async {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (price != null) map['price'] = price;
    if (categoryId != null) map['category_id'] = categoryId;
    if (condition != null) map['condition'] = condition;
    if (location != null) map['location'] = location;
    if (status != null) map['status'] = status;

    final formData = FormData.fromMap(map);

    if (customFields != null && customFields.isNotEmpty) {
      customFields.forEach((key, val) {
        if (val != null) {
          formData.fields.add(MapEntry('custom_fields[$key]', val.toString()));
        }
      });
    }

    if (images != null) {
      for (final image in images) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(
            image.path,
            filename: image.path.split('/').last,
          ),
        ));
      }
    }

    // Dio doesn't send FormData via PUT properly; use POST with _method override
    formData.fields.add(const MapEntry('_method', 'PUT'));
    final response = await _dio.post(
      '/marketplace/products/$productId',
      data: formData,
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Delete own listing.
  Future<bool> deleteProduct(int productId) async {
    try {
      final response = await _dio.delete('/marketplace/products/$productId');
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle save product.
  Future<Map<String, dynamic>> toggleSave(int productId) async {
    final response =
        await _dio.post('/marketplace/products/$productId/toggle-save');
    return Map<String, dynamic>.from(response.data);
  }

  /// Get user's own listings.
  Future<Map<String, dynamic>> getMyListings({int page = 1}) async {
    final response = await _dio.get(
      '/marketplace/my-listings',
      queryParameters: {'page': page},
    );
    final data = response.data;

    final products = (data['data'] as List)
        .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    return {
      'products': products,
      'nextPageUrl': data['next_page_url'],
      'currentPage': data['current_page'],
      'lastPage': data['last_page'],
      'total': data['total'],
    };
  }

  /// Get user's saved products.
  Future<Map<String, dynamic>> getSavedProducts({int page = 1}) async {
    final response = await _dio.get(
      '/marketplace/saved',
      queryParameters: {'page': page},
    );
    final data = response.data;

    final products = (data['data'] as List)
        .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    return {
      'products': products,
      'nextPageUrl': data['next_page_url'],
      'currentPage': data['current_page'],
      'lastPage': data['last_page'],
      'total': data['total'],
    };
  }

  /// Get seller shop details, categories, products, and reviews.
  Future<Map<String, dynamic>> getSellerShop(String username, {int? categoryId, String? query, int page = 1}) async {
    final params = <String, dynamic>{'page': page};
    if (categoryId != null) params['category_id'] = categoryId;
    if (query != null && query.isNotEmpty) params['q'] = query;

    final response = await _dio.get(
      '/marketplace/shop/$username',
      queryParameters: params,
    );
    return response.data;
  }

  /// Get paginated seller shops.
  Future<Map<String, dynamic>> getSellerShops({int page = 1, String? query}) async {
    final params = <String, dynamic>{'page': page};
    if (query != null && query.isNotEmpty) params['q'] = query;

    final response = await _dio.get(
      '/marketplace/shops',
      queryParameters: params,
    );
    final data = response.data;

    return {
      'shops': data['data'] ?? [],
      'nextPageUrl': data['next_page_url'],
      'currentPage': data['current_page'],
      'lastPage': data['last_page'],
      'total': data['total'],
    };
  }

  /// Submit a seller review.
  Future<void> submitSellerReview(String username, int rating, String? review, {List<File>? images}) async {
    if (images != null && images.isNotEmpty) {
      final formData = FormData.fromMap({
        'rating': rating,
        'review': review ?? '',
      });
      for (var file in images) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(file.path),
        ));
      }
      await _dio.post(
        '/marketplace/shop/$username/review',
        data: formData,
      );
    } else {
      await _dio.post(
        '/marketplace/shop/$username/review',
        data: {
          'rating': rating,
          'review': review,
        },
      );
    }
  }

  /// Report an advertisement campaign.
  Future<void> reportAd(int adId, String reason, {String? details}) async {
    await _dio.post(
      '/ads/$adId/report',
      data: {
        'reason': reason,
        'details': details,
      },
    );
  }

  /// Get comments for a product listing.
  Future<List<ProductCommentModel>> getProductComments(int productId) async {
    final response = await _dio.get('/marketplace/products/$productId/comments');
    if (response.data != null && response.data['data'] != null) {
      final list = response.data['data'] as List;
      return list.map((item) => ProductCommentModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  /// Submit a comment or reply on a product listing.
  Future<void> submitProductComment(int productId, String? content, {int? parentId, File? image}) async {
    final payload = <String, dynamic>{
      'content': content ?? '',
    };
    if (parentId != null) {
      payload['parent_id'] = parentId;
    }

    if (image != null) {
      final formData = FormData.fromMap(payload);
      formData.files.add(MapEntry(
        'media',
        await MultipartFile.fromFile(image.path),
      ));
      await _dio.post(
        '/marketplace/products/$productId/comments',
        data: formData,
      );
    } else {
      await _dio.post(
        '/marketplace/products/$productId/comments',
        data: payload,
      );
    }
  }
}
