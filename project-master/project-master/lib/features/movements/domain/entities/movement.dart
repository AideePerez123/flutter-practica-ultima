import 'movement_type.dart';

/// A confirmed inventory movement.
///
/// Movements are immutable once stored: corrections must be recorded as a new
/// movement, never by editing or deleting an existing one.
class Movement {
  const Movement({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.resultingStock,
    required this.reason,
    required this.responsible,
    required this.createdAt,
    this.productCode,
    this.productName,
  });

  final int? id;
  final int productId;
  final MovementType type;

  /// Quantity entered by the user. For [MovementType.ajuste] it represents the
  /// counted stock.
  final int quantity;
  final int previousStock;
  final int resultingStock;
  final String reason;
  final String responsible;
  final DateTime createdAt;

  /// Denormalized fields populated by joins for reporting.
  final String? productCode;
  final String? productName;

  /// Difference actually applied to stock (resulting - previous).
  int get delta => resultingStock - previousStock;

  Movement copyWith({
    int? id,
    int? productId,
    MovementType? type,
    int? quantity,
    int? previousStock,
    int? resultingStock,
    String? reason,
    String? responsible,
    DateTime? createdAt,
    String? productCode,
    String? productName,
  }) {
    return Movement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      resultingStock: resultingStock ?? this.resultingStock,
      reason: reason ?? this.reason,
      responsible: responsible ?? this.responsible,
      createdAt: createdAt ?? this.createdAt,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movement && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => Object.hash(id, productId, createdAt);

  @override
  String toString() =>
      'Movement(id: $id, productId: $productId, type: ${type.name})';
}
