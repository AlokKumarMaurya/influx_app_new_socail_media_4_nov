import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../utils/app_theme.dart';

class CategoryChips extends StatelessWidget {
  final List<CategoryModel> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  List<CategoryModel> _getCategoryPath(List<CategoryModel> tree, int targetId) {
    List<CategoryModel>? walk(List<CategoryModel> nodes, List<CategoryModel> path) {
      for (final node in nodes) {
        final currentPath = [...path, node];
        if (node.id == targetId) return currentPath;
        if (node.children.isNotEmpty) {
          final res = walk(node.children, currentPath);
          if (res != null) return res;
        }
      }
      return null;
    }
    return walk(tree, []) ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final chain = selectedCategoryId != null
        ? _getCategoryPath(categories, selectedCategoryId!)
        : <CategoryModel>[];

    final List<Widget> rows = [];

    // Level 0: Main Categories
    final mainActiveId = chain.isNotEmpty ? chain[0].id : null;
    rows.add(
      SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length + 1,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildChip(
                label: 'All',
                icon: Icons.grid_view_rounded,
                isActive: selectedCategoryId == null,
                onTap: () => onCategorySelected(null),
              );
            }
            final category = categories[index - 1];
            final isActive = mainActiveId == category.id;
            return _buildChip(
              label: category.name,
              icon: _getIconForCategory(category.icon),
              isActive: isActive,
              onTap: () => onCategorySelected(category.id),
            );
          },
        ),
      ),
    );

    // Sub-category rows for active chain
    for (int i = 0; i < chain.length; i++) {
      final parentCat = chain[i];
      if (parentCat.children.isNotEmpty) {
        final nextActiveId = (i + 1 < chain.length) ? chain[i + 1].id : null;
        rows.add(const SizedBox(height: 6));
        rows.add(
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: parentCat.children.length + 1,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildChip(
                    label: 'All in ${parentCat.name}',
                    icon: Icons.subdirectory_arrow_right_rounded,
                    isActive: nextActiveId == null && selectedCategoryId == parentCat.id,
                    onTap: () => onCategorySelected(parentCat.id),
                    isSub: true,
                  );
                }
                final subCat = parentCat.children[index - 1];
                final isSubActive = nextActiveId == subCat.id;
                return _buildChip(
                  label: subCat.name,
                  icon: _getIconForCategory(subCat.icon),
                  isActive: isSubActive,
                  onTap: () => onCategorySelected(subCat.id),
                  isSub: true,
                );
              },
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    bool isSub = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : AppColors.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : AppColors.isDark
                    ? Colors.white12
                    : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? icon) {
    switch (icon) {
      case 'car':
        return Icons.directions_car_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'smartphone':
        return Icons.phone_android_outlined;
      case 'shirt':
        return Icons.checkroom_outlined;
      case 'book':
      case 'book-open':
        return Icons.menu_book_outlined;
      case 'briefcase':
        return Icons.work_outline;
      case 'gift':
        return Icons.card_giftcard_outlined;
      case 'baby':
      case 'smile':
        return Icons.child_care_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'dumbbell':
      case 'activity':
        return Icons.fitness_center_outlined;
      case 'monitor':
      case 'tv':
        return Icons.tv_outlined;
      case 'tool':
        return Icons.build_outlined;
      case 'paw-print':
        return Icons.pets_outlined;
      case 'utensils':
        return Icons.restaurant_outlined;
      default:
        return Icons.label_outline;
    }
  }
}
