import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:flutter/material.dart';

class EditarProyectoPage extends StatefulWidget {
  final Proyecto proyecto;
  const EditarProyectoPage({super.key, required this.proyecto});

  @override
  State<EditarProyectoPage> createState() => _EditarProyectoPageState();
}

class _EditarProyectoPageState extends State<EditarProyectoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _ubicacionCtrl;
  late TextEditingController _presupuestoCTrl;

  bool enviando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.proyecto.nombre);
    _descripcionCtrl = TextEditingController(text: widget.proyecto.descripcion);
    _ubicacionCtrl = TextEditingController(text: widget.proyecto.ubicacion);
    _presupuestoCTrl = TextEditingController(
      text: widget.proyecto.presupuesto.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Proyecto"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: "Descripcion"),
              ),
              TextFormField(
                controller: _ubicacionCtrl,
                decoration: const InputDecoration(labelText: "Ubicacion"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              TextFormField(
                controller: _presupuestoCTrl,
                decoration: const InputDecoration(labelText: "Presupuesto"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                ),
                onPressed: enviando ? null : _guardar,
                child: const Text("Guardar Cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => enviando = true);
    final service = ProyectoService();
    final actualizado = Proyecto(
      id: widget.proyecto.id,
      nombre: _nombreCtrl.text,
      descripcion: _descripcionCtrl.text,
      ubicacion: _ubicacionCtrl.text,
      presupuesto: double.parse(_presupuestoCTrl.text),
      estado: widget.proyecto.estado,
      fechaCreacion: widget.proyecto.fechaCreacion,
    );
    final ok = await service.actualizarProyecto(actualizado);
    if (ok && mounted) Navigator.pop(context, true);
    setState(() => enviando = false);
  }
}
