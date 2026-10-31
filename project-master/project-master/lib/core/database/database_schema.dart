import 'package:sqflite/sqflite.dart';

/// Declarative schema for the local SQLite database.
class DatabaseSchema {
  DatabaseSchema._();

  static const String categoriesTable = 'categories';
  static const String productsTable = 'products';
  static const String movementsTable = 'movements';

  static Future<void> create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $productsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category_id INTEGER,
        purchase_price REAL NOT NULL DEFAULT 0,
        sale_price REAL NOT NULL DEFAULT 0,
        current_stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $categoriesTable (id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $movementsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previous_stock INTEGER NOT NULL,
        resulting_stock INTEGER NOT NULL,
        reason TEXT NOT NULL,
        responsible TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES $productsTable (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('CREATE INDEX idx_products_code ON $productsTable (code)');
    await db.execute(
      'CREATE INDEX idx_movements_product ON $movementsTable (product_id)',
    );
    await db.execute(
      'CREATE INDEX idx_movements_created ON $movementsTable (created_at)',
    );
  }
}
