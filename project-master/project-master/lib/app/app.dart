import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/home/presentation/pages/home_shell.dart';
import 'app_dependencies.dart';
import 'router.dart';

/// Application root widget.
class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dependencies.productProvider),
        ChangeNotifierProvider.value(value: dependencies.categoryProvider),
        ChangeNotifierProvider.value(value: dependencies.movementProvider),
        ChangeNotifierProvider.value(value: dependencies.dashboardProvider),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomeShell(),
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
