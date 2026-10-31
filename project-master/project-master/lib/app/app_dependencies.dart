import '../../core/database/app_database.dart';
import '../../features/categories/data/repositories/sqlite_category_repository.dart';
import '../../features/categories/presentation/providers/category_provider.dart';
import '../../features/home/presentation/providers/dashboard_provider.dart';
import '../../features/movements/data/repositories/sqlite_movement_repository.dart';
import '../../features/movements/presentation/providers/movement_provider.dart';
import '../../features/products/data/repositories/sqlite_product_repository.dart';
import '../../features/products/data/seed/demo_data_seeder.dart';
import '../../features/products/presentation/providers/product_provider.dart';

/// Simple composition root.
///
/// Builds the database, repositories and providers, and seeds the demo data on
/// first run. Construction lives here to avoid a DI framework while keeping the
/// dependency direction: presentation depends on domain, implemented by data.
class AppDependencies {
  AppDependencies({AppDatabase? database})
      : database = database ?? AppDatabase();

  final AppDatabase database;

  late final SqliteProductRepository productRepository =
      SqliteProductRepository(database);
  late final SqliteCategoryRepository categoryRepository =
      SqliteCategoryRepository(database);
  late final SqliteMovementRepository movementRepository =
      SqliteMovementRepository(database);

  late final ProductProvider productProvider =
      ProductProvider(productRepository)..load();
  late final CategoryProvider categoryProvider =
      CategoryProvider(categoryRepository)..load();
  late final MovementProvider movementProvider =
      MovementProvider(movementRepository)..load();
  late final DashboardProvider dashboardProvider =
      DashboardProvider(productRepository, movementRepository)..load();

  Future<void> bootstrap() async {
    await DemoDataSeeder(database).seedIfEmpty();
  }
}
