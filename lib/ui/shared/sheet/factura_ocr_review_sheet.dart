import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:build_check_app/models/factura_model.dart';
import 'package:build_check_app/services/factura_service.dart';
import 'package:build_check_app/ui/shared/widgets/form_utils.dart';

class FacturaOcrReviewSheet extends StatefulWidget {
  final Factura facturaExtraida;

  const FacturaOcrReviewSheet({super.key, required this.facturaExtraida});

  @override
  State<FacturaOcrReviewSheet> createState() => _FacturaOcrReviewSheetState();
}

class _FacturaOcrReviewSheetState extends State<FacturaOcrReviewSheet> {
  late TextEditingController _proveedorCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _valorCtrl;
  late TextEditingController _fechaCtrl;
  late DateTime _fechaSeleccionada;
  bool _enviando = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _proveedorCtrl = TextEditingController(
      text: widget.facturaExtraida.proveedor,
    );
    _numeroCtrl = TextEditingController(
      text: widget.facturaExtraida.numeroFactura,
    );
    _valorCtrl = TextEditingController(
      text: widget.facturaExtraida.valorTotal?.toString() ?? '',
    );

    _fechaSeleccionada = widget.facturaExtraida.fecha;
    _fechaCtrl = TextEditingController(
      text: _dateFormat.format(_fechaSeleccionada),
    );
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
        _fechaCtrl.text = _dateFormat.format(_fechaSeleccionada);
      });
    }
  }

  Future<void> _guardarFactura() async {
    // Validar que items no esté vacío
    if (widget.facturaExtraida.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materiales es un campo obligatorio'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    // Actualizar el objeto factura con los datos editados
    final facturaAGuardar = Factura(
      id: widget.facturaExtraida.id,
      numeroFactura: _numeroCtrl.text,
      fecha: _fechaSeleccionada,
      proveedor: _proveedorCtrl.text.isEmpty
          ? 'Desconocido'
          : _proveedorCtrl.text,
      observaciones: widget.facturaExtraida.observaciones,
      valorTotal:
          double.tryParse(_valorCtrl.text) ?? widget.facturaExtraida.valorTotal,
      proyectoId: widget.facturaExtraida.proyectoId,
      usuarioId: widget.facturaExtraida.usuarioId,
      urlImagen: widget.facturaExtraida.urlImagen,
      items: widget.facturaExtraida.items,
      fechaCreacion: widget.facturaExtraida.fechaCreacion,
    );

    final success = await FacturaService().registrarFacturaManual(
      facturaAGuardar,
    );

    if (mounted) {
      setState(() => _enviando = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura guardada exitosamente ✓'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true); // Regresar con éxito
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la factura'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const Text(
              'Revisar Datos de IA',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Por favor, revisa y corrige los datos extraídos por la IA antes de guardarlos.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Proveedor', _proveedorCtrl, Icons.business),
            const SizedBox(height: 12),
            _buildTextField('Número de Factura', _numeroCtrl, Icons.receipt),
            const SizedBox(height: 12),
            _buildTextField(
              'Fecha de Emisión',
              _fechaCtrl,
              Icons.calendar_today,
              readOnly: true,
              onTap: () => _seleccionarFecha(context),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Valor Total',
              _valorCtrl,
              Icons.attach_money,
              isNumber: true,
            ),
            const SizedBox(height: 32),
            // Sección de Materiales/Items
            const Text(
              'Materiales Detectados por IA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.facturaExtraida.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No se detectaron materiales. Debes agregar al menos uno.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.facturaExtraida.items.length,
                itemBuilder: (context, index) {
                  final item = widget.facturaExtraida.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cantidad: ${item.cantidad} ${item.unidadMedida.nombre}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              'Precio Unit: \$${item.precioUnitario}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Subtotal: \$${(item.cantidad * item.precioUnitario).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  void dispose() {
    _proveedorCtrl.dispose();
    _numeroCtrl.dispose();
    _valorCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }
}
