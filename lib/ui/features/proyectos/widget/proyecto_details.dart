import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/ui/features/proyectos/screen/editar_proyecto_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProyectoDetails extends StatefulWidget {
  final int proyectoId;
  const ProyectoDetails({super.key, required this.proyectoId});

  @override
  State<ProyectoDetails> createState() => _ProyectoDetailsState();
}

class _ProyectoDetailsState extends State<ProyectoDetails> {
  final ProyectoService _service = ProyectoService();

  bool cargando = true;
  String? error;
  Proyecto? proyecto;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      proyecto = await _service.obtenerProyecto(widget.proyectoId);
    } catch (e) {
      error = e.toString();
    }

    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(proyecto?.nombre ?? "Detalle del Proyecto"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (proyecto != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditarProyectoPage(proyecto: proyecto!),
                  ),
                ).then((value) {
                  if (value == true) {
                    _cargar();
                  }
                });
              },
            ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }
    if (error != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 10),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _cargar, child: const Text("Reintentar")),
          ],
        ),
      );
    }
    final p = proyecto!;
    return SingleChildScrollView(
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info("Nombre", p.nombre, Icons.title),
                const Divider(height: 30),
                _info("Descripcion", p.descripcion, Icons.description_outlined),
                const Divider(height: 30),
                _info("Ubicacion", p.ubicacion, Icons.location_on_outlined),
                const Divider(height: 30),
                _info(
                  "Presupuesto",
                  "\$${p.presupuesto.toStringAsFixed(0)}",
                  Icons.attach_money,
                ),
                const Divider(height: 30),
                _info("Estado", p.estado, Icons.flag_outlined),
                const Divider(height: 30),
                _info(
                  "Fecha de creacion",
                  DateFormat('dd/MM/yyyy HH:mm').format(p.fechaCreacionDate),
                  Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String valor, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 20, color: Color(0xFF4CAF50)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                valor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
