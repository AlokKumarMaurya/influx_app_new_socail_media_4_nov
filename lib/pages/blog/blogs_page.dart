import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/blogs_controller.dart';
import '../../data/models/blog_model.dart';
import '../../utils/app_theme.dart';
import 'blog_detail_page.dart';
import 'my_blogs_page.dart';
import 'create_blog_page.dart';

class BlogsPage extends StatelessWidget {
  const BlogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BlogsController());

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('blogs'.tr, style: AppTextStyles.h3),
            Text('discover_stories_insights'.tr,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Get.to(() => const MyBlogsPage()),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedMenu01, color: AppColors.primary, size: 16),
            label: Text('my_blogs'.tr, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
          IconButton(
            onPressed: () => Get.to(() => const CreateBlogPage()),
            icon: HugeIcon(icon: HugeIcons.strokeRoundedEdit02, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasContent = controller.heroBlog.value != null ||
            controller.featuredBlogs.isNotEmpty ||
            controller.latestBlogs.isNotEmpty;

        if (!hasContent) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshBlogs,
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                controller.loadMoreLatest();
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  if (controller.heroBlog.value != null) ...[
                    _HeroBlogCard(blog: controller.heroBlog.value!),
                    const SizedBox(height: 16),
                  ],

                  // Featured Grid
                  if (controller.featuredBlogs.isNotEmpty) ...[
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.featuredBlogs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index < controller.featuredBlogs.length - 1 ? 12 : 0,
                            ),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: _FeaturedBlogCard(blog: controller.featuredBlogs[index]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Latest Articles Header
                  if (controller.latestBlogs.isNotEmpty) ...[
                    _SectionHeading(title: 'latest_articles'.tr),
                    const SizedBox(height: 12),
                    ...controller.latestBlogs.map((blog) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _LatestBlogCard(blog: blog),
                        )),
                    if (controller.isLoadingMore.value)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedEdit02,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text('no_blog_posts_yet'.tr, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('be_first_share_thoughts'.tr,
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => const CreateBlogPage()),
            icon: const Icon(Icons.edit, size: 18),
            label: Text('write_your_first_blog'.tr),
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
}

class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            )),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ─── Hero Blog Card ──────────────────

class _HeroBlogCard extends StatelessWidget {
  final BlogModel blog;
  const _HeroBlogCard({required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => BlogDetailPage(slug: blog.slug)),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (blog.featuredImage != null)
              Positioned.fill(
                child: Image.network(
                  blog.featuredImage!,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.6),
                  errorBuilder: (_, i1, i2) => const SizedBox(),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('trending'.tr,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      if (blog.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(blog.category!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    blog.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (blog.excerpt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      blog.excerpt!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (blog.author?.avatar != null)
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(blog.author!.avatar!),
                        ),
                      const SizedBox(width: 8),
                      Text(blog.author?.name ?? 'Author',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 11, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 3),
                      Text('${blog.readingTime} min',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                      const SizedBox(width: 12),
                      Icon(Icons.visibility, size: 11, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 3),
                      Text('${blog.viewsCount}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
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
}

// ─── Featured Blog Card ──────────────────

class _FeaturedBlogCard extends StatelessWidget {
  final BlogModel blog;
  const _FeaturedBlogCard({required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => BlogDetailPage(slug: blog.slug)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: blog.featuredImage != null
                  ? Image.network(blog.featuredImage!, fit: BoxFit.cover,
                      errorBuilder: (_, i1, i2) => _noImagePlaceholder())
                  : _noImagePlaceholder(),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (blog.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(blog.category!,
                                style: const TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                          ),
                        const Spacer(),
                        Icon(Icons.access_time, size: 10, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text('${blog.readingTime} min',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      blog.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (blog.author?.avatar != null)
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: NetworkImage(blog.author!.avatar!),
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(blog.author?.name ?? 'Author',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMain),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(blog.publishedAtHuman ?? '',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
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

  Widget _noImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)]),
      ),
      child: Center(
        child: Icon(Icons.article_outlined, size: 36, color: Colors.grey.shade400),
      ),
    );
  }
}

// ─── Latest Blog Card (horizontal list item) ──────────────────

class _LatestBlogCard extends StatelessWidget {
  final BlogModel blog;
  const _LatestBlogCard({required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => BlogDetailPage(slug: blog.slug)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: SizedBox(
                width: 110,
                height: 100,
                child: blog.featuredImage != null
                    ? Image.network(blog.featuredImage!, fit: BoxFit.cover,
                        errorBuilder: (_, i1, i2) => _placeholder())
                    : _placeholder(),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (blog.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(blog.category!,
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1))),
                          ),
                        const Spacer(),
                        Icon(Icons.access_time, size: 10, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text('${blog.readingTime} min',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      blog.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(blog.author?.name ?? 'Author',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain)),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text('${blog.viewsCount}',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            Text(blog.publishedAtHuman ?? '',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
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

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(child: Icon(Icons.article_outlined, size: 28, color: Colors.grey.shade400)),
    );
  }
}
