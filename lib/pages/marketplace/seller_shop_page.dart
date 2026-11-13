import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/seller_review_model.dart';
import '../../data/services/marketplace_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/marketplace/product_card.dart';
import 'product_detail_page.dart';
import '../user/profile_page.dart';

class SellerShopPage extends StatefulWidget {
  final String username;

  const SellerShopPage({
    super.key,
    required this.username,
  });

  @override
  State<SellerShopPage> createState() => _SellerShopPageState();
}

class _SellerShopPageState extends State<SellerShopPage> {
  final MarketplaceService _service = MarketplaceService();

  bool _isLoading = true;
  Map<String, dynamic>? _sellerData;
  List<CategoryModel> _sellerCategories = [];
  List<ProductModel> _products = [];
  List<SellerReviewModel> _reviews = [];
  Map<String, dynamic>? _userReview;

  int? _selectedCategoryId;
  int _activeTab = 0; // 0: Products, 1: Reviews

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getSellerShop(
        widget.username,
        categoryId: _selectedCategoryId,
      );
      setState(() {
        _sellerData = Map<String, dynamic>.from(res['seller'] ?? {});
        _sellerCategories = (res['categories'] as List? ?? [])
            .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c)))
            .toList();

        final rawProducts = res['products']['data'] as List? ?? [];
        _products = rawProducts
            .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
            .toList();

        _reviews = (res['reviews'] as List? ?? [])
            .map((r) => SellerReviewModel.fromJson(Map<String, dynamic>.from(r)))
            .toList();

        _userReview = res['user_review'] != null
            ? Map<String, dynamic>.from(res['user_review'])
            : null;
      });
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_to_load_seller_shop'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReviewDialog() {
    int rating = _userReview != null ? (_userReview!['rating'] as int) : 5;
    final reviewController = TextEditingController(
      text: _userReview != null ? (_userReview!['review'] as String?) ?? '' : '',
    );
    List<File> selectedImages = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'rate_review_seller'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating Stars
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () {
                            setModalState(() => rating = starValue);
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14, color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'share_buying_experience'.tr,
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: AppColors.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Photo Attachments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'photo_attachments_optional'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFiles = await picker.pickMultiImage();
                          if (pickedFiles.isNotEmpty) {
                            setModalState(() {
                              selectedImages = pickedFiles.map((f) => File(f.path)).toList();
                            });
                          }
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: Text('add_photos'.tr, style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  if (selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        separatorBuilder: (c, i) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedImages[idx],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedImages.removeAt(idx);
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _service.submitSellerReview(
                            widget.username,
                            rating,
                            reviewController.text.trim(),
                            images: selectedImages,
                          );
                          Navigator.pop(ctx);
                          Get.snackbar('success'.tr, 'review_submitted_successfully'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white);
                          _loadShopData();
                        } catch (e) {
                          Get.snackbar('error'.tr, 'failed_submit_review'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('submit_review'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textMain, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _sellerData != null ? '${_sellerData!['name']}\'s Shop' : 'Seller Shop',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShopData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSellerHeaderCard(),
                    const SizedBox(height: 16),
                    _buildTabSwitcher(),
                    const SizedBox(height: 12),
                    if (_activeTab == 0) ...[
                      if (_sellerCategories.isNotEmpty) _buildSellerCategoryChips(),
                      _buildProductsGrid(),
                    ] else ...[
                      _buildReviewsList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSellerHeaderCard() {
    final name = _sellerData?['name'] ?? 'Seller';
    final username = _sellerData?['username'] ?? '';
    final avatarUrl = _sellerData?['avatar_url'];
    final avgRating = (_sellerData?['average_rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = _sellerData?['review_count'] as int? ?? 0;

    return Container(
      width: double.infinity,
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 36, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.verified, size: 18, color: AppColors.primary),
                      ],
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($reviewCount reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final sellerId = _sellerData?['id'];
                    if (sellerId != null) {
                      Get.to(() => ProfilePage(userId: int.tryParse(sellerId.toString())));
                    }
                  },
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text('visit_profile'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMain,
                    side: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showReviewDialog,
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  label: Text(_userReview != null ? 'edit_review'.tr : 'rate_seller'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _activeTab == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  '${'products'.tr} (${_products.length})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        _activeTab == 0 ? FontWeight.w800 : FontWeight.w500,
                    color: _activeTab == 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _activeTab == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  '${'reviews'.tr} (${_reviews.length})',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        _activeTab == 1 ? FontWeight.w800 : FontWeight.w500,
                    color: _activeTab == 1
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCategoryChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _sellerCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isActive = _selectedCategoryId == null;
            return ChoiceChip(
              label: Text('all_items'.tr),
              selected: isActive,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : AppColors.textMain,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              onSelected: (_) {
                setState(() => _selectedCategoryId = null);
                _loadShopData();
              },
            );
          }
          final cat = _sellerCategories[index - 1];
          final isActive = _selectedCategoryId == cat.id;
          return ChoiceChip(
            label: Text(cat.name),
            selected: isActive,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : AppColors.textMain,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            onSelected: (_) {
              setState(() => _selectedCategoryId = cat.id);
              _loadShopData();
            },
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'no_products_listed_category'.tr,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ProductCard(
          product: product,
          onTap: () => Get.to(() => ProductDetailPage(productId: product.id)),
        );
      },
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.rate_review_outlined,
                  size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'no_buyer_reviews_yet'.tr,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final rev = _reviews[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: rev.buyerAvatar != null
                        ? NetworkImage(rev.buyerAvatar!)
                        : null,
                    child: rev.buyerAvatar == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rev.buyerName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        Text(
                          '${rev.createdAt.day}/${rev.createdAt.month}/${rev.createdAt.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rev.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (rev.review != null && rev.review!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rev.review!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMain,
                  ),
                ),
              ],
              if (rev.images.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: rev.images.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      return GestureDetector(
                        onTap: () {
                          Get.dialog(
                            Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(16),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: InteractiveViewer(
                                      child: Image.network(rev.images[i], fit: BoxFit.contain),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                    onPressed: () => Get.back(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            rev.images[i],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (rev.reply != null && rev.reply!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'seller_reply'.tr}:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rev.reply!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
