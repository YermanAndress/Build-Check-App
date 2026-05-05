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
  late TextEditingController _estadoCtrl;

  bool enviando = false;

  final List<String> estados = ["Planificacion", "Ejecucion", "Terminado"];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Proyecto"),
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
                      color: Colors.black.withOpacity(0.05),
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
                    controller: _presupuestoCTrl,
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
                    value: _estadoCtrl.text,
                    decoration: const InputDecoration(
                      labelText: "Estado",
                      prefixIcon: Icon(
                        Icons.flag_outlined,
                        color: Colors.blueGrey,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Planificacion",
                        child: Text("Planificacion"),
                      ),
                      DropdownMenuItem(
                        value: "Ejecucion",
                        child: Text("Ejecucion"),
                      ),
                      DropdownMenuItem(
                        value: "Terminado",
                        child: Text("Terminado"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _estadoCtrl.text = value!);
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? "Requerido" : null,
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
                              "Guardar Cambios",
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
          ],
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
      estado: _estadoCtrl.text,
      fechaCreacion: widget.proyecto.fechaCreacion,
    );
    final ok = await service.actualizarProyecto(actualizado);
    if (ok && mounted) Navigator.pop(context, true);
    setState(() => enviando = false);
  }
}
