import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../data/models/mall_product_model.dart';
import '../data/services/mall_products_service.dart';

class MallProductsController extends GetxController {
  final MallProductsService _service = MallProductsService();
  final products = <MallProductModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    if (isLoading.value) return;
    final hadProducts = products.isNotEmpty;
    isLoading.value = true;
    errorMessage.value = '';
    _currentPage = 1;
    _hasMore = true;
    try {
      final result = await _service.getProducts(page: 1);
      products.assignAll(result.products);
      _currentPage = result.currentPage;
      _hasMore = result.hasMore;
    } catch (error) {
      errorMessage.value = _friendlyError(error);
      if (!hadProducts) products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final result = await _service.getProducts(page: _currentPage + 1);
      products.addAll(result.products);
      _currentPage = result.currentPage;
      _hasMore = result.hasMore;
    } catch (error) {
      errorMessage.value = _friendlyError(error);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refresh() => loadProducts();

  String _friendlyError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        return 'Unable to access the product catalogue. Check the mall API key.';
      }
      if (status != null) return 'Unable to load products (HTTP $status).';
      return 'Unable to connect. Check your internet connection and try again.';
    }
    return 'Something went wrong while loading products.';
  }
}