import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: Text(proyecto?.nombre ?? "Detalle del Proyecto"),
        backgroundColor: Colors.white,
        elevation: 0,
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
    return ListView(
      children: [
        _info("Nombre", p.nombre),
        _info("Descripcion", p.descripcion),
        _info("Ubicacion", p.ubicacion),
        _info("Presupuesto", "\$${p.presupuesto.toStringAsFixed(0)}"),
        _info("Estado", p.estado),
        _info("Fecha de creacion", p.fechaCreacion),
      ],
    );
  }

  Widget _info(String label, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
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
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
