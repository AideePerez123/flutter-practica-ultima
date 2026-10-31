import 'package:flutter/foundation.dart';

import '../../../movements/domain/repositories/movement_repository.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';

/// Aggregated numbers shown on the dashboard.
class DashboardStats {
  const DashboardStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.lowStockCount,
    required this.totalMovements,
    required this.inventoryValue,
    required this.lowStockProducts,
    required this.recentMovements,
  });

  final int totalProducts;
  final int activeProducts;
  final int lowStockCount;
  final int totalMovements;
  final double inventoryValue;
  final List<Product> lowStockProducts;
  final int recentMovements;

  static const DashboardStats empty = DashboardStats(
    totalProducts: 0,
    activeProducts: 0,
    lowStockCount: 0,
    totalMovements: 0,
    inventoryValue: 0,
    lowStockProducts: [],
    recentMovements: 0,
  );
}

/// Computes dashboard indicators from the repositories.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._products, this._movements);

  final ProductRepository _products;
  final MovementRepository _movements;

  DashboardStats _stats = DashboardStats.empty;
  bool _loading = false;

  DashboardStats get stats => _stats;
  bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _products.countProducts(),
        _products.countProducts(onlyActive: true),
        _products.countLowStock(),
        _movements.countMovements(),
        _products.totalInventoryValue(),
        _products.getProducts(query: const ProductQuery(onlyLowStock: true)),
        _movements.getMovements(),
      ]);

      _stats = DashboardStats(
        totalProducts: results[0] as int,
        activeProducts: results[1] as int,
        lowStockCount: results[2] as int,
        totalMovements: results[3] as int,
        inventoryValue: results[4] as double,
        lowStockProducts: results[5] as List<Product>,
        recentMovements: (results[6] as List).length,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
