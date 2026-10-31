import 'package:flutter/material.dart';

import '../features/categories/presentation/pages/categories_page.dart';
import '../features/home/presentation/pages/home_shell.dart';
import '../features/labels/presentation/pages/label_page.dart';
import '../features/movements/presentation/pages/movement_form_page.dart';
import '../features/movements/presentation/pages/movement_history_page.dart';
import '../features/products/domain/entities/product.dart';
import '../features/products/presentation/pages/product_detail_page.dart';
import '../features/products/presentation/pages/product_form_page.dart';
import '../features/products/presentation/pages/product_list_page.dart';
import '../features/reports/presentation/pages/reports_page.dart';
import '../features/scanner/presentation/pages/scanner_page.dart';

/// Named route table for the application.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String products = '/products';
  static const String productForm = '/products/form';
  static const String productDetail = '/products/detail';
  static const String scanner = '/scanner';
  static const String movements = '/movements';
  static const String movementForm = '/movements/new';
  static const String labels = '/labels';
  static const String reports = '/reports';
  static const String categories = '/categories';
}

/// Central route generator.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.products:
        return MaterialPageRoute(builder: (_) => const ProductListPage());

      case AppRoutes.productForm:
        final product = settings.arguments as Product?;
        return MaterialPageRoute(
          builder: (_) => ProductFormPage(product: product),
        );

      case AppRoutes.productDetail:
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: settings.arguments as int),
        );

      case AppRoutes.scanner:
        return MaterialPageRoute(builder: (_) => const ScannerPage());

      case AppRoutes.movements:
        return MaterialPageRoute(builder: (_) => const MovementHistoryPage());

      case AppRoutes.movementForm:
        final args = settings.arguments as MovementFormArgs?;
        return MaterialPageRoute(
          builder: (_) =>
              MovementFormPage(args: args ?? const MovementFormArgs()),
        );

      case AppRoutes.labels:
        final product = settings.arguments as Product;
        return MaterialPageRoute(builder: (_) => LabelPage(product: product));

      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportsPage());

      case AppRoutes.categories:
        return MaterialPageRoute(builder: (_) => const CategoriesPage());

      case AppRoutes.home:
      default:
        return MaterialPageRoute(builder: (_) => const HomeShell());
    }
  }
}
