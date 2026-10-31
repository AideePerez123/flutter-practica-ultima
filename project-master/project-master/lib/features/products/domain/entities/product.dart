/// A product tracked in the inventory.
class Product {
  const Product({
    this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.categoryId,
    required this.purchasePrice,
    required this.salePrice,
    this.currentStock = 0,
    this.minStock = 0,
    this.imagePath,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;

  /// Unique product code, also encoded into the barcode and QR label.
  final String code;
  final String name;
  final String description;
  final int? categoryId;
  final double purchasePrice;
  final double salePrice;

  /// Current available quantity, always derived from confirmed movements.
  final int currentStock;
  final int minStock;
  final String? imagePath;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Inventory value estimate: stock x recorded purchase price.
  double get inventoryValue => currentStock * purchasePrice;

  /// True when stock is at or below the configured minimum.
  bool get isLowStock => currentStock <= minStock;

  /// Difference between sale and purchase price.
  double get margin => salePrice - purchasePrice;

  Product copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    int? categoryId,
    bool clearCategory = false,
    double? purchasePrice,
    double? salePrice,
    int? currentStock,
    int? minStock,
    String? imagePath,
    bool clearImage = false,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => Object.hash(id, code);

  @override
  String toString() => 'Product(id: $id, code: $code, name: $name)';
}
