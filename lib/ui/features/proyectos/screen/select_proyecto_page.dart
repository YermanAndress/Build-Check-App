import 'package:flutter/material.dart';

import 'package:build_check_app/ui/main_screen.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:build_check_app/ui/features/proyectos/screen/crear_proyecto_page.dart';
import 'package:build_check_app/ui/features/proyectos/widget/unirse_proyecto_dialog.dart';

class SelectProyectoPage extends StatefulWidget {
  const SelectProyectoPage({super.key});

  @override
  State<SelectProyectoPage> createState() => _SelectProyectoPageState();
}

class _SelectProyectoPageState extends State<SelectProyectoPage> {
  final ProyectoService _service = ProyectoService();
  bool _cargando = true;
  String? _error;
  List<Proyecto> _proyectos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _proyectos = await _service.obtenerMisProyectos();
      if (mounted) {
        setState(() => _cargando = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _seleccionar(Proyecto proyecto) async {
    try {
      final resultado = await _service.seleccionarProyecto(proyecto.id!);
      await SecureStorage.save("accessToken", resultado['accessToken']);
      await ProyectoActual.set(
        resultado['proyecto_id'],
        rol: resultado['rol_proyecto'],
      );

      print("Proyecto seleccionado: ${proyecto.id}");
      print("Resultado del servicio: $resultado");
      print("proyecto_id: ${resultado['proyecto_id']}");
      print("rol_proyecto: ${resultado['rol_proyecto']}");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _abrirCrear() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CrearProyectoPage()),
    );
    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _abrirUnirse() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const UnirseProyectoDialog(),
    );
    if (result == true && mounted) {
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 54,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Selecciona un Proyecto',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Elige el proyecto con el que deseas trabajar',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(child: _buildBody()),
                const SizedBox(height: 16),
                if (!_cargando)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _abrirUnirse,
                          icon: const Icon(Icons.link),
                          label: const Text('Unirse con Token'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF2196F3)),
                            foregroundColor: const Color(0xFF2196F3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _abrirCrear,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Proyecto'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_proyectos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aún no perteneces a ningún proyecto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa los botones de abajo para crear uno nuevo\no unirte con un token de invitación',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _proyectos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = _proyectos[index];
        return _ProyectoTile(proyecto: p, onTap: () => _seleccionar(p));
      },
    );
  }
}

class _ProyectoTile extends StatelessWidget {
  final Proyecto proyecto;
  final VoidCallback onTap;

  const _ProyectoTile({required this.proyecto, required this.onTap});

  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'EN_PROGRESO':
        return const Color(0xFF2196F3);
      case 'COMPLETADO':
        return const Color(0xFF4CAF50);
      case 'PENDIENTE':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_outlined,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proyecto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF263238),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proyecto.descripcion.isEmpty
                          ? 'Sin descripción'
                          : proyecto.descripcion,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _colorEstado(proyecto.estado),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  proyecto.estado.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
