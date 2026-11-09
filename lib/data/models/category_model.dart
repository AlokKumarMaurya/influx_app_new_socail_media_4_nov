class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final int? parentId;
  final String? path;
  final List<CategoryModel> children;
  final int depth;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.parentId,
    this.path,
    this.children = const [],
    this.depth = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, {int depth = 0}) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String?,
      parentId: json['parent_id'] as int?,
      path: json['path'] as String?,
      depth: depth,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c), depth: depth + 1))
              .toList()
          : [],
    );
  }

  /// Get indented display name for dropdown options (e.g., "  — Sub Category")
  String get indentedName {
    if (depth == 0) return name;
    final prefix = '— ' * depth;
    return '$prefix$name';
  }

  /// Flatten tree into a single list with depth tracking
  static List<CategoryModel> flattenTree(List<CategoryModel> tree) {
    final List<CategoryModel> result = [];
    void walk(CategoryModel cat) {
      result.add(cat);
      for (final child in cat.children) {
        walk(child);
      }
    }
    for (final cat in tree) {
      walk(cat);
    }
    return result;
  }
}
