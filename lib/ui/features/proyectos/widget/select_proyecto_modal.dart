import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';

class SelectProyectoModal extends StatefulWidget {
  final Function(Proyecto)? onProyectoSelected;

  const SelectProyectoModal({super.key, this.onProyectoSelected});

  @override
  State<SelectProyectoModal> createState() => _SelectProyectoModalState();
}

class _SelectProyectoModalState extends State<SelectProyectoModal> {
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
      proyectos = await _service.obtenerMisProyectos();
      if (proyectos.isEmpty) {
        error = "No tienes proyectos. Crea uno o pide que te inviten.";
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() => cargando = false);
  }

  Future<void> _seleccionarProyecto(Proyecto proyecto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("proyectoActual", proyecto.id!);
    
    if (mounted) {
      widget.onProyectoSelected?.call(proyecto);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selecciona un Proyecto",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Elige el proyecto con el que deseas trabajar",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      );
    }

    if (proyectos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              "No tienes proyectos",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a crear proyecto
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text("Crear Proyecto"),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: proyectos.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final proyecto = proyectos[index];
        return InkWell(
          onTap: () => _seleccionarProyecto(proyecto),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proyecto.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  proyecto.descripcion ?? "Sin descripción",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(proyecto.estado),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        proyecto.estado,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'en_progreso':
        return const Color(0xFF2196F3);
      case 'completado':
        return const Color(0xFF4CAF50);
      case 'pendiente':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
