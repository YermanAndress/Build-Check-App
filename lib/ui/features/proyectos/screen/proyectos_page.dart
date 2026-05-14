import 'package:flutter/material.dart';

import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/services/role_helper.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/ui/features/proyectos/screen/crear_proyecto_page.dart';
import 'package:build_check_app/ui/features/proyectos/widget/proyecto_card.dart';
import 'package:build_check_app/ui/features/proyectos/widget/proyecto_details.dart';
import 'package:build_check_app/ui/features/proyectos/widget/unirse_proyecto_dialog.dart';
import 'package:build_check_app/services/secure_storage.dart';

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
  bool _puedeCrear = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarPermiso();
  }

  Future<void> _cargarPermiso() async {
    final puede = RoleHelper.puedeGestionarProyectos();
    if (mounted) setState(() => _puedeCrear = puede);
  }

  Future<void> _seleccionarProyecto(Proyecto proyecto) async {
    try {
      final result = await _service.seleccionarProyecto(proyecto.id!);
      await ProyectoActual.set(proyecto.id!, rol: result['rol_proyecto']);
      await SecureStorage.save("accessToken", result['accessToken']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al seleccionar proyecto: $e")),
      );
    }
  }

  Future<void> _cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      proyectos = await _service.obtenerMisProyectos();
      if (_searchCtrl.text.isNotEmpty) {
        _filtrar(_searchCtrl.text);
      } else {
        filtrados = proyectos;
      }
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "join_project",
            backgroundColor: const Color(0xFF2196F3),
            child: const Icon(Icons.link, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const UnirseProyectoDialog(),
              ).then((value) {
                if (value == true) {
                  _cargar();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (_puedeCrear)
            FloatingActionButton(
              heroTag: "create_project",
              backgroundColor: const Color(0xFF4CAF50),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearProyectoPage()),
                ).then((value) {
                  if (value == true) {
                    _cargar();
                  }
                });
              },
            ),
        ],
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
    final activos = <Proyecto>[];
    final otros = <Proyecto>[];
    final activoId = ProyectoActual.id;
    for (final proyecto in filtrados) {
      if (activoId != null && proyecto.id == activoId) {
        activos.add(proyecto);
      } else {
        otros.add(proyecto);
      }
    }
    final ordenados = [...activos, ...otros];

    return ListView.separated(
      itemCount: ordenados.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = ordenados[i];
        return ProyectoCard(
          proyecto: p,
          esActivo: p.id == activoId,
          onTap: () async {
            await _seleccionarProyecto(p);
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProyectoDetails(
                  proyectoId: p.id!,
                  rolEnProyecto: p.rolProyecto,
                ),
              ),
            ).then((value) {
              if (value == true) _cargar();
            });
          },
        );
      },
    );
  }
}
