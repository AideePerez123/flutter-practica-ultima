import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_inteligente/core/theme/app_theme.dart';

void main() {
  testWidgets('MaterialApp builds with the app theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Text('Inventario Inteligente')),
      ),
    );
    expect(find.text('Inventario Inteligente'), findsOneWidget);
  });
}
