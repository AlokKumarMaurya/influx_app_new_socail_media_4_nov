import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../models/mall_product_model.dart';

class MallProductsService {
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.mallBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
        'app-type': 'customer',
        'lang': 'en',
        if (AppConfig.mallApiKey.isNotEmpty)
          'x-api-key': AppConfig.mallApiKey,
      },
    ),
  );

  Future<MallProductsPage> getProducts({int page = 1}) async {
    final response = await _dio.get('/products', queryParameters: {'page': page});
    final payload = Map<String, dynamic>.from(response.data as Map);
    final rows = payload['data'] is List ? payload['data'] as List : const [];

    return MallProductsPage(
      products: rows
          .whereType<Map>()
          .map((item) => MallProductModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      currentPage: _int(payload['current_page'], page),
      lastPage: _int(payload['last_page'], page),
      total: _int(payload['total'], rows.length),
      nextPageUrl: payload['next_page_url']?.toString(),
    );
  }

  static int _int(dynamic value, int fallback) =>
      int.tryParse(value?.toString() ?? '') ?? fallback;
}

class MallProductsPage {
  final List<MallProductModel> products;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? nextPageUrl;

  const MallProductsPage({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.nextPageUrl,
  });

  bool get hasMore => nextPageUrl != null && currentPage < lastPage;
}