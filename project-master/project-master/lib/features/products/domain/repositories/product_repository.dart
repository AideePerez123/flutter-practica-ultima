import '../entities/product.dart';

/// Query options for listing products.
class ProductQuery {
  const ProductQuery({
    this.search,
    this.categoryId,
    this.onlyActive = false,
    this.onlyLowStock = false,
  });

  final String? search;
  final int? categoryId;
  final bool onlyActive;
  final bool onlyLowStock;

  ProductQuery copyWith({
    String? search,
    int? categoryId,
    bool clearCategory = false,
    bool clearSearch = false,
    bool? onlyActive,
    bool? onlyLowStock,
  }) {
    return ProductQuery(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      onlyActive: onlyActive ?? this.onlyActive,
      onlyLowStock: onlyLowStock ?? this.onlyLowStock,
    );
  }
}

/// Contract for product persistence.
abstract class ProductRepository {
  Future<List<Product>> getProducts({ProductQuery? query});

  Future<Product?> getProductById(int id);

  Future<Product?> getProductByCode(String code);

  Future<bool> codeExists(String code, {int? excludingId});

  /// Creates a product and records its initial stock as an entry movement in a
  /// single transaction. Returns the new product id.
  Future<int> createProduct(Product product, {required String responsible});

  Future<void> updateProduct(Product product);

  /// Soft delete: marks the product inactive. A product with movements is never
  /// physically removed.
  Future<void> deactivateProduct(int id);

  Future<void> reactivateProduct(int id);

  Future<bool> hasMovements(int productId);

  Future<int> countProducts({bool onlyActive = false});

  Future<int> countLowStock();

  /// Total inventory value estimate: sum(stock * purchase price).
  Future<double> totalInventoryValue();
}
