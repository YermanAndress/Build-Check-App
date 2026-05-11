import 'package:flutter/material.dart';

import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';

class EditarProyectoPage extends StatefulWidget {
  final Proyecto proyecto;
  final String? rolEnProyecto;
  const EditarProyectoPage({
    super.key,
    required this.proyecto,
    this.rolEnProyecto,
  });

  @override
  State<EditarProyectoPage> createState() => _EditarProyectoPageState();
}

class _EditarProyectoPageState extends State<EditarProyectoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _ubicacionCtrl;
  late TextEditingController _presupuestoCTrl;
  late TextEditingController _estadoCtrl;

  bool enviando = false;

  final List<String> estados = ["PENDIENTE", "EN_PROGRESO", "COMPLETADO"];

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.proyecto.nombre);
    _descripcionCtrl = TextEditingController(text: widget.proyecto.descripcion);
    _ubicacionCtrl = TextEditingController(text: widget.proyecto.ubicacion);
    _presupuestoCTrl = TextEditingController(
      text: widget.proyecto.presupuesto.toString(),
    );
    _estadoCtrl = TextEditingController(text: widget.proyecto.estado);
  }

  bool get _tienePermiso =>
      widget.rolEnProyecto == 'ROLE_OWNER' ||
      widget.rolEnProyecto == 'ROLE_ADMIN';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !enviando,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Editar Proyecto"),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_tienePermiso) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'No tienes permisos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo OWNER y ADMIN pueden editar proyectos',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.apartment_rounded,
                size: 50,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  enabled: !enviando,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    prefixIcon: Icon(Icons.title, color: Colors.blueGrey),
                  ),
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                TextFormField(
                  controller: _descripcionCtrl,
                  enabled: !enviando,
                  decoration: const InputDecoration(
                    labelText: "Descripcion",
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _ubicacionCtrl,
                  enabled: !enviando,
                  decoration: const InputDecoration(
                    labelText: "Ubicacion",
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: Colors.blueGrey,
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                TextFormField(
                  controller: _presupuestoCTrl,
                  enabled: !enviando,
                  decoration: const InputDecoration(
                    labelText: "Presupuesto",
                    prefixIcon: Icon(
                      Icons.attach_money,
                      color: Colors.blueGrey,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Requerido" : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _estadoCtrl.text,
                  decoration: const InputDecoration(
                    labelText: "Estado",
                    prefixIcon: Icon(
                      Icons.flag_outlined,
                      color: Colors.blueGrey,
                    ),
                  ),
                  items: estados
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: enviando
                      ? null
                      : (value) {
                          setState(() => _estadoCtrl.text = value!);
                        },
                  validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: enviando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: enviando
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => enviando = true);

    try {
      final proyectoActualizado = Proyecto(
        id: widget.proyecto.id,
        nombre: _nombreCtrl.text,
        descripcion: _descripcionCtrl.text,
        ubicacion: _ubicacionCtrl.text,
        presupuesto: double.parse(_presupuestoCTrl.text),
        estado: _estadoCtrl.text,
        fechaCreacion: widget.proyecto.fechaCreacion,
        rolProyecto: widget.rolEnProyecto,
      );

      await ProyectoService().actualizarProyecto(proyectoActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proyecto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      if (mounted) {
        if (e.toString().contains('403')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes permisos para editar este proyecto'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      setState(() => enviando = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _presupuestoCTrl.dispose();
    _estadoCtrl.dispose();
    super.dispose();
  }
}
