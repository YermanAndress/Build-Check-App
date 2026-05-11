import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';

class AdminProyectoPage extends StatefulWidget {
  final Proyecto proyecto;

  const AdminProyectoPage({super.key, required this.proyecto});

  @override
  State<AdminProyectoPage> createState() => _AdminProyectoPageState();
}

class _AdminProyectoPageState extends State<AdminProyectoPage> {
  final ProyectoService _service = ProyectoService();
  int _selectedTab = 0;
  
  // Miembros
  List<Map<String, dynamic>> _miembros = [];
  bool _cargandoMiembros = false;

  // Invitaciones
  List<Map<String, dynamic>> _invitaciones = [];
  bool _cargandoInvitaciones = false;

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
    _cargarInvitaciones();
  }

  Future<void> _cargarMiembros() async {
    setState(() => _cargandoMiembros = true);
    try {
      final miembros = await _service.obtenerMiembros(widget.proyecto.id!);
      setState(() => _miembros = miembros);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar miembros: $e")),
      );
    }
    setState(() => _cargandoMiembros = false);
  }

  Future<void> _cargarInvitaciones() async {
    setState(() => _cargandoInvitaciones = true);
    try {
      final invitaciones =
          await _service.obtenerInvitaciones(widget.proyecto.id!);
      setState(() => _invitaciones = invitaciones);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar invitaciones: $e")),
      );
    }
    setState(() => _cargandoInvitaciones = false);
  }

  Future<void> _generarInvitacion() async {
    final rol = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rol para nuevo miembro"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            "ROLE_ALMACENISTA",
            "ROLE_DIRECTOR_OBRA",
            "ROLE_RESIDENTE",
          ]
              .map((r) => ListTile(
                    title: Text(r),
                    onTap: () => Navigator.pop(context, r),
                  ))
              .toList(),
        ),
      ),
    );

    if (rol != null) {
      try {
        final resultado = await _service.generarInvitacion(
          widget.proyecto.id!,
          rol,
        );
        if (mounted) {
          _mostrarTokenDialog(resultado['token']);
          _cargarInvitaciones();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  void _mostrarTokenDialog(String token) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Token de Invitación Generado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Comparte este token con alguien para que se una:"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                token,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Válido por 10 días, máximo 7 usos",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copiar al portapapeles
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Token copiado")),
              );
              Navigator.pop(context);
            },
            child: const Text("Copiar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Future<void> _removerMiembro(int usuarioId, String nombre) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: Text("¿Remover a $nombre del proyecto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remover"),
          ),
        ],
      ),
    );

    if (confirma == true) {
      try {
        await _service.removerMiembro(widget.proyecto.id!, usuarioId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Miembro removido")),
          );
          _cargarMiembros();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  Color _getRoleColor(String rol) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Administrar Proyecto"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Header con nombre del proyecto ──
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.proyecto.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.proyecto.descripcion ?? "Sin descripción",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          // ── Tabs ──
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(0, "Miembros", _miembros.length),
                ),
                Expanded(
                  child: _buildTab(1, "Invitaciones", _invitaciones.length),
                ),
              ],
            ),
          ),
          // ── Contenido ──
          Expanded(
            child: _selectedTab == 0 ? _buildMiembros() : _buildInvitaciones(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFF4CAF50) : Colors.grey,
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiembros() {
    if (_cargandoMiembros) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    if (_miembros.isEmpty) {
      return const Center(
        child: Text("Sin miembros en este proyecto"),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _miembros.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final miembro = _miembros[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  (miembro['nombre'] as String)
                      .split(' ')
                      .map((e) => e[0])
                      .join()
                      .toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      miembro['nombre'] ?? "Usuario",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      miembro['correo'] ?? "",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(miembro['rol_proyecto'])
                      .withAlpha((0.2 * 255).toInt()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  miembro['rol_proyecto'] ?? "N/A",
                  style: TextStyle(
                    color: _getRoleColor(miembro['rol_proyecto']),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Remover"),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'remove') {
                    _removerMiembro(
                      miembro['id'],
                      miembro['nombre'],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvitaciones() {
    if (_cargandoInvitaciones) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _generarInvitacion,
            icon: const Icon(Icons.add),
            label: const Text("Generar Nueva Invitación"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          if (_invitaciones.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text("Sin invitaciones activas"),
              ),
            )
          else
            Column(
              children: _invitaciones.map((inv) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3)
                                  .withAlpha((0.2 * 255).toInt()),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              inv['rol_por_defecto'] ?? "N/A",
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            "Usos: ${inv['usos_restantes']}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        inv['token'],
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
