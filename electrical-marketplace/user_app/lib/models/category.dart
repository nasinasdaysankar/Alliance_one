class Category {
  final String id;
  final String name;
  final String? parentId;
  final String? slug;
  final int displayOrder;
  final bool isActive;
  final List<Category> children;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.slug,
    required this.displayOrder,
    required this.isActive,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        parentId: json['parent_id']?.toString(),
        slug: json['slug']?.toString(),
        displayOrder: int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
        isActive: json['is_active'] != false,
        children: (json['children'] as List<dynamic>?)
                ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
      );

  bool get isParent => parentId == null;
}
