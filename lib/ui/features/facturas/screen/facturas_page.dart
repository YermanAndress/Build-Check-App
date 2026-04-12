import 'package:flutter/material.dart';

import '../../../../models/factura_model.dart';
import '../../../../services/factura_service.dart';

import '../widget/factura_card.dart';

class FacturasPage extends StatefulWidget {
  const FacturasPage({super.key});

  @override
  State<FacturasPage> createState() => _FacturasScreenState();
}

class _FacturasScreenState extends State<FacturasPage> {
  final FacturaService _service = FacturaService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Historial de Gastos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Factura>>(
        future: _service.obtenerFacturas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final facturas = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: facturas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                FacturaCard(factura: facturas[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No hay facturas registradas aún',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
