import '../../../../core/error/domain_exception.dart';
import '../entities/movement_type.dart';

/// Encapsulates the inventory business rules in a pure, testable way.
///
/// Has no dependency on storage or UI. Both the data layer and the tests rely
/// on it as the single source of truth for the rules.
class InventoryRules {
  const InventoryRules();

  /// Validates a movement request and returns the resulting stock.
  ///
  /// Throws [DomainException] when a rule is violated:
  /// * entry and exit quantities must be greater than zero;
  /// * exits may not exceed the available stock;
  /// * every movement needs a reason;
  /// * adjustments need a non negative counted stock and a justification.
  int computeResultingStock({
    required MovementType type,
    required int quantity,
    required int currentStock,
    required String reason,
  }) {
    if (reason.trim().isEmpty) {
      throw const DomainException(
        'Debe indicar el motivo del movimiento.',
        code: DomainErrorCodes.reasonRequired,
      );
    }

    switch (type) {
      case MovementType.entrada:
        if (quantity <= 0) {
          throw const DomainException(
            'La cantidad de entrada debe ser mayor que cero.',
            code: DomainErrorCodes.invalidQuantity,
          );
        }
        return currentStock + quantity;

      case MovementType.salida:
        if (quantity <= 0) {
          throw const DomainException(
            'La cantidad de salida debe ser mayor que cero.',
            code: DomainErrorCodes.invalidQuantity,
          );
        }
        if (quantity > currentStock) {
          throw DomainException(
            'No hay existencias suficientes: disponible $currentStock, '
            'solicitado $quantity.',
            code: DomainErrorCodes.insufficientStock,
          );
        }
        return currentStock - quantity;

      case MovementType.ajuste:
        if (quantity < 0) {
          throw const DomainException(
            'La cantidad contada no puede ser negativa.',
            code: DomainErrorCodes.invalidQuantity,
          );
        }
        return quantity;
    }
  }
}
