import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:inventario_inteligente/core/database/app_database.dart';
import 'package:inventario_inteligente/core/error/domain_exception.dart';
import 'package:inventario_inteligente/features/movements/data/repositories/sqlite_movement_repository.dart';
import 'package:inventario_inteligente/features/movements/domain/entities/movement.dart';
import 'package:inventario_inteligente/features/movements/domain/entities/movement_type.dart';
import 'package:inventario_inteligente/features/products/data/repositories/sqlite_product_repository.dart';
import 'package:inventario_inteligente/features/products/domain/entities/product.dart';
import 'package:inventario_inteligente/features/products/domain/repositories/product_repository.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late SqliteProductRepository products;
  late SqliteMovementRepository movements;

  setUp(() async {
    database = AppDatabase(
      databaseFactoryOverride: databaseFactoryFfi,
      pathOverride: inMemoryDatabasePath,
    );
    products = SqliteProductRepository(database);
    movements = SqliteMovementRepository(database);
    // Force database creation before the tests run.
    await database.database;
  });

  tearDown(() async {
    await database.close();
  });

  Future<int> createProduct({int initialStock = 10}) {
    return products.createProduct(
      Product(
        code: 'TST-001',
        name: 'Producto de prueba',
        purchasePrice: 5,
        salePrice: 8,
        currentStock: initialStock,
        minStock: 2,
      ),
      responsible: 'tester',
    );
  }

  test('creating a product records initial stock as an entry movement',
      () async {
    final id = await createProduct(initialStock: 7);

    final product = await products.getProductById(id);
    expect(product!.currentStock, 7);

    final history = await movements.getMovements();
    expect(history, hasLength(1));
    expect(history.first.type, MovementType.entrada);
    expect(history.first.quantity, 7);
    expect(history.first.resultingStock, 7);
  });

  test('registering an exit decreases stock and keeps history', () async {
    final id = await createProduct(initialStock: 10);

    await movements.registerMovement(
      Movement(
        productId: id,
        type: MovementType.salida,
        quantity: 4,
        previousStock: 0,
        resultingStock: 0,
        reason: 'venta',
        responsible: 'tester',
        createdAt: DateTime.now(),
      ),
    );

    final product = await products.getProductById(id);
    expect(product!.currentStock, 6);

    final history = await movements.getMovements();
    expect(history, hasLength(2));
    final last = history.first;
    expect(last.type, MovementType.salida);
    expect(last.previousStock, 10);
    expect(last.resultingStock, 6);
  });

  test('an exit beyond available stock is rejected and stock is unchanged',
      () async {
    final id = await createProduct(initialStock: 3);

    expect(
      () => movements.registerMovement(
        Movement(
          productId: id,
          type: MovementType.salida,
          quantity: 10,
          previousStock: 0,
          resultingStock: 0,
          reason: 'venta',
          responsible: 'tester',
          createdAt: DateTime.now(),
        ),
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.code,
          'code',
          DomainErrorCodes.insufficientStock,
        ),
      ),
    );

    final product = await products.getProductById(id);
    expect(product!.currentStock, 3);
  });

  test('an adjustment sets the counted stock', () async {
    final id = await createProduct(initialStock: 50);

    await movements.registerMovement(
      Movement(
        productId: id,
        type: MovementType.ajuste,
        quantity: 12,
        previousStock: 0,
        resultingStock: 0,
        reason: 'conteo físico',
        responsible: 'tester',
        createdAt: DateTime.now(),
      ),
    );

    final product = await products.getProductById(id);
    expect(product!.currentStock, 12);
  });

  test('duplicate codes are rejected', () async {
    await createProduct();

    expect(
      () => createProduct(),
      throwsA(
        isA<DomainException>().having(
          (e) => e.code,
          'code',
          DomainErrorCodes.codeDuplicated,
        ),
      ),
    );
  });

  test('search, low stock and inventory value queries work', () async {
    await createProduct(initialStock: 1); // minStock 2 -> low stock

    final found = await products.getProducts(
      query: const ProductQuery(search: 'prueba'),
    );
    expect(found, hasLength(1));

    expect(await products.countLowStock(), 1);
    expect(await products.countProducts(), 1);
    expect(await products.totalInventoryValue(), 5.0);
  });

  test('deactivated products keep their movement history', () async {
    final id = await createProduct(initialStock: 5);
    await products.deactivateProduct(id);

    final product = await products.getProductById(id);
    expect(product!.active, isFalse);
    expect(await products.hasMovements(id), isTrue);

    expect(
      () => movements.registerMovement(
        Movement(
          productId: id,
          type: MovementType.entrada,
          quantity: 1,
          previousStock: 0,
          resultingStock: 0,
          reason: 'compra',
          responsible: 'tester',
          createdAt: DateTime.now(),
        ),
      ),
      throwsA(isA<DomainException>()),
    );
  });
}
