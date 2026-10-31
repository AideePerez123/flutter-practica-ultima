import 'package:flutter/foundation.dart';

import '../../../../core/error/domain_exception.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

/// Exposes product data and mutations to the UI.
class ProductProvider extends ChangeNotifier {
  ProductProvider(this._repository);

  final ProductRepository _repository;

  List<Product> _products = const [];
  bool _loading = false;
  Object? _error;
  ProductQuery _query = const ProductQuery();

  List<Product> get products => _products;
  bool get isLoading => _loading;
  Object? get error => _error;
  ProductQuery get query => _query;

  Future<void> load({ProductQuery? query}) async {
    if (query != null) _query = query;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _repository.getProducts(query: _query);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setSearch(String? search) {
    _query = _query.copyWith(
      search: search,
      clearSearch: search == null || search.isEmpty,
    );
    return load();
  }

  Future<void> setCategory(int? categoryId) {
    _query = _query.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
    );
    return load();
  }

  Future<void> toggleOnlyLowStock() {
    _query = _query.copyWith(onlyLowStock: !_query.onlyLowStock);
    return load();
  }

  Future<void> resetFilters() {
    _query = const ProductQuery();
    return load();
  }

  /// Creates a product; returns it on success or null when an error occurred.
  Future<Product?> createProduct(Product product, {required String responsible}) async {
    try {
      final id = await _repository.createProduct(product, responsible: responsible);
      await load();
      return product.copyWith(id: id);
    } on DomainException {
      rethrow;
    } catch (e) {
      _error = e;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    await _repository.updateProduct(product);
    await load();
  }

  Future<void> deactivate(int id) async {
    await _repository.deactivateProduct(id);
    await load();
  }

  Future<void> reactivate(int id) async {
    await _repository.reactivateProduct(id);
    await load();
  }

  Future<Product?> findByCode(String code) => _repository.getProductByCode(code);

  Future<Product?> findById(int id) => _repository.getProductById(id);

  Future<bool> codeExists(String code, {int? excludingId}) =>
      _repository.codeExists(code, excludingId: excludingId);
}
