import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../controllers/news_ticker_controller.dart';
import '../../pages/blog/blogs_page.dart';
import '../../pages/blog/blog_detail_page.dart';
import '../../utils/app_theme.dart';

class NewsTickerWidget extends StatefulWidget {
  const NewsTickerWidget({super.key});

  @override
  State<NewsTickerWidget> createState() => _NewsTickerWidgetState();
}

class _NewsTickerWidgetState extends State<NewsTickerWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;

      if (maxExtent > 0) {
        if (currentOffset >= maxExtent) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentOffset + 1.2);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NewsTickerController());

    return Obx(() {
      final isEnabled = controller.isEnabled.value;
      final isBlogs = controller.tickerType.value == 'latest_blogs';
      final hasBlogs = controller.blogItems.isNotEmpty;
      final hasText = controller.tickerText.value.isNotEmpty;

      if (!isEnabled || (isBlogs ? !hasBlogs : !hasText)) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        height: 36,
        color: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'news'.tr.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    if (isBlogs)
                      ...[...controller.blogItems, ...controller.blogItems].map(
                        (item) {
                          final slug = (item['slug'] ?? '').toString();
                          final title = (item['title'] ?? '').toString();
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (_) {
                              if (slug.isNotEmpty) {
                                Get.to(() => BlogDetailPage(slug: slug));
                              } else {
                                Get.to(() => const BlogsPage());
                              }
                            },
                            onTap: () {
                              if (slug.isNotEmpty) {
                                Get.to(() => BlogDetailPage(slug: slug));
                              } else {
                                Get.to(() => const BlogsPage());
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                right: 32,
                                top: 6,
                                bottom: 6,
                              ),
                              color: Colors.transparent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedDiceFaces01,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (_) => Get.to(() => const BlogsPage()),
                        onTap: () => Get.to(() => const BlogsPage()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: Colors.transparent,
                          child: Text(
                            controller.tickerText.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
