import '../../../../core/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../movements/domain/entities/movement_type.dart';
import '../../domain/entities/product.dart';

/// Populates the database with demonstration data on first run.
///
/// Creates 3 categories and 15 products, each with an initial entry movement so
/// the history and stock stay consistent.
class DemoDataSeeder {
  DemoDataSeeder(this._appDatabase);

  final AppDatabase _appDatabase;

  static const List<String> _categoryNames = [
    'Bebidas',
    'Abarrotes',
    'Limpieza',
  ];

  /// (code, name, description, categoryIndex, purchase, sale, stock, minStock)
  static const List<List<Object>> _products = [
    ['BEB-001', 'Agua purificada 600 ml', 'Botella de agua sin gas', 0, 6.5, 12.0, 48, 12],
    ['BEB-002', 'Refresco de cola 2 L', 'Botella retornable', 0, 22.0, 35.0, 24, 8],
    ['BEB-003', 'Jugo de naranja 1 L', 'Jugo natural pasteurizado', 0, 18.0, 28.0, 15, 6],
    ['BEB-004', 'Café molido 250 g', 'Café tostado y molido', 0, 45.0, 69.0, 10, 4],
    ['BEB-005', 'Té verde caja 20 sobres', 'Té en sobres individuales', 0, 28.0, 42.0, 3, 5],
    ['ABA-001', 'Arroz 1 kg', 'Arroz blanco de grano largo', 1, 21.0, 32.0, 40, 10],
    ['ABA-002', 'Frijol negro 1 kg', 'Frijol negro seleccionado', 1, 26.0, 39.0, 30, 10],
    ['ABA-003', 'Aceite vegetal 900 ml', 'Aceite de girasol', 1, 38.0, 55.0, 18, 6],
    ['ABA-004', 'Azúcar estándar 1 kg', 'Azúcar refinada', 1, 24.0, 34.0, 25, 8],
    ['ABA-005', 'Atún en agua 140 g', 'Lata de atún en agua', 1, 19.0, 29.0, 4, 6],
    ['LIM-001', 'Jabón en polvo 1 kg', 'Detergente para ropa', 2, 34.0, 52.0, 20, 6],
    ['LIM-002', 'Cloro 1 L', 'Blanqueador desinfectante', 2, 16.0, 26.0, 22, 8],
    ['LIM-003', 'Limpiador multiusos 750 ml', 'Limpiador líquido aromatizado', 2, 27.0, 41.0, 12, 5],
    ['LIM-004', 'Papel higiénico 4 rollos', 'Papel de doble hoja', 2, 31.0, 47.0, 16, 6],
    ['LIM-005', 'Jabón de baño 3 piezas', 'Jabón de tocador', 2, 25.0, 38.0, 2, 4],
  ];

  /// Seeds data only when the products table is empty.
  Future<bool> seedIfEmpty() async {
    final db = await _appDatabase.database;
    final count = await db.query(DatabaseSchema.productsTable, limit: 1);
    if (count.isNotEmpty) return false;

    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final categoryIds = <int>[];
      for (final name in _categoryNames) {
        final id = await txn.insert(DatabaseSchema.categoriesTable, {
          'name': name,
          'created_at': now,
        });
        categoryIds.add(id);
      }

      for (final row in _products) {
        final code = row[0] as String;
        final stock = row[6] as int;
        final productId = await txn.insert(DatabaseSchema.productsTable, {
          'code': code,
          'name': row[1] as String,
          'description': row[2] as String,
          'category_id': categoryIds[row[3] as int],
          'purchase_price': row[4] as double,
          'sale_price': row[5] as double,
          'current_stock': stock,
          'min_stock': row[7] as int,
          'image_path': null,
          'active': 1,
          'created_at': now,
          'updated_at': now,
        });

        if (stock > 0) {
          await txn.insert(DatabaseSchema.movementsTable, {
            'product_id': productId,
            'type': MovementType.entrada.name,
            'quantity': stock,
            'previous_stock': 0,
            'resulting_stock': stock,
            'reason': 'Stock inicial (datos de demostración)',
            'responsible': AppConstants.defaultResponsible,
            'created_at': now,
          });
        }
      }
    });

    return true;
  }

  /// Builds the seed product list for tests without touching the database.
  static List<Product> buildProducts() {
    return _products
        .map(
          (row) => Product(
            code: row[0] as String,
            name: row[1] as String,
            description: row[2] as String,
            purchasePrice: row[4] as double,
            salePrice: row[5] as double,
            currentStock: row[6] as int,
            minStock: row[7] as int,
          ),
        )
        .toList();
  }

  static List<Category> buildCategories() =>
      _categoryNames.map((name) => Category(name: name)).toList();
}
