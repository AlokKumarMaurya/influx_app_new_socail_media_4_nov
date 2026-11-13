import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import '../../controllers/extra_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/feed/post_card.dart';
import '../../widgets/marketplace/product_card.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExtraController controller = Get.put(ExtraController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller.fetchSavedPosts(refresh: true);
    controller.fetchSavedProducts(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('saved_items'.tr, style: AppTextStyles.h2),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'posts'.tr),
            Tab(text: 'marketplace'.tr),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedPosts(),
          _buildSavedProducts(),
        ],
      ),
    );
  }

  Widget _buildSavedPosts() {
    return Obx(() {
      if (controller.savedPostsLoading.value && controller.savedPosts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.savedPosts.isEmpty) {
        return _buildEmptyState('no_saved_posts'.tr, 'save_posts_to_view_desc'.tr);
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchSavedPosts(refresh: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              controller.fetchSavedPosts();
            }
            return true;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: controller.hasMoreSavedPosts.value 
                ? controller.savedPosts.length + 1 
                : controller.savedPosts.length,
            itemBuilder: (context, index) {
              if (index == controller.savedPosts.length) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ));
              }
              return PostCard(post: controller.savedPosts[index]);
            },
          ),
        ),
      );
    });
  }

  Widget _buildSavedProducts() {
    return Obx(() {
      if (controller.savedProductsLoading.value && controller.savedProducts.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.savedProducts.isEmpty) {
        return _buildEmptyState('no_saved_products'.tr, 'save_products_to_view_desc'.tr);
      }
      return RefreshIndicator(
        onRefresh: () => controller.fetchSavedProducts(refresh: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              controller.fetchSavedProducts();
            }
            return true;
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: controller.hasMoreSavedProducts.value 
                ? controller.savedProducts.length + 1 
                : controller.savedProducts.length,
            itemBuilder: (context, index) {
              if (index == controller.savedProducts.length) {
                return const Center(child: CircularProgressIndicator());
              }
              return ProductCard(product: controller.savedProducts[index]);
            },
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
