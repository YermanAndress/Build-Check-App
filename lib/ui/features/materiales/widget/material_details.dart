import 'package:build_check_app/enum/unidad_medida.dart';
import 'package:build_check_app/services/role_helper.dart';
import 'package:flutter/material.dart';

import 'package:build_check_app/models/material_model.dart';

class MaterialDetailScreen extends StatefulWidget {
  final MaterialItem material;
  const MaterialDetailScreen({super.key, required this.material});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nombreCtrl;
  bool _isSaving = false;
  bool _puedeEditar = false;
  UnidadMedida? _unidadSeleccionada;

  @override
  void initState() {
    super.initState();
    _puedeEditar = RoleHelper.puedeGestionarMateriales();
    _nombreCtrl = TextEditingController(text: widget.material.nombre);

    _unidadSeleccionada = UnidadMedida.values.firstWhere(
      (e) => e.name == widget.material.unidadMedida,
      orElse: () => UnidadMedida.UNIDAD,
    );
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
        const SnackBar(content: Text('Material actualizado correctamente ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Material' : 'Detalle del Material'),
        actions: [
          if (_puedeEditar)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: (0.05)),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2,
                  size: 50,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    'Nombre del Material',
                    _nombreCtrl,
                    Icons.label_outline,
                  ),
                  // Dropdown de unidad de medida
                  DropdownButtonFormField<UnidadMedida>(
                    initialValue: _unidadSeleccionada,
                    decoration: const InputDecoration(
                      labelText: "Unidad de Medida",
                      prefixIcon: Icon(
                        Icons.rule_outlined,
                        color: Colors.blueGrey,
                      ),
                    ),
                    items: UnidadMedida.values.map((unidad) {
                      return DropdownMenuItem<UnidadMedida>(
                        value: unidad,
                        child: Text(unidad.nombre),
                      );
                    }).toList(),
                    onChanged: _isEditing
                        ? (value) {
                            setState(() {
                              _unidadSeleccionada = value;
                            });
                          }
                        : null, // Deshabilitar si no está en modo edición
                    validator: (value) => value == null ? "Requerido" : null,
                  ),
                  _buildReadOnlyInfo(
                    'Stock Actual',
                    '${widget.material.stockActual} ${widget.material.unidadMedida}',
                    Icons.storage,
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
                  Text(
                    controller.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
