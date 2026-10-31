import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Loads and manages product categories.
class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._repository);

  final CategoryRepository _repository;

  List<Category> _categories = const [];
  bool _loading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _loading;

  Category? byId(int? id) {
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  String nameOf(int? id) => byId(id)?.name ?? 'Sin categoría';

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _categories = await _repository.getCategories();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(String name) async {
    await _repository.createCategory(Category(name: name.trim()));
    await load();
  }

  Future<void> update(Category category) async {
    await _repository.updateCategory(category);
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.deleteCategory(id);
    await load();
  }
}
