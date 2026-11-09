import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/marketplace_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_comment_model.dart';
import '../../data/services/marketplace_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/chat/image_lightbox.dart';
import '../../widgets/marketplace/product_card.dart';
import '../../widgets/common/hashtag_text.dart';
import 'seller_shop_page.dart';
import 'create_listing_page.dart';
import '../user/profile_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final MarketplaceController controller;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  final MarketplaceService _marketplaceService = MarketplaceService();
  List<ProductCommentModel> _productComments = [];
  bool _isLoadingComments = false;
  File? _commentImageFile;
  final TextEditingController _mainCommentController = TextEditingController();
  final Map<int, TextEditingController> _replyControllers = {};
  final Map<int, File?> _replyImageFiles = {};
  int? _activeReplyCommentId;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MarketplaceController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProductDetail(widget.productId);
      _loadProductComments();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mainCommentController.dispose();
    for (var c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProductComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _marketplaceService.getProductComments(widget.productId);
      if (mounted) {
        setState(() {
          _productComments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _pickCommentImage({int? replyCommentId}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (replyCommentId != null) {
          _replyImageFiles[replyCommentId] = File(picked.path);
        } else {
          _commentImageFile = File(picked.path);
        }
      });
    }
  }

  Future<void> _submitProductComment({int? parentId}) async {
    final textController = parentId != null
        ? (_replyControllers[parentId] ?? TextEditingController())
        : _mainCommentController;
    final imageFile = parentId != null ? _replyImageFiles[parentId] : _commentImageFile;
    final text = textController.text.trim();

    if (text.isEmpty && imageFile == null) {
      Get.snackbar('error'.tr, 'comment_cannot_be_empty'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      await _marketplaceService.submitProductComment(
        widget.productId,
        text.isNotEmpty ? text : null,
        parentId: parentId,
        image: imageFile,
      );

      textController.clear();
      setState(() {
        if (parentId != null) {
          _replyImageFiles.remove(parentId);
          _activeReplyCommentId = null;
        } else {
          _commentImageFile = null;
        }
      });

      _loadProductComments();
      Get.snackbar('success'.tr, 'comment_posted'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('error'.tr, 'failed_post_comment'.tr, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _messageSeller(ProductModel product) async {
    if (product.seller == null) return;

    final greeting =
        'Hi, I\'m interested in your "${product.title}" listed for ${product.formattedPrice}. Is it still available?';

    try {
      final ChatController chatController = Get.put(ChatController());
      await chatController.startConversationAndSendGreeting(
        product.seller!.id,
        greeting,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not initate chat.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.cardBg,
        colorText: AppColors.textMain,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoadingDetail.value) {
          return _buildLoading();
        }

        final product = controller.selectedProduct.value;
        if (product == null) {
          return _buildError();
        }

        return CustomScrollView(
          slivers: [
            // Image Gallery
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.height * 0.45,
              pinned: true,
              backgroundColor: AppColors.cardBg,
              leading: _buildBackButton(),
              actions: [
                _buildSaveButton(product),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildImageGallery(product),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      _buildBadges(product),
                      const SizedBox(height: 16),

                      // Title
                      HashtagText(
                        text: product.title,
                        contextType: HashtagContext.product,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Price
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seller Card
                      if (product.seller != null) _buildSellerCard(product),
                      const SizedBox(height: 24),

                      // Description
                      _buildSection(
                        icon: Icons.description_outlined,
                        title: 'description'.tr,
                        child: HashtagText(
                          text: product.description ?? 'no_description'.tr,
                          contextType: HashtagContext.product,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Specifications
                      if (product.customFieldsData.isNotEmpty)
                        _buildSpecificationsSection(product),

                      // Location
                      _buildLocationSection(product),
                      const SizedBox(height: 24),

                      // Related Products
                      if (controller.relatedProducts.isNotEmpty) ...[
                        _buildRelatedProducts(),
                        const SizedBox(height: 24),
                      ],

                      // Product Comments & Replies Section (Positioned at Very End)
                      _buildProductCommentsSection(product),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final product = controller.selectedProduct.value;
        if (product == null) return const SizedBox.shrink();
        return _buildBottomBar(product);
      }),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Get.back(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  Widget _buildSaveButton(ProductModel product) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            product.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: product.isSaved ? AppColors.primary : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => controller.toggleSave(product.id),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  Widget _buildImageGallery(ProductModel product) {
    final images = product.media.isNotEmpty
        ? product.media.map((m) => m.fileUrl).toList()
        : [product.primaryImageUrl ?? ''];

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentImageIndex = i),
          itemCount: images.length,
          itemBuilder: (_, index) {
            final url = images[index];
            if (url.isEmpty) {
              return Container(
                color: AppColors.isDark ? Colors.grey[800] : Colors.grey[200],
                child: Center(
                  child: Icon(Icons.image_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.3)),
                ),
              );
            }
            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, index) => Container(
                color: AppColors.isDark ? Colors.grey[800] : Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, i1, i2) => Container(
                color: AppColors.isDark ? Colors.grey[800] : Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, size: 48)),
              ),
            );
          },
        ),
        // Page indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentImageIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentImageIndex
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildBadges(ProductModel product) {
    final catLabel = product.category?.path ?? product.category?.name;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (catLabel != null && catLabel.isNotEmpty)
          _buildBadgeChip(catLabel, Icons.category_outlined),
        _buildBadgeChip(product.conditionLabel, Icons.verified_outlined),
      ],
    );
  }

  Widget _buildBadgeChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerCard(ProductModel product) {
    final seller = product.seller!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => ProfilePage(userId: seller.id)),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: seller.avatarUrl != null
                            ? CachedNetworkImageProvider(seller.avatarUrl!)
                            : null,
                        child: seller.avatarUrl == null
                            ? Icon(Icons.person, color: AppColors.primary)
                            : null,
                      ),
                      if (seller.isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBg, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Joined ${_formatDate(seller.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.to(() => SellerShopPage(
                    username: (seller.username != null && seller.username!.isNotEmpty)
                        ? seller.username!
                        : seller.id.toString(),
                  ));
            },
            icon: const Icon(Icons.storefront_rounded, size: 14),
            label: Text('shop'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSpecificationsSection(ProductModel product) {
    final fields = product.customFieldsData;
    if (fields.isEmpty) return const SizedBox.shrink();

    final entries = fields.entries.where((e) {
      if (e.value == null) return false;
      if (e.value is String && (e.value as String).trim().isEmpty) return false;
      if (e.value is List && (e.value as List).isEmpty) return false;
      return true;
    }).toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          icon: Icons.tune_rounded,
          title: 'item_specifications_details'.tr,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.isDark ? Colors.white12 : Colors.grey[200]!,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.isDark ? Colors.white12 : Colors.grey[200]!,
              ),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final keyLabel = entry.key
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((word) => word.isNotEmpty
                        ? '${word[0].toUpperCase()}${word.substring(1)}'
                        : '')
                    .join(' ');

                String displayValue;
                if (entry.value is List) {
                  displayValue = (entry.value as List).join(', ');
                } else {
                  displayValue = entry.value.toString();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          keyLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          displayValue,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLocationSection(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 20, color: Colors.red[400]),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.location ??
                'Available for nationwide shipping or local pickup.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Always meet in a public, well-lit place.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You might also like',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.relatedProducts.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final related = controller.relatedProducts[index];
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: related,
                  onTap: () {
                    Get.to(() => ProductDetailPage(productId: related.id), preventDuplicates: false);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCommentsSection(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mode_comment_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'product_qa_comments'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_productComments.length} ${'comments'.tr}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Comment Input Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _mainCommentController,
                  maxLines: 2,
                  style: TextStyle(fontSize: 14, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'ask_question_or_comment'.tr,
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: AppColors.isDark ? Colors.white10 : Colors.white,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add_a_photo_outlined, color: _commentImageFile != null ? AppColors.primary : Colors.grey),
                onPressed: () => _pickCommentImage(),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                onPressed: () => _submitProductComment(),
              ),
            ],
          ),
          if (_commentImageFile != null) ...[
            const SizedBox(height: 8),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _commentImageFile!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _commentImageFile = null),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Comments List
          if (_isLoadingComments)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
          else if (_productComments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No questions or comments yet. Be the first to ask!',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _productComments.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 24),
              itemBuilder: (ctx, idx) {
                final cmt = _productComments[idx];
                return _buildCommentItem(cmt);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(ProductCommentModel cmt, {bool isReply = false}) {
    final hasImage = cmt.imageUrl != null && cmt.imageUrl!.isNotEmpty;
    if (!_replyControllers.containsKey(cmt.id)) {
      _replyControllers[cmt.id] = TextEditingController();
    }
    final isReplying = _activeReplyCommentId == cmt.id;

    return Container(
      margin: EdgeInsets.only(left: isReply ? 24 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: cmt.userAvatar != null ? CachedNetworkImageProvider(cmt.userAvatar!) : null,
                child: cmt.userAvatar == null ? Icon(Icons.person, size: isReply ? 14 : 18, color: AppColors.primary) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cmt.userName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${cmt.createdAt.day}/${cmt.createdAt.month}/${cmt.createdAt.year}',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (cmt.content != null && cmt.content!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        HashtagText(
                          text: cmt.content!,
                          contextType: HashtagContext.product,
                          style: TextStyle(fontSize: 13, color: AppColors.textMain),
                        ),
                      ],
                      if (hasImage) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => ImageLightbox.show(context, cmt.imageUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 120, maxWidth: 180),
                              child: Image.network(
                                cmt.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!isReply) ...[
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 4),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _activeReplyCommentId = isReplying ? null : cmt.id;
                  });
                },
                icon: const Icon(Icons.subdirectory_arrow_right, size: 14),
                label: Text(isReplying ? 'Cancel' : 'Reply', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ),
            if (isReplying) ...[
              Padding(
                padding: const EdgeInsets.only(left: 46, top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyControllers[cmt.id],
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'write_a_reply'.tr,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: AppColors.isDark ? Colors.white10 : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_a_photo_outlined, size: 18, color: _replyImageFiles[cmt.id] != null ? AppColors.primary : Colors.grey),
                      onPressed: () => _pickCommentImage(replyCommentId: cmt.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                      onPressed: () => _submitProductComment(parentId: cmt.id),
                    ),
                  ],
                ),
              ),
              if (_replyImageFiles[cmt.id] != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 46, top: 6),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(_replyImageFiles[cmt.id]!, width: 50, height: 50, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 1,
                        right: 1,
                        child: GestureDetector(
                          onTap: () => setState(() => _replyImageFiles.remove(cmt.id)),
                          child: Container(padding: const EdgeInsets.all(1), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (cmt.replies.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...cmt.replies.map((reply) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildCommentItem(reply, isReply: true),
              )),
            ],
          ],
        ],
      ),
    );
  }

  void _confirmDelete(int productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'delete_listing'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        content: Text(
          'delete_listing_confirmation'.tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.deleteListing(productId);
              if (success) {
                Get.back();
                Get.snackbar('done'.tr, 'listing_deleted'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white);
              } else {
                Get.snackbar('error'.tr, 'failed_delete_listing'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red[400],
                    colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final isOwner = authController?.user.value?.id == product.seller?.id ||
        (authController?.user.value?.id != null && authController?.user.value?.id == product.userId);

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isOwner) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.to(() => CreateListingPage(product: product));
                },
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: Text(
                  'edit_listing'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () => _confirmDelete(product.id),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _messageSeller(product),
                icon: const Icon(Icons.message_outlined, size: 20),
                label: Text(
                  'message_seller'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.isDark ? Colors.white24 : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: () => controller.toggleSave(product.id),
                icon: Icon(
                  product.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: product.isSaved
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'product_not_found'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('go_back'.tr),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
