import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/url_utils.dart';
import '../../utils/app_theme.dart';
import './skeleton_loader.dart';

class CustomNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    final fullUrl = UrlUtils.getFullUrl(imageUrl);

    Widget image = CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return SkeletonLoader(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      shape: shape,
      borderRadius: borderRadius,
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withAlpha(20),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primary,
          size: 24,
        ),
      ),
    );
  }
}
