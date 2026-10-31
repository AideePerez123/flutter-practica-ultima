import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';
import '../../../../core/error/domain_exception.dart';
import '../../../movements/domain/entities/movement_type.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../mappers/product_mapper.dart';

/// SQLite backed implementation of [ProductRepository].
class SqliteProductRepository implements ProductRepository {
  SqliteProductRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<Product>> getProducts({ProductQuery? query}) async {
    final db = await _appDatabase.database;
    final q = query ?? const ProductQuery();

    final where = <String>[];
    final args = <Object?>[];

    if (q.onlyActive) {
      where.add('p.active = 1');
    }
    if (q.categoryId != null) {
      where.add('p.category_id = ?');
      args.add(q.categoryId);
    }
    if (q.onlyLowStock) {
      where.add('p.current_stock <= p.min_stock');
    }
    if (q.search != null && q.search!.trim().isNotEmpty) {
      where.add('(p.code LIKE ? OR p.name LIKE ?)');
      final term = '%${q.search!.trim()}%';
      args
        ..add(term)
        ..add(term);
    }

    final rows = await db.rawQuery('''
      SELECT p.* FROM ${DatabaseSchema.productsTable} p
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY p.name COLLATE NOCASE ASC
    ''', args);

    return rows.map(ProductMapper.fromMap).toList();
  }

  @override
  Future<Product?> getProductById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      DatabaseSchema.productsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ProductMapper.fromMap(rows.first);
  }

  @override
  Future<Product?> getProductByCode(String code) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      DatabaseSchema.productsTable,
      where: 'code = ?',
      whereArgs: [code.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : ProductMapper.fromMap(rows.first);
  }

  @override
  Future<bool> codeExists(String code, {int? excludingId}) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      DatabaseSchema.productsTable,
      columns: ['id'],
      where: excludingId == null ? 'code = ?' : 'code = ? AND id != ?',
      whereArgs:
          excludingId == null ? [code.trim()] : [code.trim(), excludingId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<int> createProduct(
    Product product, {
    required String responsible,
  }) async {
    final db = await _appDatabase.database;

    return db.transaction<int>((txn) async {
      final existing = await txn.query(
        DatabaseSchema.productsTable,
        columns: ['id'],
        where: 'code = ?',
        whereArgs: [product.code.trim()],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw const DomainException(
          'Ya existe un producto con ese código.',
          code: DomainErrorCodes.codeDuplicated,
        );
      }

      final initialStock = product.currentStock;
      // Stock starts at zero; the initial quantity enters as a movement so it
      // stays traceable.
      final newProduct = product.copyWith(currentStock: 0);
      final productId = await txn.insert(
        DatabaseSchema.productsTable,
        ProductMapper.toMap(newProduct),
      );

      if (initialStock > 0) {
        final now = DateTime.now();
        await txn.insert(DatabaseSchema.movementsTable, {
          'product_id': productId,
          'type': MovementType.entrada.name,
          'quantity': initialStock,
          'previous_stock': 0,
          'resulting_stock': initialStock,
          'reason': 'Stock inicial',
          'responsible': responsible,
          'created_at': now.toIso8601String(),
        });
        await txn.update(
          DatabaseSchema.productsTable,
          {
            'current_stock': initialStock,
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
      }

      return productId;
    });
  }

  @override
  Future<void> updateProduct(Product product) async {
    final db = await _appDatabase.database;
    final id = product.id;
    if (id == null) {
      throw const DomainException('Producto sin identificador.');
    }

    final duplicated = await codeExists(product.code, excludingId: id);
    if (duplicated) {
      throw const DomainException(
        'Ya existe otro producto con ese código.',
        code: DomainErrorCodes.codeDuplicated,
      );
    }

    // Stock and creation date are never edited here; stock is managed through
    // movements only.
    final map = ProductMapper.toMap(product)
      ..remove('current_stock')
      ..remove('created_at');

    await db.update(
      DatabaseSchema.productsTable,
      map,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deactivateProduct(int id) async {
    final db = await _appDatabase.database;
    await db.update(
      DatabaseSchema.productsTable,
      {'active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> reactivateProduct(int id) async {
    final db = await _appDatabase.database;
    await db.update(
      DatabaseSchema.productsTable,
      {'active': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> hasMovements(int productId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      DatabaseSchema.movementsTable,
      columns: ['id'],
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<int> countProducts({bool onlyActive = false}) async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseSchema.productsTable}'
      '${onlyActive ? ' WHERE active = 1' : ''}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> countLowStock() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseSchema.productsTable} '
      'WHERE active = 1 AND current_stock <= min_stock',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<double> totalInventoryValue() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT SUM(current_stock * purchase_price) AS total '
      'FROM ${DatabaseSchema.productsTable} WHERE active = 1',
    );
    final value = result.first['total'];
    return value == null ? 0 : (value as num).toDouble();
  }
}
