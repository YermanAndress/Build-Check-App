import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/factura_model.dart';

class FacturaDetailsScreen extends StatefulWidget {
  final Factura factura;
  const FacturaDetailsScreen({super.key, required this.factura});

  @override
  State<FacturaDetailsScreen> createState() => _FacturaDetailsState();
}

class _FacturaDetailsState extends State<FacturaDetailsScreen> {
  bool _isEditing = false;
  late TextEditingController _proveedorCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _obsCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _proveedorCtrl = TextEditingController(text: widget.factura.proveedor);
    _numeroCtrl = TextEditingController(text: widget.factura.numeroFactura);
    _obsCtrl = TextEditingController(text: widget.factura.observaciones);
  }

  Future<void> _guardarCambios() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura actualizada correctamente ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fMoneda = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );
    final fFecha = DateFormat('dd MMMM yyyy', 'es_ES');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Factura' : 'Detalle de Factura'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalHeader(fMoneda),
            const SizedBox(height: 20),

            _buildInfoCard(fFecha),
            const SizedBox(height: 20),

            const Text(
              "Materiales Incluidos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildItemsList(fMoneda),

            const SizedBox(height: 30),

            if (_isEditing) _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalHeader(NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "VALOR TOTAL",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(widget.factura.valorTotal ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DateFormat dateFormatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildField('Proveedor', _proveedorCtrl, Icons.business),
          const Divider(height: 30),
          _buildField('Número de Factura', _numeroCtrl, Icons.tag),
          const Divider(height: 30),
          _buildReadOnlyInfo(
            'Fecha de Emisión',
            dateFormatter.format(widget.factura.fecha),
            Icons.calendar_today,
          ),
          const Divider(height: 30),
          _buildField('Observaciones', _obsCtrl, Icons.notes),
        ],
      ),
    );
  }

  Widget _buildItemsList(NumberFormat currencyFormatter) {
    if (widget.factura.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Esta factura no tiene materiales registrados."),
        ),
      );
    }
    return Column(
      children: widget.factura.items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.build, color: Color(0xFF4CAF50), size: 20),
            ),
            title: Text(
              item.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${item.cantidad} unidades x ${currencyFormatter.format(item.precioUnitario)}",
            ),
            trailing: Text(
              currencyFormatter.format(item.cantidad * item.precioUnitario),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _guardarCambios,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Actualizar Factura',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              )
            : Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
