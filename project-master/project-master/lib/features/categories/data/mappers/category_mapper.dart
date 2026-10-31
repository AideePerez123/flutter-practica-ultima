import '../../../../core/database/database_schema.dart';
import '../../domain/entities/category.dart';

/// Converts between [Category] entities and SQLite rows.
class CategoryMapper {
  CategoryMapper._();

  static const String table = DatabaseSchema.categoriesTable;

  static Category fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  static Map<String, Object?> toMap(Category category) {
    return {
      'name': category.name,
      'created_at': (category.createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
