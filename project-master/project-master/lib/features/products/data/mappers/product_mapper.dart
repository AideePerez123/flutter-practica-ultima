import '../../../../core/database/database_schema.dart';
import '../../domain/entities/product.dart';

/// Converts between [Product] entities and SQLite rows.
class ProductMapper {
  ProductMapper._();

  static const String table = DatabaseSchema.productsTable;

  static Product fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      categoryId: map['category_id'] as int?,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      currentStock: (map['current_stock'] as int?) ?? 0,
      minStock: (map['min_stock'] as int?) ?? 0,
      imagePath: map['image_path'] as String?,
      active: ((map['active'] as int?) ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  static Map<String, Object?> toMap(Product product) {
    return {
      'code': product.code,
      'name': product.name,
      'description': product.description,
      'category_id': product.categoryId,
      'purchase_price': product.purchasePrice,
      'sale_price': product.salePrice,
      'current_stock': product.currentStock,
      'min_stock': product.minStock,
      'image_path': product.imagePath,
      'active': product.active ? 1 : 0,
      'created_at': (product.createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
