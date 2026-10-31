import '../../../../core/database/database_schema.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_type.dart';

/// Converts between [Movement] entities and SQLite rows.
class MovementMapper {
  MovementMapper._();

  static const String table = DatabaseSchema.movementsTable;

  static Movement fromMap(Map<String, Object?> map) {
    return Movement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      type: MovementType.fromName(map['type'] as String),
      quantity: map['quantity'] as int,
      previousStock: map['previous_stock'] as int,
      resultingStock: map['resulting_stock'] as int,
      reason: map['reason'] as String,
      responsible: map['responsible'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      productCode: map['product_code'] as String?,
      productName: map['product_name'] as String?,
    );
  }

  static Map<String, Object?> toMap(Movement movement) {
    return {
      'product_id': movement.productId,
      'type': movement.type.name,
      'quantity': movement.quantity,
      'previous_stock': movement.previousStock,
      'resulting_stock': movement.resultingStock,
      'reason': movement.reason,
      'responsible': movement.responsible,
      'created_at': movement.createdAt.toIso8601String(),
    };
  }
}
