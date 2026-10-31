import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/widgets/code_preview.dart';
import '../../domain/services/label_service.dart';
import '../../../products/domain/entities/product.dart';

/// Shows the barcode and QR for a product with print and share actions.
class LabelPage extends StatelessWidget {
  const LabelPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    const service = LabelService();

    return Scaffold(
      appBar: AppBar(title: const Text('Etiqueta del producto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(product.code),
                  const SizedBox(height: 16),
                  BarcodePreview(data: product.code, height: 100),
                  const SizedBox(height: 16),
                  QrPreview(data: service.qrPayload(product), size: 170),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              final data = await service.buildLabelPdf(product);
              await Printing.layoutPdf(onLayout: (_) async => data);
            },
            icon: const Icon(Icons.print_outlined),
            label: const Text('Imprimir etiqueta'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final data = await service.buildLabelPdf(product);
              final file = XFile.fromData(
                data,
                name: 'etiqueta_${product.code}.pdf',
                mimeType: 'application/pdf',
              );
              await SharePlus.instance.share(
                ShareParams(files: [file], text: 'Etiqueta de ${product.name}'),
              );
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartir etiqueta'),
          ),
        ],
      ),
    );
  }
}
