import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../products/domain/entities/product.dart';

/// Generates printable labels containing the product name, code, a Code 128
/// barcode and a QR code.
///
/// The QR payload contains only the product code; stock is intentionally never
/// embedded because it changes with every movement.
class LabelService {
  const LabelService();

  /// Payload encoded into the QR code. Contains a stable identifier only.
  String qrPayload(Product product) => product.code;

  /// Renders a single label to a PDF document.
  Future<Uint8List> buildLabelPdf(Product product) async {
    final document = pw.Document();
    final barcodeData = _code128Svg(product.code);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Container(
            width: 300,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey700),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  product.name,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Código: ${product.code}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 12),
                pw.SvgImage(svg: barcodeData, height: 60),
                pw.SizedBox(height: 12),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrPayload(product),
                  width: 110,
                  height: 110,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return document.save();
  }

  /// Renders a sheet with several labels, three per row.
  Future<Uint8List> buildLabelsSheetPdf(List<Product> products) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final product in products) _labelWidget(product),
            ],
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _labelWidget(Product product) {
    return pw.Container(
      width: 170,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            product.name,
            maxLines: 2,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(product.code, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.BarcodeWidget(
            barcode: pw.Barcode.code128(),
            data: product.code,
            height: 34,
          ),
          pw.SizedBox(height: 4),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: qrPayload(product),
            width: 70,
            height: 70,
          ),
        ],
      ),
    );
  }

  String _code128Svg(String data) {
    final bc = Barcode.code128();
    return bc.toSvg(data, width: 220, height: 60, drawText: false);
  }
}
