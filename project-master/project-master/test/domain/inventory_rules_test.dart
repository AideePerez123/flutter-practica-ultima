import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_inteligente/core/error/domain_exception.dart';
import 'package:inventario_inteligente/features/movements/domain/entities/movement_type.dart';
import 'package:inventario_inteligente/features/movements/domain/services/inventory_rules.dart';

void main() {
  const rules = InventoryRules();

  group('entrada', () {
    test('suma la cantidad al stock actual', () {
      final result = rules.computeResultingStock(
        type: MovementType.entrada,
        quantity: 5,
        currentStock: 10,
        reason: 'compra',
      );
      expect(result, 15);
    });

    test('rechaza cantidad cero o negativa', () {
      expect(
        () => rules.computeResultingStock(
          type: MovementType.entrada,
          quantity: 0,
          currentStock: 10,
          reason: 'compra',
        ),
        throwsA(
          isA<DomainException>().having(
            (e) => e.code,
            'code',
            DomainErrorCodes.invalidQuantity,
          ),
        ),
      );
    });
  });

  group('salida', () {
    test('resta la cantidad del stock actual', () {
      final result = rules.computeResultingStock(
        type: MovementType.salida,
        quantity: 4,
        currentStock: 10,
        reason: 'venta',
      );
      expect(result, 6);
    });

    test('permite retirar exactamente todo el stock', () {
      final result = rules.computeResultingStock(
        type: MovementType.salida,
        quantity: 10,
        currentStock: 10,
        reason: 'venta',
      );
      expect(result, 0);
    });

    test('rechaza salidas mayores al stock disponible', () {
      expect(
        () => rules.computeResultingStock(
          type: MovementType.salida,
          quantity: 11,
          currentStock: 10,
          reason: 'venta',
        ),
        throwsA(
          isA<DomainException>().having(
            (e) => e.code,
            'code',
            DomainErrorCodes.insufficientStock,
          ),
        ),
      );
    });
  });

  group('ajuste', () {
    test('fija el stock a la cantidad contada', () {
      final result = rules.computeResultingStock(
        type: MovementType.ajuste,
        quantity: 3,
        currentStock: 40,
        reason: 'conteo físico',
      );
      expect(result, 3);
    });

    test('rechaza cantidades negativas', () {
      expect(
        () => rules.computeResultingStock(
          type: MovementType.ajuste,
          quantity: -1,
          currentStock: 40,
          reason: 'conteo',
        ),
        throwsA(isA<DomainException>()),
      );
    });
  });

  test('todo movimiento exige un motivo', () {
    expect(
      () => rules.computeResultingStock(
        type: MovementType.entrada,
        quantity: 1,
        currentStock: 0,
        reason: '   ',
      ),
      throwsA(
        isA<DomainException>()
            .having((e) => e.code, 'code', DomainErrorCodes.reasonRequired),
      ),
    );
  });
}
