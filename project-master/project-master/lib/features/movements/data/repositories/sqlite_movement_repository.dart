import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';
import '../../../../core/error/domain_exception.dart';
import '../../domain/entities/movement.dart';
import '../../domain/repositories/movement_repository.dart';
import '../../domain/services/inventory_rules.dart';
import '../mappers/movement_mapper.dart';

/// SQLite backed implementation of [MovementRepository].
///
/// The movement insert and the stock update run inside a single transaction so
/// they either both succeed or both fail.
class SqliteMovementRepository implements MovementRepository {
  SqliteMovementRepository(
    this._appDatabase, {
    this.rules = const InventoryRules(),
  });

  final AppDatabase _appDatabase;
  final InventoryRules rules;

  @override
  Future<int> registerMovement(Movement movement) async {
    final db = await _appDatabase.database;

    return db.transaction<int>((txn) async {
      final productRows = await txn.query(
        DatabaseSchema.productsTable,
        where: 'id = ?',
        whereArgs: [movement.productId],
        limit: 1,
      );
      if (productRows.isEmpty) {
        throw const DomainException(
          'El producto no existe.',
          code: DomainErrorCodes.productNotFound,
        );
      }

      final currentStock = productRows.first['current_stock'] as int;
      final active = ((productRows.first['active'] as int?) ?? 1) == 1;
      if (!active) {
        throw const DomainException(
          'El producto está desactivado; no admite movimientos.',
        );
      }

      // Recompute the resulting stock inside the transaction so concurrent
      // updates cannot bypass validation.
      final resultingStock = rules.computeResultingStock(
        type: movement.type,
        quantity: movement.quantity,
        currentStock: currentStock,
        reason: movement.reason,
      );

      final now = DateTime.now();
      final toInsert = movement.copyWith(
        previousStock: currentStock,
        resultingStock: resultingStock,
        createdAt: now,
      );

      final id = await txn.insert(
        DatabaseSchema.movementsTable,
        MovementMapper.toMap(toInsert),
      );

      await txn.update(
        DatabaseSchema.productsTable,
        {
          'current_stock': resultingStock,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [movement.productId],
      );

      return id;
    });
  }

  @override
  Future<List<Movement>> getMovements({MovementQuery? query}) async {
    final db = await _appDatabase.database;
    final q = query ?? const MovementQuery();

    final where = <String>[];
    final args = <Object?>[];

    if (q.productId != null) {
      where.add('m.product_id = ?');
      args.add(q.productId);
    }
    if (q.type != null) {
      where.add('m.type = ?');
      args.add(q.type!.name);
    }
    if (q.from != null) {
      where.add('m.created_at >= ?');
      args.add(q.from!.toIso8601String());
    }
    if (q.to != null) {
      where.add('m.created_at <= ?');
      args.add(q.to!.toIso8601String());
    }

    final rows = await db.rawQuery('''
      SELECT m.*, p.code AS product_code, p.name AS product_name
      FROM ${DatabaseSchema.movementsTable} m
      INNER JOIN ${DatabaseSchema.productsTable} p ON p.id = m.product_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY m.created_at DESC, m.id DESC
    ''', args);

    return rows.map(MovementMapper.fromMap).toList();
  }

  @override
  Future<int> countMovements() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DatabaseSchema.movementsTable}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
