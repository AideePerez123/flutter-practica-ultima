import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_schema.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../mappers/category_mapper.dart';

/// SQLite backed implementation of [CategoryRepository].
class SqliteCategoryRepository implements CategoryRepository {
  SqliteCategoryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<Category>> getCategories() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      DatabaseSchema.categoriesTable,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(CategoryMapper.fromMap).toList();
  }

  @override
  Future<Category?> getCategoryById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      DatabaseSchema.categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : CategoryMapper.fromMap(rows.first);
  }

  @override
  Future<int> createCategory(Category category) async {
    final db = await _appDatabase.database;
    return db.insert(
      DatabaseSchema.categoriesTable,
      CategoryMapper.toMap(category),
    );
  }

  @override
  Future<void> updateCategory(Category category) async {
    final db = await _appDatabase.database;
    final id = category.id;
    if (id == null) return;
    await db.update(
      DatabaseSchema.categoriesTable,
      CategoryMapper.toMap(category)..remove('created_at'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      DatabaseSchema.categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
