import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../pages/feed/search_page.dart';
import '../../pages/marketplace/marketplace_page.dart';

enum HashtagContext { post, product }

/// A text widget that renders #hashtags and URLs as clickable spans.
/// In post context, tapping a hashtag navigates to SearchPage.
/// In product context, tapping a hashtag navigates to MarketplacePage.
class HashtagText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? hashtagStyle;
  final TextStyle? urlStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;
  final HashtagContext contextType;
  final void Function(String tag)? onHashtagTap;

  const HashtagText({
    super.key,
    required this.text,
    this.style,
    this.hashtagStyle,
    this.urlStyle,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
    this.contextType = HashtagContext.post,
    this.onHashtagTap,
  });

  @override
  State<HashtagText> createState() => _HashtagTextState();
}

class _HashtagTextState extends State<HashtagText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  void _handleHashtagClick(String tag) {
    if (widget.onHashtagTap != null) {
      widget.onHashtagTap!(tag);
      return;
    }

    final query = tag.startsWith('#') ? tag : '#$tag';
    if (widget.contextType == HashtagContext.product) {
      Get.to(() => MarketplacePage(initialSearchQuery: query));
    } else {
      Get.to(() => SearchPage(initialQuery: query));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final defaultStyle = widget.style ??
        TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.4);
    final effectiveHashtagStyle = widget.hashtagStyle ??
        defaultStyle.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        );
    final effectiveUrlStyle = widget.urlStyle ??
        defaultStyle.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        );

    // Regex to match URLs or #hashtags (with international unicode word characters)
    final regex = RegExp(
      r'(https?://[^\s<"]+|www\.[^\s<"]+)|(?<![\w&])#([a-zA-Z0-9_\u0080-\uFFFF]+)',
      caseSensitive: false,
    );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(widget.text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: widget.text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      final urlMatch = match.group(1);
      final tagMatch = match.group(2);

      if (urlMatch != null) {
        final url = urlMatch;
        final href = url.toLowerCase().startsWith('www.') ? 'https://$url' : url;
        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(href);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          };
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: url,
            style: effectiveUrlStyle,
            recognizer: recognizer,
          ),
        );
      } else if (tagMatch != null) {
        final fullTag = '#$tagMatch';
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _handleHashtagClick(fullTag);
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: fullTag,
            style: effectiveHashtagStyle,
            recognizer: recognizer,
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }
}
