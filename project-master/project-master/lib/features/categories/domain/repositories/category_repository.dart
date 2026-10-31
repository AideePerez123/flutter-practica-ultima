import '../entities/category.dart';

/// Contract for category persistence.
abstract class CategoryRepository {
  Future<List<Category>> getCategories();

  Future<Category?> getCategoryById(int id);

  Future<int> createCategory(Category category);

  Future<void> updateCategory(Category category);

  Future<void> deleteCategory(int id);
}
