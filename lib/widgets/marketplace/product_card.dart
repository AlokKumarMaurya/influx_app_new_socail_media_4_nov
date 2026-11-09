import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/product_model.dart';
import '../../utils/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onSave,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1.1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  // Badges
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (product.isNew)
                          _buildBadge('New', Colors.green),
                        if (product.isSaved) ...[
                          const SizedBox(height: 4),
                          _buildBadge('Saved', AppColors.primary),
                        ],
                      ],
                    ),
                  ),
                  // Status badge for own listings
                  if (showActions)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge(
                        product.status == 'available' ? 'Available' : 'Sold',
                        product.status == 'available'
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.location != null &&
                      product.location!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            product.location!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Action buttons for own listings
                  if (showActions) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Edit',
                            Icons.edit_outlined,
                            onEdit,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          null,
                          Icons.delete_outline,
                          onDelete,
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.primaryImageUrl != null &&
        product.primaryImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: product.primaryImageUrl!,
        fit: BoxFit.cover,
        placeholder: (_, index) => Container(
          color: AppColors.isDark ? Colors.grey[800] : Colors.grey[200],
          child: Center(
            child: Icon(Icons.image_outlined,
                size: 40, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
        ),
        errorWidget: (_, i1, i2) => Container(
          color: AppColors.isDark ? Colors.grey[800] : Colors.grey[200],
          child: Center(
            child: Icon(Icons.broken_image_outlined,
                size: 40, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
        ),
      );
    }
    return Container(
      color: AppColors.isDark ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: Icon(Icons.shopping_bag_outlined,
            size: 40, color: AppColors.textSecondary.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String? label,
    IconData icon,
    VoidCallback? onPressed, {
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.isDark ? Colors.white10 : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.isDark ? Colors.white12 : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isDestructive ? Colors.red : AppColors.textSecondary,
              ),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
