import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../controllers/blogs_controller.dart';
import '../../data/models/blog_model.dart';
import '../../utils/app_theme.dart';
import '../user/profile_page.dart';

class BlogDetailPage extends StatefulWidget {
  final String slug;
  const BlogDetailPage({super.key, required this.slug});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late final BlogsController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<BlogsController>()) {
      controller = Get.find<BlogsController>();
    } else {
      controller = Get.put(BlogsController());
    }
    controller.loadBlog(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final blog = controller.currentBlog.value;
        if (blog == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text('blog_not_found'.tr, style: AppTextStyles.h3),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Get.back(), child: Text('go_back'.tr)),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // Header with cover image
            _buildHeader(blog),

            // Body content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta info
                    Row(
                      children: [
                        if (blog.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(blog.category!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1))),
                          ),
                        const Spacer(),
                        Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('${blog.readingTime} ${'min_read'.tr}',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        Icon(Icons.visibility, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text('${blog.viewsCount} ${'views'.tr}',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Content
                    HtmlWidget(
                      blog.content ?? '',
                      textStyle: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tags
                    if (blog.tags != null && blog.tags!.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: blog.tags!.split(',').map((tag) {
                          return Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(tag.trim(),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Divider
                    Divider(color: AppColors.textSecondary.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),

                    // Author card
                    _buildAuthorCard(blog),
                    const SizedBox(height: 24),

                    // Related Articles
                    if (controller.relatedBlogs.isNotEmpty) ...[
                      Text('related_articles'.tr,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain)),
                      const SizedBox(height: 12),
                      ...controller.relatedBlogs.map((related) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RelatedBlogItem(blog: related),
                          )),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BlogModel blog) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.cardBg,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (blog.featuredImage != null)
              Image.network(blog.featuredImage!, fit: BoxFit.cover,
                  errorBuilder: (_, i1, i2) => _gradientPlaceholder()),
            if (blog.featuredImage == null) _gradientPlaceholder(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (blog.author?.avatar != null)
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(blog.author!.avatar!),
                        ),
                      const SizedBox(width: 8),
                      Text(blog.author?.name ?? 'Author',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      if (blog.author?.profileType == 'creator' ||
                          blog.author?.profileType == 'business') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                      ],
                      const Spacer(),
                      Text(blog.publishedAtFormatted ?? '',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildAuthorCard(BlogModel blog) {
    if (blog.author == null) return const SizedBox();

    return GestureDetector(
      onTap: () => Get.to(() => ProfilePage(userId: blog.author!.id)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.isDark
              ? Colors.white.withValues(alpha: 0.03)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: blog.author?.avatar != null
                  ? NetworkImage(blog.author!.avatar!)
                  : null,
              child: blog.author?.avatar == null
                  ? Icon(Icons.person, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(blog.author!.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textMain)),
                  Text(blog.author?.bio ?? 'Content writer on this platform',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text('view_profile'.tr,
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Related Blog Item ──────────────────

class _RelatedBlogItem extends StatelessWidget {
  final BlogModel blog;
  const _RelatedBlogItem({required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.off(() => BlogDetailPage(slug: blog.slug)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 90,
                height: 80,
                child: blog.featuredImage != null
                    ? Image.network(blog.featuredImage!, fit: BoxFit.cover,
                        errorBuilder: (_, i1, i2) => _ph())
                    : _ph(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(blog.title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${blog.author?.name ?? 'author'.tr} · ${blog.readingTime} ${'min_read'.tr}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ph() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)]),
      ),
      child: Center(child: Icon(Icons.article, size: 24, color: Colors.grey.shade400)),
    );
  }
}
