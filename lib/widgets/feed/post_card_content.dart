import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart' hide ImageSource;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../pages/feed/single_post_page.dart';
import '../../pages/feed/search_page.dart';
import '../../pages/marketplace/marketplace_page.dart';
import '../../pages/user/profile_page.dart';
import '../common/hashtag_text.dart';

class PostCardContent extends StatefulWidget {
  final PostModel post;
  final bool isSingleView;
  final bool isSharedNested;

  const PostCardContent({
    super.key,
    required this.post,
    required this.isSingleView,
    this.isSharedNested = false,
  });

  @override
  State<PostCardContent> createState() => _PostCardContentState();
}

class _PostCardContentState extends State<PostCardContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final content = widget.post.content ?? '';
    final hasContent = content.isNotEmpty;
    final hasLink = widget.post.linkUrl != null && widget.post.linkUrl!.isNotEmpty;
    final isColor = widget.post.postType == 'color' && widget.post.bgColor != null;

    if (!hasContent && !hasLink && !isColor) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.isSingleView
          ? null
          : () => Get.to(() => SinglePostPage(postId: widget.post.id, initialPost: widget.post)),
      child: _buildBody(content, hasContent, hasLink, isColor),
    );
  }

  Widget _buildBody(String content, bool hasContent, bool hasLink, bool isColor) {
    if (isColor && hasContent) {
      return _buildColorContent(content);
    }

    final formattedContent = hasContent ? _formatContentLinks(content) : '';
    final isLong = formattedContent.length > 250;

    return Padding(
      padding: widget.isSharedNested
          ? const EdgeInsets.symmetric(vertical: 4)
          : const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasContent)
            HtmlWidget(
              _expanded || !isLong ? formattedContent : '${formattedContent.substring(0, 250)}...',
              textStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMain,
                height: 1.4,
                fontSize: widget.isSharedNested ? 14 : 16,
              ),
              onTapUrl: (url) async {
                final cleanUrl = url.trim();
                if (cleanUrl.startsWith('mention://')) {
                  final username = cleanUrl.replaceFirst('mention://', '').trim();
                  if (username.isNotEmpty) {
                    final asId = int.tryParse(username);
                    if (asId != null) {
                      Get.to(() => ProfilePage(userId: asId));
                    } else {
                      Get.to(() => ProfilePage(username: username));
                    }
                  }
                  return true;
                }
                if (cleanUrl.startsWith('hashtag://')) {
                  final tag = cleanUrl.replaceFirst('hashtag://', '');
                  final query = tag.startsWith('#') ? tag : '#$tag';
                  Get.to(() => SearchPage(initialQuery: query));
                  return true;
                }
                if (cleanUrl.contains('/search') && cleanUrl.contains('q=')) {
                  final uri = Uri.tryParse(cleanUrl);
                  String tag = uri?.queryParameters['q'] ?? '';
                  if (tag.isNotEmpty) {
                    if (!tag.startsWith('#')) tag = '#$tag';
                    Get.to(() => SearchPage(initialQuery: tag));
                    return true;
                  }
                }
                if (cleanUrl.startsWith('marketplace://') ||
                    (cleanUrl.contains('/marketplace') && cleanUrl.contains('q='))) {
                  final uri = Uri.tryParse(cleanUrl);
                  String tag = uri?.queryParameters['q'] ?? cleanUrl.replaceFirst('marketplace://', '');
                  if (tag.isNotEmpty) {
                    if (!tag.startsWith('#')) tag = '#$tag';
                    Get.to(() => MarketplacePage(initialSearchQuery: tag));
                    return true;
                  }
                }
                final uri = Uri.tryParse(cleanUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return true;
                }
                return false;
              },
            ),
          if (hasContent && isLong)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _expanded ? 'See less' : 'See more',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          if (hasLink)
            _buildLinkPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildLinkPreviewCard() {
    final linkUrl = widget.post.linkUrl;
    if (linkUrl == null || linkUrl.isEmpty) return const SizedBox.shrink();

    final linkTitle = widget.post.linkTitle ?? linkUrl;
    final linkDesc = widget.post.linkDescription;
    final linkImage = widget.post.linkImage;
    final linkDomain = widget.post.linkDomain ?? Uri.tryParse(linkUrl)?.host.replaceAll('www.', '').toUpperCase();

    final cardBgColor = AppColors.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);
    final cardBorderColor = AppColors.isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Material(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final uri = Uri.tryParse(linkUrl);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: cardBorderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (linkImage != null && linkImage.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: CachedNetworkImage(
                      imageUrl: linkImage,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, err, stack) => const SizedBox.shrink(),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  color: cardBgColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (linkDomain != null && linkDomain.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            linkDomain,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.isDark ? AppColors.textSecondary : const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Text(
                        linkTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                          height: 1.3,
                        ),
                      ),
                      if (linkDesc != null && linkDesc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            linkDesc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorContent(String content) {
    final colors = _parseGradient(widget.post.bgColor!);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: HashtagText(
          text: content,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
            shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
          ),
          hashtagStyle: const TextStyle(
            color: Colors.yellowAccent,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1.4,
            decoration: TextDecoration.underline,
            decorationColor: Colors.yellowAccent,
            shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
          ),
        ),
      ),
    );
  }

  List<Color> _parseGradient(String gradient) {
    final hexRegex = RegExp(r'#([0-9a-fA-F]{6})');
    final matches = hexRegex.allMatches(gradient);
    if (matches.length >= 2) {
      return matches.map((m) => Color(int.parse('0xFF${m.group(1)}')).withValues(alpha: 1.0)).toList();
    }
    return [const Color(0xFF667eea), const Color(0xFF764ba2)];
  }

  String _formatContentLinks(String text) {
    String formatted = text;
    if (!formatted.contains('<a ')) {
      final urlRegex = RegExp(r'(https?://[^\s<"]+|www\.[^\s<"]+)', caseSensitive: false);
      formatted = formatted.replaceAllMapped(urlRegex, (match) {
        final url = match.group(0)!;
        final href = url.toLowerCase().startsWith('www.') ? 'https://$url' : url;
        return '<a href="$href">$url</a>';
      });
    }

    final hashtagRegex = RegExp(r'(<a\b[^>]*>.*?<\/a>)|(?<![\w&])#([a-zA-Z0-9_\u0080-\uFFFF]+)');
    formatted = formatted.replaceAllMapped(hashtagRegex, (match) {
      if (match.group(1) != null) return match.group(1)!;
      final hashtag = match.group(0)!;
      final tag = match.group(2)!;
      return '<a href="hashtag://$tag" style="color: #2563eb; font-weight: 600; text-decoration: none;">$hashtag</a>';
    });

    return formatted;
  }
}
