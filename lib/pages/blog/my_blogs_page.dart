import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/blogs_controller.dart';
import '../../data/models/blog_model.dart';
import '../../utils/app_theme.dart';
import 'create_blog_page.dart';
import 'blog_detail_page.dart';

class MyBlogsPage extends StatefulWidget {
  const MyBlogsPage({super.key});

  @override
  State<MyBlogsPage> createState() => _MyBlogsPageState();
}

class _MyBlogsPageState extends State<MyBlogsPage> {
  late final BlogsController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BlogsController>()) {
      controller = Get.find<BlogsController>();
    } else {
      controller = Get.put(BlogsController());
    }
    controller.loadMyBlogs();
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
          icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.textMain, size: 24),
          onPressed: () => Get.back(),
        ),
        title: Text('my_blogs'.tr, style: AppTextStyles.h3),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const CreateBlogPage()),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isMyBlogsLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.myBlogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text('no_blogs_yet'.tr, style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text('start_writing_first_blog'.tr, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const CreateBlogPage()),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text('write_a_blog'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              controller.loadMoreMyBlogs();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.myBlogs.length + (controller.isMyBlogsLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.myBlogs.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final blog = controller.myBlogs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MyBlogCard(blog: blog, controller: controller),
              );
            },
          ),
        );
      }),
    );
  }
}

class _MyBlogCard extends StatelessWidget {
  final BlogModel blog;
  final BlogsController controller;

  const _MyBlogCard({required this.blog, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (blog.featuredImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(blog.featuredImage!, fit: BoxFit.cover,
                    errorBuilder: (_, i1, i2) => const SizedBox()),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + Category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: blog.status == 'published'
                            ? AppColors.success.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        blog.status == 'published' ? 'published'.tr : 'draft'.tr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: blog.status == 'published'
                              ? AppColors.success
                              : Colors.orange,
                        ),
                      ),
                    ),
                    if (blog.category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(blog.category!,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6366F1))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  blog.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Stats + Actions
                Row(
                  children: [
                    Icon(Icons.visibility, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text('${blog.viewsCount}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text('${blog.readingTime} min',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Text(blog.publishedAtHuman ?? 'draft'.tr,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const Spacer(),
                    // Edit
                    GestureDetector(
                      onTap: () => Get.to(() => CreateBlogPage(editBlog: blog)),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, size: 14, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // View
                    if (blog.status == 'published')
                      GestureDetector(
                        onTap: () => Get.to(() => BlogDetailPage(slug: blog.slug)),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.open_in_new, size: 14, color: AppColors.success),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Delete
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('delete_blog'.tr, style: TextStyle(color: AppColors.textMain)),
        content: Text('delete_blog_confirmation'.tr,
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteBlog(blog.id);
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
