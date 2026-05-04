import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/ui/features/proyectos/screen/crear_proyecto_page.dart';
import 'package:build_check_app/ui/features/proyectos/widget/proyecto_card.dart';
import 'package:build_check_app/ui/features/proyectos/widget/proyecto_details.dart';
import 'package:flutter/material.dart';

class ProyectosPage extends StatefulWidget {
  const ProyectosPage({super.key});

  @override
  State<ProyectosPage> createState() => _ProyectosPageState();
}

class _ProyectosPageState extends State<ProyectosPage> {
  final ProyectoService _service = ProyectoService();
  final TextEditingController _searchCtrl = TextEditingController();
  bool cargando = true;
  String? error;
  List<Proyecto> proyectos = [];
  List<Proyecto> filtrados = [];

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
      filtrados = proyectos;
    } catch (e) {
      error = e.toString();
    }
    setState(() => cargando = false);
  }

  void _filtrar(String texto) {
    texto = texto.toLowerCase();
    setState(() {
      filtrados = proyectos.where((p) {
        return p.nombre.toLowerCase().contains(texto) ||
            p.estado.toLowerCase().contains(texto);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CrearProyectoPage()),
          );
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Lista de Proyectos",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchCtrl,
                onChanged: _filtrar,
                decoration: InputDecoration(
                  hintText: "Buscar proyecto...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4CAF50),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
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
    if (filtrados.isEmpty) {
      return const Center(
        child: Text(
          "No hay coincidencias",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      itemCount: filtrados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = filtrados[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProyectoDetails(proyectoId: p.id),
              ),
            );
          },
          child: ProyectoCard(proyecto: p),
        );
      },
    );
  }
}
