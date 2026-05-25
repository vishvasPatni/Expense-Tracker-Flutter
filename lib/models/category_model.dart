import '../utils/safe_parse.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    this.parentCategoryId,
    required this.isDefault,
    required this.categoryType,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;
  final String? parentCategoryId;
  final bool isDefault;
  final String categoryType; // 'expense', 'income', or 'transfer'
  final DateTime createdAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'more_horiz',
      color: json['color'] as String? ?? '#6366F1',
      parentCategoryId: json['parent_category_id'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      categoryType: json['category_type'] as String? ?? 'expense',
      createdAt: parseDateTimeOrDefault(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'icon': icon,
        'color': color,
        'parent_category_id': parentCategoryId,
        'is_default': isDefault,
        'category_type': categoryType,
        'created_at': createdAt.toIso8601String(),
      };

  CategoryModel copyWith({
    String? name,
    String? icon,
    String? color,
    String? categoryType,
  }) {
    return CategoryModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentCategoryId: parentCategoryId,
      isDefault: isDefault,
      categoryType: categoryType ?? this.categoryType,
      createdAt: createdAt,
    );
  }
}
