import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mall_products_controller.dart';
import '../../data/models/mall_product_model.dart';
import '../../utils/app_theme.dart';

class MallProductsPage extends StatefulWidget {
  const MallProductsPage({super.key});

  @override
  State<MallProductsPage> createState() => _MallProductsPageState();
}

class _MallProductsPageState extends State<MallProductsPage> {
  late final MallProductsController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(MallProductsController());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (Get.isRegistered<MallProductsController>()) {
      Get.delete<MallProductsController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value && controller.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.products.isEmpty && controller.errorMessage.isNotEmpty) {
          return _MessageState(
            message: controller.errorMessage.value,
            actionLabel: 'Retry',
            onAction: controller.refresh,
          );
        }
        if (controller.products.isEmpty) {
          return const _MessageState(message: 'No products found.');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 268,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MallProductCard(
                      product: controller.products[index],
                    ),
                    childCount: controller.products.length,
                  ),
                ),
              ),
              if (controller.isLoadingMore.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (controller.errorMessage.isNotEmpty &&
                  controller.products.isNotEmpty)
                SliverToBoxAdapter(
                  child: TextButton(
                    onPressed: controller.loadMore,
                    child: Text(controller.errorMessage.value),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      }),
    );
  }
}

class _MallProductCard extends StatelessWidget {
  const _MallProductCard({required this.product});
  final MallProductModel product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFFF0F4F8),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(5),
                  child: product.imageUrl.isEmpty
                      ? const Icon(Icons.image_outlined,
                          size: 42, color: Colors.black26)
                      : CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            size: 42,
                            color: Colors.black26,
                          ),
                        ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: const Color(0xFF2675D8),
                    size: 27,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (product.originalPrice != null &&
                    product.originalPrice! > product.price) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${product.originalPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
