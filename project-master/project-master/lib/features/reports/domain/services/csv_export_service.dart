import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/app_constants.dart';
import '../../../movements/domain/entities/movement.dart';
import '../../../products/domain/entities/product.dart';

/// Builds CSV content and writes it to the device documents directory.
class CsvExportService {
  const CsvExportService();

  static final DateFormat _stamp = DateFormat('yyyyMMdd_HHmmss');

  /// Exports the product list with stock, prices and inventory value.
  Future<File> exportProducts(
    List<Product> products, {
    required String Function(int?) categoryName,
  }) async {
    final rows = <List<Object?>>[
      [
        'Codigo',
        'Nombre',
        'Categoria',
        'Descripcion',
        'Precio compra',
        'Precio venta',
        'Stock actual',
        'Stock minimo',
        'Estado',
        'Valor inventario',
      ],
      for (final product in products)
        [
          product.code,
          product.name,
          categoryName(product.categoryId),
          product.description,
          product.purchasePrice.toStringAsFixed(2),
          product.salePrice.toStringAsFixed(2),
          product.currentStock,
          product.minStock,
          product.active ? 'Activo' : 'Inactivo',
          product.inventoryValue.toStringAsFixed(2),
        ],
    ];

    return _write(rows, AppConstants.csvFileNamePrefix);
  }

  /// Exports the movement history.
  Future<File> exportMovements(List<Movement> movements) async {
    final rows = <List<Object?>>[
      [
        'Fecha',
        'Codigo',
        'Producto',
        'Tipo',
        'Cantidad',
        'Stock anterior',
        'Stock resultante',
        'Motivo',
        'Responsable',
      ],
      for (final movement in movements)
        [
          DateFormat('yyyy-MM-dd HH:mm:ss').format(movement.createdAt),
          movement.productCode ?? '',
          movement.productName ?? '',
          movement.type.label,
          movement.quantity,
          movement.previousStock,
          movement.resultingStock,
          movement.reason,
          movement.responsible,
        ],
    ];

    return _write(rows, AppConstants.movementsCsvFileNamePrefix);
  }

  // addBom makes Excel render the accented characters correctly.
  static final Csv _csv = Csv(addBom: true);

  Future<File> _write(List<List<Object?>> rows, String prefix) async {
    final content = _csv.encoder.convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${_stamp.format(DateTime.now())}.csv';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(content, flush: true);
    return file;
  }
}
