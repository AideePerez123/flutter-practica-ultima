import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final dependencies = AppDependencies();
  // Seed demonstration data before the first frame so the UI always has data.
  await dependencies.bootstrap();

  runApp(InventarioApp(dependencies: dependencies));
}
