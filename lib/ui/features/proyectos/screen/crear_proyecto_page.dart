import 'package:flutter/material.dart';

import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/services/secure_storage.dart';

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
  final _presupuestoCtrl = TextEditingController();
  String _estadoSeleccionado = "Pendiente";

  bool enviando = false;

  static const List<String> estadosDisponibles = [
    "Pendiente",
    "Planificacion",
    "Ejecucion",
    "Terminado",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Crear Proyecto"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      prefixIcon: Icon(Icons.title, color: Colors.blueGrey),
                    ),
                    validator: (v) => v!.isEmpty ? "Requerido" : null,
                  ),
                  TextFormField(
                    controller: _descripcionCtrl,
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
                    controller: _presupuestoCtrl,
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
                    initialValue: _estadoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: "Estado",
                      prefixIcon: Icon(
                        Icons.flag_outlined,
                        color: Colors.blueGrey,
                      ),
                    ),
                    items: estadosDisponibles
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e == "Pendiente"
                                  ? "Pendiente"
                                  : e == "Planificacion"
                                  ? "Planificacion"
                                  : e == "Ejecucion"
                                  ? "Ejecucion"
                                  : e == "Terminado"
                                  ? "Terminado"
                                  : "Ejecucion",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _estadoSeleccionado = value!);
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? "Requerido" : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: enviando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: enviando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Crear Proyecto",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => enviando = true);
    try {
      final service = ProyectoService();
      final proyecto = Proyecto(
        id: null,
        nombre: _nombreCtrl.text,
        descripcion: _descripcionCtrl.text,
        ubicacion: _ubicacionCtrl.text,
        presupuesto: double.parse(_presupuestoCtrl.text),
        estado: _estadoSeleccionado,
        fechaCreacion: "",
      );
      final created = await service.crearProyecto(proyecto);
      final resultado = await service.seleccionarProyecto(created.id!);

      if (mounted) {
        await SecureStorage.save("accessToken", resultado['accessToken']);
        await ProyectoActual.set(
          resultado['proyecto_id'],
          rol: resultado['rol_proyecto'],
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => enviando = false);
  }
}
