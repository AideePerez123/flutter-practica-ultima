import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a scannable Code 128 barcode for a product code.
class BarcodePreview extends StatelessWidget {
  const BarcodePreview({
    super.key,
    required this.data,
    this.height = 90,
    this.showText = true,
  });

  final String data;
  final double height;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return BarcodeWidget(
      barcode: Barcode.code128(),
      data: data,
      height: height,
      drawText: showText,
      style: const TextStyle(fontSize: 12, letterSpacing: 1.2),
    );
  }
}

/// Renders a QR code for the given payload.
class QrPreview extends StatelessWidget {
  const QrPreview({
    super.key,
    required this.data,
    this.size = 180,
    this.foregroundColor,
  });

  final String data;
  final double size;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor ?? Colors.black,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor ?? Colors.black,
      ),
    );
  }
}
