import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:build_check_app/models/factura_model.dart';
import 'package:build_check_app/services/factura_service.dart';
import 'package:build_check_app/ui/shared/widgets/form_utils.dart';
import 'package:build_check_app/enum/unidad_medida.dart';

class FacturaOcrReviewSheet extends StatefulWidget {
  final Factura facturaExtraida;
  final Uint8List? imageBytes;

  const FacturaOcrReviewSheet({
    super.key,
    required this.facturaExtraida,
    this.imageBytes,
  });

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
  Uint8List? _imageBytes;
  late List<FacturaMaterialItem> _items;
  final List<TextEditingController> _itemNombreCtrls = [];
  final List<TextEditingController> _itemCantidadCtrls = [];
  final List<TextEditingController> _itemPrecioCtrls = [];
  final List<UnidadMedida> _itemUnidades = [];

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

    _imageBytes = widget.imageBytes;

    _items = widget.facturaExtraida.items
        .map(
          (item) => FacturaMaterialItem(
            materialId: item.materialId,
            nombre: item.nombre,
            cantidad: item.cantidad,
            precioUnitario: item.precioUnitario,
            unidadMedida: item.unidadMedida,
            usuarioId: item.usuarioId,
            fechaCreacion: item.fechaCreacion,
          ),
        )
        .toList();
    if (_items.isEmpty) {
      _addItem();
    } else {
      for (final item in _items) {
        _itemNombreCtrls.add(TextEditingController(text: item.nombre));
        _itemCantidadCtrls.add(
          TextEditingController(
            text: item.cantidad == 0 ? '' : item.cantidad.toString(),
          ),
        );
        _itemPrecioCtrls.add(
          TextEditingController(
            text: item.precioUnitario == 0 ? '' : item.precioUnitario.toString(),
          ),
        );
        _itemUnidades.add(item.unidadMedida);
      }
    }
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
    _syncItemsFromInputs();

    if (_items.isEmpty) {
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
      items: _items,
      fechaCreacion: widget.facturaExtraida.fechaCreacion,
    );

    final service = FacturaService();
    final success = _imageBytes == null
        ? await service.registrarFacturaManual(facturaAGuardar)
        : await service.registrarFacturaConImagen(
            factura: facturaAGuardar,
            bytes: _imageBytes!,
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
            _buildItemsEditor(),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
                label: const Text(
                  'Agregar material',
                  style: TextStyle(color: Color(0xFF4CAF50)),
                ),
              ),
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

  Widget _buildItemsEditor() {
    return Column(
      children: List.generate(_items.length, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildItemField(
                      'Material',
                      _itemNombreCtrls[index],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildItemField(
                      'Cant',
                      _itemCantidadCtrls[index],
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildUnidadDropdown(index),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildItemField(
                      'Valor unitario',
                      _itemPrecioCtrls[index],
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.redAccent,
                    tooltip: 'Eliminar material',
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _buildUnidadDropdown(int index) {
    return DropdownButtonFormField<UnidadMedida>(
      value: _itemUnidades[index],
      items: UnidadMedida.values
          .map(
            (unidad) => DropdownMenuItem(
              value: unidad,
              child: Text(
                unidad.nombre,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _itemUnidades[index] = value);
      },
      decoration: InputDecoration(
        labelText: 'Unidad',
        labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  void _addItem() {
    setState(() {
      final newItem = FacturaMaterialItem(
        materialId: null,
        nombre: '',
        cantidad: 0,
        precioUnitario: 0,
        unidadMedida: UnidadMedida.UNIDAD,
        usuarioId: widget.facturaExtraida.usuarioId,
        fechaCreacion: null,
      );
      _items.add(newItem);
      _itemNombreCtrls.add(TextEditingController());
      _itemCantidadCtrls.add(TextEditingController());
      _itemPrecioCtrls.add(TextEditingController());
      _itemUnidades.add(UnidadMedida.UNIDAD);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _itemNombreCtrls.removeAt(index).dispose();
      _itemCantidadCtrls.removeAt(index).dispose();
      _itemPrecioCtrls.removeAt(index).dispose();
      _itemUnidades.removeAt(index);
    });
  }

  void _syncItemsFromInputs() {
    final List<FacturaMaterialItem> updated = [];

    for (int i = 0; i < _items.length; i++) {
      final nombre = _itemNombreCtrls[i].text.trim();
      final cantidad = double.tryParse(_itemCantidadCtrls[i].text) ?? 0;
      final precioUnitario = double.tryParse(_itemPrecioCtrls[i].text) ?? 0;
      final unidad = _itemUnidades[i];

      if (nombre.isEmpty && cantidad == 0 && precioUnitario == 0) {
        continue;
      }

      updated.add(
        FacturaMaterialItem(
          materialId: _items[i].materialId,
          nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
          cantidad: cantidad,
          precioUnitario: precioUnitario,
          unidadMedida: unidad,
          usuarioId: widget.facturaExtraida.usuarioId,
          fechaCreacion: _items[i].fechaCreacion,
        ),
      );
    }

    _items = updated;
  }

  @override
  void dispose() {
    for (final controller in _itemNombreCtrls) {
      controller.dispose();
    }
    for (final controller in _itemCantidadCtrls) {
      controller.dispose();
    }
    for (final controller in _itemPrecioCtrls) {
      controller.dispose();
    }
    _proveedorCtrl.dispose();
    _numeroCtrl.dispose();
    _valorCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }
}
