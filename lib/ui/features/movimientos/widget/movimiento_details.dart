import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:build_check_app/models/movimiento_model.dart';
import 'package:build_check_app/services/movimiento_service.dart';

class MovimientoDetailScreen extends StatefulWidget {
  final MovimientoResumen movimiento;
  const MovimientoDetailScreen({super.key, required this.movimiento});

  @override
  State<MovimientoDetailScreen> createState() => _MovimientoDetailScreenState();
}

class _MovimientoDetailScreenState extends State<MovimientoDetailScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _cantidadCtrl;
  String _tipoSeleccionado = '';

  @override
  void initState() {
    super.initState();
    _cantidadCtrl = TextEditingController(
      text: widget.movimiento.cantidad % 1 == 0
          ? widget.movimiento.cantidad.toInt().toString()
          : widget.movimiento.cantidad.toString(),
    );
    _tipoSeleccionado = widget.movimiento.tipoMovimiento;
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    final int? id = widget.movimiento.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede editar: ID no disponible')),
      );
      return;
    }

    final double? nuevaCantidad = double.tryParse(_cantidadCtrl.text.trim());
    if (nuevaCantidad == null || nuevaCantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'tipoMovimiento': _tipoSeleccionado,
      'cantidad': nuevaCantidad,
      'fecha': DateFormat('yyyy-MM-dd').format(widget.movimiento.fecha),
      if (widget.movimiento.materialId != null)
        'materialId': widget.movimiento.materialId,
      if (widget.movimiento.proyectoId != null)
        'proyectoId': widget.movimiento.proyectoId,
    };

    final ok = await MovimientoService().actualizarMovimiento(id, data);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (ok) _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Movimiento actualizado correctamente ✓'
                : 'Error al actualizar el movimiento',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esEntrada = _tipoSeleccionado == 'ENTRADA';
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Editar Movimiento' : 'Detalle del Movimiento'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                // Restaurar valores si se cancela
                if (!_isEditing) {
                  _cantidadCtrl.text =
                      widget.movimiento.cantidad % 1 == 0
                          ? widget.movimiento.cantidad.toInt().toString()
                          : widget.movimiento.cantidad.toString();
                  _tipoSeleccionado = widget.movimiento.tipoMovimiento;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cabecera con ícono grande
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  esEntrada
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 50,
                  color: esEntrada
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE53935),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Badge / Selector de tipo
            _isEditing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['ENTRADA', 'SALIDA'].map((tipo) {
                      final selected = _tipoSeleccionado == tipo;
                      final color = tipo == 'ENTRADA'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _tipoSeleccionado = tipo),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color),
                          ),
                          child: Text(
                            tipo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                              color: selected ? Colors.white : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: esEntrada
                          ? const Color(0xFFF0F7F0)
                          : const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _tipoSeleccionado,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1,
                        color: esEntrada
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ),

            const SizedBox(height: 30),

            // Tarjeta de información
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Material (solo lectura siempre)
                  _buildReadOnlyInfo(
                    'Material',
                    widget.movimiento.materialNombre.isNotEmpty
                        ? widget.movimiento.materialNombre
                        : 'Material #${widget.movimiento.materialId ?? '—'}',
                    Icons.inventory_2_outlined,
                  ),
                  const Divider(height: 30),

                  // Cantidad (editable)
                  _buildField(
                    'Cantidad',
                    _cantidadCtrl,
                    Icons.straighten,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    valueColor: esEntrada
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE53935),
                  ),
                  const Divider(height: 30),

                  // Fecha (solo lectura)
                  _buildReadOnlyInfo(
                    'Fecha del Movimiento',
                    dateFormat.format(widget.movimiento.fecha),
                    Icons.calendar_today_outlined,
                  ),
                  const Divider(height: 30),

                  // Registrado (solo lectura)
                  _buildReadOnlyInfo(
                    'Registrado',
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(widget.movimiento.fechaCreacion),
                    Icons.access_time_outlined,
                    valueColor: Colors.blueGrey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            if (_isEditing)
              SizedBox(
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
                          'Guardar Cambios',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                ),
              )
            : Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: valueColor ?? const Color(0xFF4CAF50)),
                  const SizedBox(width: 10),
                  Text(
                    controller.text.isEmpty ? '—' : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? const Color(0xFF263238),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildReadOnlyInfo(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? const Color(0xFF263238),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}