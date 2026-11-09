import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/marketplace_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../data/models/category_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/marketplace/product_card.dart';
import '../../widgets/marketplace/category_chips.dart';
import '../../widgets/marketplace/marketplace_filter_sheet.dart';
import 'product_detail_page.dart';
import 'create_listing_page.dart';
import 'my_listings_page.dart';
import 'saved_products_page.dart';
import 'seller_shops_page.dart';

class MarketplacePage extends StatefulWidget {
  final String? initialSearchQuery;
  const MarketplacePage({super.key, this.initialSearchQuery});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final MarketplaceController controller = Get.put(MarketplaceController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      _showSearch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setSearchQuery(widget.initialSearchQuery!);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.loadMoreProducts();
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarketplaceFilterSheet(
        initialMinPrice: controller.minPrice.value,
        initialMaxPrice: controller.maxPrice.value,
        initialCondition: controller.selectedCondition.value,
        initialLocation: controller.locationFilter.value,
        initialUsername: controller.usernameFilter.value,
        onApply: (min, max, condition, loc, user) {
          controller.setAdvancedFilters(
            min: min,
            max: max,
            condition: condition,
            location: loc,
            username: user,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textMain,
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: _showSearch
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 42,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) {
                          controller.setSearchQuery(val);
                          setState(() {});
                        },
                        style: TextStyle(fontSize: 14, color: AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: 'search_marketplace_hint'.tr,
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          controller.setSearchQuery('');
                          setState(() {});
                        },
                        child: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                      ),
                  ],
                ),
              )
            : Text(
                'marketplace'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
        actions: _showSearch
            ? [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSearch = false;
                      _searchController.clear();
                      controller.setSearchQuery('');
                    });
                  },
                  child: Text(
                    'cancel'.tr,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : [
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: AppColors.textMain,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSearch = true;
                    });
                  },
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFilterHorizontal,
                    color: AppColors.textMain,
                    size: 20,
                  ),
                  onPressed: _showFilters,
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: AppColors.textMain,
                    size: 20,
                  ),
                  tooltip: 'seller_shops'.tr,
                  onPressed: () => Get.to(() => const SellerShopsPage()),
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedBookmark01,
                    color: AppColors.textMain,
                    size: 20,
                  ),
                  onPressed: () => Get.to(() => const SavedProductsPage()),
                ),
                TextButton.icon(
                  onPressed: () => Get.to(() => const MyListingsPage()),
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedDashboardSquare01,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  label: Text(
                    'my_listings'.tr,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
      ),
      body: Obx(() {
        return Column(
          children: [
            // Category chips
            if (controller.categories.isNotEmpty)
              Container(
                color: AppColors.cardBg,
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: CategoryChips(
                  categories: controller.categories,
                  selectedCategoryId: controller.selectedCategoryId.value,
                  onCategorySelected: (id) {
                    CategoryModel? cat;
                    if (id != null) {
                      cat = CategoryModel.flattenTree(controller.categories)
                          .firstWhereOrNull((c) => c.id == id);
                    }
                    controller.selectCategory(id, cat?.name);
                  },
                ),
              ),

            // Active filters bar
            if (controller.hasActiveFilters)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Row(
                  children: [
                    Icon(Icons.filter_list,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildFilterSummary(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        controller.clearFilters();
                        _searchController.clear();
                      },
                      child: Text(
                        'clear_all'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Products grid
            Expanded(
              child: controller.isLoading.value
                  ? _buildLoadingGrid()
                  : controller.products.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: controller.refreshProducts,
                          color: AppColors.primary,
                          child: GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: controller.products.length +
                                (controller.isLoadingMore.value ? 2 : 0),
                            itemBuilder: (context, index) {
                              if (index >= controller.products.length) {
                                return _buildLoadingCard();
                              }
                              final product = controller.products[index];
                              return ProductCard(
                                product: product,
                                onTap: () => Get.to(
                                  () => ProductDetailPage(
                                      productId: product.id),
                                ),
                                onSave: () =>
                                    controller.toggleSave(product.id),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const CreateListingPage()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'sell'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (controller.selectedCategoryName.value != null) {
      parts.add(controller.selectedCategoryName.value!);
    }
    if (controller.searchQuery.value.isNotEmpty) {
      parts.add('"${controller.searchQuery.value}"');
    }
    if (controller.locationFilter.value != null && controller.locationFilter.value!.isNotEmpty) {
      parts.add('📍 ${controller.locationFilter.value}');
    }
    if (controller.usernameFilter.value != null && controller.usernameFilter.value!.isNotEmpty) {
      parts.add('👤 ${controller.usernameFilter.value}');
    }
    if (controller.minPrice.value != null ||
        controller.maxPrice.value != null) {
      final sym = Get.isRegistered<SettingsController>()
          ? Get.find<SettingsController>().currencySymbol.value
          : '\$';
      final min = controller.minPrice.value?.toStringAsFixed(0) ?? '0';
      final max = controller.maxPrice.value?.toStringAsFixed(0) ?? '∞';
      parts.add('$sym$min - $sym$max');
    }
    if (controller.selectedCondition.value != null) {
      parts.add(controller.selectedCondition.value!
          .replaceAll('_', ' ')
          .capitalize!);
    }
    return parts.join(' · ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'no_matches_found'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'try_different_keywords'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              controller.clearFilters();
              _searchController.clear();
            },
            child: Text(
              'clear_all_filters'.tr,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, index) => _buildLoadingCard(),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.primary.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppColors.isDark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.isDark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
