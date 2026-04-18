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
  List<Factura> _todasFacturas = [];
  List<Factura> _filtrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await _service.obtenerFacturas();
    print("Facturas cargadas: $lista"); // <--- AGREGA ESTO
    if (mounted) {
      setState(() {
        _todasFacturas = lista;
        _filtrados = lista;
        _cargando = false;
      });
    }
  }

  void _filtrar(String query) {
    setState(() {
      _filtrados = _todasFacturas
          .where(
            (f) =>
                (f.proveedor).toLowerCase().contains(query.toLowerCase()) ||
                (f.numeroFactura ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Historial de Gastos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por proveedor o número...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _filtrados.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filtrados.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  FacturaCard(factura: _filtrados[index]),
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
          Text(
            _todasFacturas.isEmpty
                ? 'No hay facturas registradas aún'
                : 'No se encontraron resultados',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
