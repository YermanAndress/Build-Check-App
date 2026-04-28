import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:build_check_app/models/factura_model.dart';
import 'package:build_check_app/ui/features/facturas/widget/factura_details.dart';

import 'package:build_check_app/ui/shared/widgets/card_base.dart';

class FacturaCard extends StatelessWidget {
  final Factura factura;
  const FacturaCard({super.key, required this.factura});

  @override
  Widget build(BuildContext context) {
    final fMoneda = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );
    final fFecha = DateFormat('dd MMM yyyy', 'es_ES');

    return CardBase(
      icon: Icons.receipt_long_outlined,
      iconBackgroundColor: const Color(0xFFE3F2FD),
      iconColor: Colors.blue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacturaDetailsScreen(factura: factura),
          ),
        );
      },
      leftContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            factura.proveedor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF263238),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "Factura: ${factura.numeroFactura}",
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          Text(
            fFecha.format(factura.fecha),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fMoneda.format(factura.valorTotal ?? 0),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const Text(
            'Total Pago',
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
