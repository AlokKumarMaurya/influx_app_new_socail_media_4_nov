import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/services/marketplace_service.dart';

class MarketplaceController extends GetxController {
  final MarketplaceService _service = MarketplaceService();

  // ─── Observable State ──────────────────
  final products = <ProductModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final myListings = <ProductModel>[].obs;
  final savedProducts = <ProductModel>[].obs;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final isLoadingDetail = false.obs;
  final isCreating = false.obs;
  final isLoadingMyListings = false.obs;
  final isLoadingSavedProducts = false.obs;

  // ─── Product Detail ──────────────────
  final selectedProduct = Rx<ProductModel?>(null);
  final relatedProducts = <ProductModel>[].obs;

  // ─── Filters ──────────────────
  final selectedCategoryId = Rx<int?>(null);
  final selectedCategoryName = Rx<String?>(null);
  final searchQuery = ''.obs;
  final minPrice = Rx<double?>(null);
  final maxPrice = Rx<double?>(null);
  final selectedCondition = Rx<String?>(null);
  final locationFilter = Rx<String?>(null);
  final usernameFilter = Rx<String?>(null);

  // ─── Pagination ──────────────────
  int _currentPage = 1;
  bool _hasMorePages = true;
  int _myListingsPage = 1;
  bool _hasMoreMyListings = true;
  int _savedProductsPage = 1;
  bool _hasMoreSavedProducts = true;

  // ─── Search Debounce ──────────────────
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadProducts();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  // ────────────────────────────────────────
  // Categories
  // ────────────────────────────────────────

  Future<void> loadCategories() async {
    try {
      final result = await _service.getCategories();
      categories.assignAll(result);
    } catch (e) {
      Get.log('Failed to load categories: $e');
    }
  }

  // ────────────────────────────────────────
  // Products - Browse
  // ────────────────────────────────────────

  Future<void> loadProducts() async {
    isLoading.value = true;
    _currentPage = 1;
    _hasMorePages = true;

    try {
      final result = await _service.getProducts(
        page: 1,
        categoryId: selectedCategoryId.value,
        query: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        condition: selectedCondition.value,
        location: locationFilter.value,
        username: usernameFilter.value,
      );
      products.assignAll(result['products'] as List<ProductModel>);
      _currentPage = result['currentPage'] as int;
      _hasMorePages = result['nextPageUrl'] != null;
    } catch (e) {
      Get.log('Failed to load products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !_hasMorePages) return;
    isLoadingMore.value = true;

    try {
      final result = await _service.getProducts(
        page: _currentPage + 1,
        categoryId: selectedCategoryId.value,
        query: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        condition: selectedCondition.value,
        location: locationFilter.value,
        username: usernameFilter.value,
      );
      products.addAll(result['products'] as List<ProductModel>);
      _currentPage = result['currentPage'] as int;
      _hasMorePages = result['nextPageUrl'] != null;
    } catch (e) {
      Get.log('Load more products error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // ────────────────────────────────────────
  // Filters
  // ────────────────────────────────────────

  void selectCategory(int? categoryId, String? categoryName) {
    selectedCategoryId.value = categoryId;
    selectedCategoryName.value = categoryName;
    loadProducts();
  }

  void setSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = query;
      loadProducts();
    });
  }

  void setAdvancedFilters({double? min, double? max, String? condition, String? location, String? username}) {
    minPrice.value = min;
    maxPrice.value = max;
    selectedCondition.value = condition;
    locationFilter.value = location;
    usernameFilter.value = username;
    loadProducts();
  }

  void clearFilters() {
    selectedCategoryId.value = null;
    selectedCategoryName.value = null;
    searchQuery.value = '';
    minPrice.value = null;
    maxPrice.value = null;
    selectedCondition.value = null;
    loadProducts();
  }

  bool get hasActiveFilters =>
      selectedCategoryId.value != null ||
      searchQuery.value.isNotEmpty ||
      minPrice.value != null ||
      maxPrice.value != null ||
      selectedCondition.value != null;

  // ────────────────────────────────────────
  // Product Detail
  // ────────────────────────────────────────

  Future<void> loadProductDetail(int productId) async {
    isLoadingDetail.value = true;
    selectedProduct.value = null;
    relatedProducts.clear();

    try {
      final result = await _service.getProductDetail(productId);
      selectedProduct.value = result['product'] as ProductModel;
      relatedProducts
          .assignAll(result['relatedProducts'] as List<ProductModel>);
    } catch (e) {
      Get.log('Failed to load product detail: $e');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ────────────────────────────────────────
  // Save / Unsave
  // ────────────────────────────────────────

  Future<void> toggleSave(int productId) async {
    // Optimistic toggle in products list
    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      products[index] =
          products[index].copyWith(isSaved: !products[index].isSaved);
    }

    // Optimistic toggle in detail view
    if (selectedProduct.value?.id == productId) {
      selectedProduct.value =
          selectedProduct.value!.copyWith(isSaved: !selectedProduct.value!.isSaved);
    }

    // Optimistic toggle in saved list
    final savedIndex = savedProducts.indexWhere((p) => p.id == productId);
    if (savedIndex != -1) {
      savedProducts.removeAt(savedIndex);
    } else if (selectedProduct.value?.id == productId) {
        if(selectedProduct.value!.isSaved) savedProducts.insert(0, selectedProduct.value!);
    } else if (index != -1){
        if(products[index].isSaved) savedProducts.insert(0, products[index]);
    }

    try {
      await _service.toggleSave(productId);
    } catch (e) {
      // Revert on failure
      if (index != -1) {
        products[index] =
            products[index].copyWith(isSaved: !products[index].isSaved);
      }
      if (selectedProduct.value?.id == productId) {
        selectedProduct.value = selectedProduct.value!
            .copyWith(isSaved: !selectedProduct.value!.isSaved);
      }
    }
  }

  // ────────────────────────────────────────
  // Create / Update / Delete
  // ────────────────────────────────────────

  Future<ProductModel?> createListing({
    required String title,
    required String description,
    required double price,
    required int categoryId,
    required String condition,
    String? location,
    Map<String, dynamic>? customFields,
    List<File>? images,
  }) async {
    isCreating.value = true;
    try {
      final result = await _service.createProduct(
        title: title,
        description: description,
        price: price,
        categoryId: categoryId,
        condition: condition,
        location: location,
        customFields: customFields,
        images: images,
      );
      if (result['success'] == true && result['data'] != null) {
        final product = ProductModel.fromJson(
            Map<String, dynamic>.from(result['data']));
        products.insert(0, product);
        return product;
      }
    } catch (e) {
      Get.log('Failed to create listing: $e');
      rethrow;
    } finally {
      isCreating.value = false;
    }
    return null;
  }

  Future<bool> updateListing(
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
    try {
      final result = await _service.updateProduct(
        productId,
        title: title,
        description: description,
        price: price,
        categoryId: categoryId,
        condition: condition,
        location: location,
        status: status,
        customFields: customFields,
        images: images,
      );
      if (result['success'] == true) {
        // Refresh my listings
        loadMyListings();
        return true;
      }
    } catch (e) {
      Get.log('Failed to update listing: $e');
    }
    return false;
  }

  Future<bool> deleteListing(int productId) async {
    try {
      final success = await _service.deleteProduct(productId);
      if (success) {
        products.removeWhere((p) => p.id == productId);
        myListings.removeWhere((p) => p.id == productId);
        return true;
      }
    } catch (e) {
      Get.log('Failed to delete listing: $e');
    }
    return false;
  }

  // ────────────────────────────────────────
  // My Listings
  // ────────────────────────────────────────

  Future<void> loadMyListings() async {
    isLoadingMyListings.value = true;
    _myListingsPage = 1;
    _hasMoreMyListings = true;

    try {
      final result = await _service.getMyListings(page: 1);
      myListings.assignAll(result['products'] as List<ProductModel>);
      _myListingsPage = result['currentPage'] as int;
      _hasMoreMyListings = result['nextPageUrl'] != null;
    } catch (e) {
      Get.log('Failed to load my listings: $e');
    } finally {
      isLoadingMyListings.value = false;
    }
  }

  Future<void> loadMoreMyListings() async {
    if (isLoadingMore.value || !_hasMoreMyListings) return;
    isLoadingMore.value = true;

    try {
      final result =
          await _service.getMyListings(page: _myListingsPage + 1);
      myListings.addAll(result['products'] as List<ProductModel>);
      _myListingsPage = result['currentPage'] as int;
      _hasMoreMyListings = result['nextPageUrl'] != null;
    } catch (e) {
      Get.log('Load more my listings error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ────────────────────────────────────────
  // Saved Products
  // ────────────────────────────────────────

  Future<void> loadSavedProducts() async {
    isLoadingSavedProducts.value = true;
    _savedProductsPage = 1;
    _hasMoreSavedProducts = true;

    try {
      final result = await _service.getSavedProducts(page: 1);
      savedProducts.assignAll(result['products'] as List<ProductModel>);
      _savedProductsPage = result['currentPage'] as int;
      _hasMoreSavedProducts = result['nextPageUrl'] != null;
    } catch (e) {
      Get.log('Failed to load saved products: $e');
    } finally {
      isLoadingSavedProducts.value = false;
    }
  }

  Future<void> loadMoreSavedProducts() async {
    if (isLoadingMore.value || !_hasMoreSavedProducts) return;
    isLoadingMore.value = true;

    try {
      final result =
          await _service.getSavedProducts(page: _savedProductsPage + 1);
      savedProducts.addAll(result['products'] as List<ProductModel>);
      _savedProductsPage = result['currentPage'] as int;
      _hasMoreSavedProducts = result['nextPageUrl'] != null;
    } catch (e) {
      Get.log('Load more saved products error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }
}
