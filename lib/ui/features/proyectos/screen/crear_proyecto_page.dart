import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:flutter/material.dart';

class CrearProyectoPage extends StatefulWidget {
  const CrearProyectoPage({super.key});

  @override
  State<CrearProyectoPage> createState() => _CrearProyectoPageState();
}

class _CrearProyectoPageState extends State<CrearProyectoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _presupuestoCTrl = TextEditingController();

  bool enviando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Proyecto"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
                  backgroundColor: const Color(0xFF4CA450),
                ),
                onPressed: enviando ? null : _guardar,
                child: const Text("Guardar"),
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
    final proyecto = Proyecto(
      id: 0,
      nombre: _nombreCtrl.text,
      descripcion: _descripcionCtrl.text,
      ubicacion: _ubicacionCtrl.text,
      presupuesto: double.parse(_presupuestoCTrl.text),
      estado: "Planificacion",
      fechaCreacion: "",
    );
    final ok = await service.crearProyecto(proyecto);
    if (ok && mounted) Navigator.pop(context, true);
    setState(() => enviando = false);
  }
}
