import '../entities/movement.dart';
import '../entities/movement_type.dart';

/// Filters for the movement history.
class MovementQuery {
  const MovementQuery({this.productId, this.type, this.from, this.to});

  final int? productId;
  final MovementType? type;
  final DateTime? from;
  final DateTime? to;

  MovementQuery copyWith({
    int? productId,
    bool clearProduct = false,
    MovementType? type,
    bool clearType = false,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
  }) {
    return MovementQuery(
      productId: clearProduct ? null : (productId ?? this.productId),
      type: clearType ? null : (type ?? this.type),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}

/// Contract for movement persistence.
abstract class MovementRepository {
  /// Registers a movement and updates the product stock atomically.
  ///
  /// Returns the created movement id. Business rules are validated inside the
  /// transaction using [InventoryRules].
  Future<int> registerMovement(Movement movement);

  Future<List<Movement>> getMovements({MovementQuery? query});

  Future<int> countMovements();
}
