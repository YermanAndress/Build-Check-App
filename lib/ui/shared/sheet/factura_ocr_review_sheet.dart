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
    _proveedorCtrl =
        TextEditingController(text: widget.facturaExtraida.proveedor);
    _numeroCtrl =
        TextEditingController(text: widget.facturaExtraida.numeroFactura);
    _valorCtrl = TextEditingController(
        text: widget.facturaExtraida.valorTotal?.toString() ?? '');

    _fechaSeleccionada = widget.facturaExtraida.fecha;
    _fechaCtrl =
        TextEditingController(text: _dateFormat.format(_fechaSeleccionada));
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
    setState(() => _enviando = true);

    // Actualizar el objeto factura con los datos editados
    final facturaAGuardar = Factura(
      id: widget.facturaExtraida.id,
      numeroFactura: _numeroCtrl.text,
      fecha: _fechaSeleccionada,
      proveedor: _proveedorCtrl.text.isEmpty ? 'Desconocido' : _proveedorCtrl.text,
      observaciones: widget.facturaExtraida.observaciones,
      valorTotal: double.tryParse(_valorCtrl.text) ?? widget.facturaExtraida.valorTotal,
      proyectoId: widget.facturaExtraida.proyectoId,
      urlImagen: widget.facturaExtraida.urlImagen,
      items: widget.facturaExtraida.items,
    );

    final success = await FacturaService().registrarFacturaManual(facturaAGuardar);

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
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              'Proveedor',
              _proveedorCtrl,
              Icons.business,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              'Número de Factura',
              _numeroCtrl,
              Icons.receipt,
            ),
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
            BotonEnviar(
              enviando: _enviando,
              label: 'CONFIRMAR Y GUARDAR',
              onTap: _guardarFactura,
            ),
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
