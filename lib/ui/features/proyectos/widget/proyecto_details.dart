<<<<<<< HEAD
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/services/role_helper.dart';
import 'package:build_check_app/ui/features/proyectos/screen/editar_proyecto_page.dart';
=======
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/ui/features/proyectos/screen/admin_proyecto_page.dart';
import 'package:build_check_app/ui/features/proyectos/screen/editar_proyecto_page.dart';

class ProyectoDetails extends StatefulWidget {
  final int proyectoId;
  final String? rolEnProyecto;
  const ProyectoDetails({
    super.key,
    required this.proyectoId,
    this.rolEnProyecto,
  });

  @override
  State<ProyectoDetails> createState() => _ProyectoDetailsState();
}

class _ProyectoDetailsState extends State<ProyectoDetails> {
  final ProyectoService _service = ProyectoService();

  bool cargando = true;
  String? error;
  Proyecto? proyecto;

  bool _puedeGestionar = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarPermiso();
  }

  Future<void> _cargarPermiso() async {
    final puede = await RoleHelper.puedeGestionarProyectos();
    if (mounted) setState(() => _puedeGestionar = puede);
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

  bool get _esAdmin =>
      widget.rolEnProyecto == 'ROLE_OWNER' ||
      widget.rolEnProyecto == 'ROLE_ADMIN';

  bool get _esOwner => widget.rolEnProyecto == 'ROLE_OWNER';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(proyecto?.nombre ?? "Detalle del Proyecto"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
<<<<<<< HEAD
          if (proyecto != null && _puedeGestionar)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
=======
          if (proyecto != null) ...[
            if (_esAdmin)
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                tooltip: 'Administrar proyecto',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminProyectoPage(proyecto: proyecto!),
                  ),
                ).then((_) => _cargar()),
              ),
            if (_esAdmin)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditarProyectoPage(
                          proyecto: proyecto!,
                          rolEnProyecto: widget.rolEnProyecto,
                        ),
                      ),
                    ).then((v) {
                      if (v == true) _cargar();
                    }),
              ),
            if (_esOwner)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _confirmarEliminar,
              ),
            const SizedBox(width: 4),
          ],
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
          if (widget.rolEnProyecto != null) ...[
            const SizedBox(height: 12),
            _RolBadge(rol: widget.rolEnProyecto!),
          ],
          if (!_esAdmin && widget.rolEnProyecto != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'No tienes permisos para administrar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
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
                _info(
                  "Estado",
                  p.estado.replaceAll('_', ' '),
                  Icons.flag_outlined,
                ),
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
            Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
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

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar Proyecto"),
        content: const Text("¿Seguro que deseas eliminar este proyecto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _service.eliminarProyecto(widget.proyectoId);
                if (mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proyecto eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _RolBadge extends StatelessWidget {
  final String rol;
  const _RolBadge({required this.rol});

  Color get _color {
    switch (rol) {
      case 'ROLE_OWNER':
        return const Color(0xFFFF9800);
      case 'ROLE_ADMIN':
        return const Color(0xFF2196F3);
      case 'ROLE_ALMACENISTA':
        return const Color(0xFF4CAF50);
      case 'ROLE_DIRECTOR_OBRA':
        return const Color(0xFF9C27B0);
      case 'ROLE_RESIDENTE':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String get _label => rol.replaceAll('ROLE_', '').replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Tu rol: $_label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
