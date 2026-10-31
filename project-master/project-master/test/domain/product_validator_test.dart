import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_inteligente/core/error/domain_exception.dart';
import 'package:inventario_inteligente/features/products/domain/entities/product.dart';
import 'package:inventario_inteligente/features/products/domain/services/product_validator.dart';

void main() {
  const validator = ProductValidator();

  Product product({
    String code = 'ABC-001',
    String name = 'Producto',
    double purchasePrice = 10,
    double salePrice = 15,
    int minStock = 1,
  }) {
    return Product(
      code: code,
      name: name,
      purchasePrice: purchasePrice,
      salePrice: salePrice,
      minStock: minStock,
    );
  }

  test('acepta un producto válido', () {
    expect(() => validator.validate(product()), returnsNormally);
  });

  test('exige código', () {
    expect(
      () => validator.validate(product(code: '  ')),
      throwsA(
        isA<DomainException>()
            .having((e) => e.code, 'code', DomainErrorCodes.codeRequired),
      ),
    );
  });

  test('exige nombre', () {
    expect(
      () => validator.validate(product(name: '')),
      throwsA(
        isA<DomainException>()
            .having((e) => e.code, 'code', DomainErrorCodes.nameRequired),
      ),
    );
  });

  test('rechaza precios negativos', () {
    expect(
      () => validator.validate(product(purchasePrice: -1)),
      throwsA(
        isA<DomainException>()
            .having((e) => e.code, 'code', DomainErrorCodes.invalidPrice),
      ),
    );
  });

  test('rechaza stock mínimo negativo', () {
    expect(
      () => validator.validate(product(minStock: -1)),
      throwsA(
        isA<DomainException>()
            .having((e) => e.code, 'code', DomainErrorCodes.invalidMinStock),
      ),
    );
  });
}
