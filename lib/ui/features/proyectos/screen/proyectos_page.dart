import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/ui/features/proyectos/widget/proyecto_details.dart';
import 'package:flutter/material.dart';

class ProyectosPage extends StatefulWidget {
  const ProyectosPage({super.key});

  @override
  State<ProyectosPage> createState() => _ProyectosPageState();
}

class _ProyectosPageState extends State<ProyectosPage> {
  final ProyectoService _service = ProyectoService();
  bool cargando = true;
  String? error;
  List<Proyecto> proyectos = [];

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
      proyectos = await _service.obtenerProyectos();
    } catch (e) {
      error = e.toString();
    }
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Proyectos"),
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
    if (proyectos.isEmpty) {
      return const Center(
        child: Text(
          "No hay proyectos registrados",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      itemCount: proyectos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = proyectos[i];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: Colors.white,
          title: Text(
            p.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("Estado: ${p.estado}\nCreado: ${p.fechaCreacion}"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProyectoDetails(proyectoId: p.id),
              ),
            );
          },
        );
      },
    );
  }
}
