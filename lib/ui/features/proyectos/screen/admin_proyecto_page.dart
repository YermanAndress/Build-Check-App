import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:build_check_app/core/proyecto_actual.dart';

class AdminProyectoPage extends StatefulWidget {
  final Proyecto proyecto;
  const AdminProyectoPage({super.key, required this.proyecto});

  @override
  State<AdminProyectoPage> createState() => _AdminProyectoPageState();
}

class _AdminProyectoPageState extends State<AdminProyectoPage> {
  final ProyectoService _service = ProyectoService();
  int _selectedTab = 0;

  List<Map<String, dynamic>> _miembros = [];
  bool _cargandoMiembros = false;
  String? _errorMiembros;

  List<Map<String, dynamic>> _invitaciones = [];
  bool _cargandoInvitaciones = false;
  String? _errorInvitaciones;

  @override
  void initState() {
    super.initState();
    _cargarMiembros();
    _cargarInvitaciones();
  }

  Future<void> _cargarMiembros() async {
    setState(() {
      _cargandoMiembros = true;
      _errorMiembros = null;
    });
    try {
      final miembros = await _service.obtenerMiembros(widget.proyecto.id!);
      print("Miembros recibidos: ${jsonEncode(miembros)}");
      setState(() => _miembros = miembros);
    } catch (e) {
      setState(() => _errorMiembros = e.toString());
    }
    setState(() => _cargandoMiembros = false);
  }

  Future<void> _cambiarRol(int usuarioId, String nombreUsuario) async {
    const roles = [
      'ROLE_ADMIN',
      'ROLE_ALMACENISTA',
      'ROLE_DIRECTOR_OBRA',
      'ROLE_RESIDENTE',
    ];
    final nuevoRol = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cambiar rol de $nombreUsuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles
              .map(
                (r) => ListTile(
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: _colorRol(r),
                  ),
                  title: Text(r.replaceAll('ROLE_', '').replaceAll('_', ' ')),
                  onTap: () => Navigator.pop(context, r),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (nuevoRol == null) return;
    try {
      final ok = await _service.cambiarRolMiembro(
        widget.proyecto.id!,
        usuarioId,
        nuevoRol,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Rol actualizado a ${nuevoRol.replaceAll("ROLE_", "")}'
                  : 'No se pudo actualizar el rol',
            ),
            backgroundColor: ok ? const Color(0xFF4CAF50) : Colors.red,
          ),
        );
        if (ok) _cargarMiembros();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removerMiembro(int usuarioId, String nombre) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Remover a $nombre del proyecto? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirma != true) return;
    try {
      await _service.removerMiembro(widget.proyecto.id!, usuarioId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Miembro removido'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        _cargarMiembros();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cargarInvitaciones() async {
    setState(() {
      _cargandoInvitaciones = true;
      _errorInvitaciones = null;
    });
    try {
      final invitaciones = await _service.obtenerInvitaciones(
        widget.proyecto.id!,
      );
      setState(() => _invitaciones = invitaciones);
    } catch (e) {
      setState(() => _errorInvitaciones = e.toString());
    }
    setState(() => _cargandoInvitaciones = false);
  }

  Future<void> _generarInvitacion() async {
    const roles = ['ROLE_ALMACENISTA', 'ROLE_DIRECTOR_OBRA', 'ROLE_RESIDENTE'];
    final rol = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rol para el nuevo miembro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles
              .map(
                (r) => ListTile(
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: _colorRol(r),
                  ),
                  title: Text(r.replaceAll('ROLE_', '').replaceAll('_', ' ')),
                  onTap: () => Navigator.pop(context, r),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
    if (rol == null) return;
    try {
      final resultado = await _service.generarInvitacion(
        widget.proyecto.id!,
        rol,
      );
      if (mounted) {
        _mostrarTokenDialog(resultado['token'] as String);
        _cargarInvitaciones();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _mostrarTokenDialog(String token) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Token de Invitación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparte este token para que alguien se una al proyecto:',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: SelectableText(
                token,
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Válido por 10 días · máximo 7 usos',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: token));
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Token copiado al portapapeles'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _revocarInvitacion(String token) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revocar invitación'),
        content: const Text('¿Desactivar este token? Nadie más podrá usarlo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
    if (confirma != true) return;
    try {
      await _service.revocarInvitacion(widget.proyecto.id!, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitación revocada'),
            backgroundColor: Colors.orange,
          ),
        );
        _cargarInvitaciones();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }


  Color _colorRol(String? rol) {
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

  String _getInitials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.isEmpty || nombre.isEmpty) return '?';
    return parts
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Administrar Proyecto'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF555555),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("token");
                await prefs.remove("usuario");
                await ProyectoActual.limpiar();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Loginpage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: FutureBuilder(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final prefs = snapshot.data!;
                    final usuarioJson = prefs.getString("usuario");
                    if (usuarioJson == null) return const SizedBox();
                    final usuario = jsonDecode(usuarioJson);
                    final nombre = usuario["nombre"] ?? "Usuario";
                    final rolProyecto = ProyectoActual.rolEnProyecto;
                    final rolLabel = rolProyecto
                        ?.replaceAll('ROLE_', '')
                        .replaceAll('_', ' ');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hola, $nombre 👋",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (rolLabel != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4CAF50,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              rolLabel,
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Cerrar sesión", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
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
                  widget.proyecto.descripcion.isEmpty
                      ? 'Sin descripción'
                      : widget.proyecto.descripcion,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _buildTab(0, 'Miembros', _miembros.length)),
                Expanded(
                  child: _buildTab(1, 'Invitaciones', _invitaciones.length),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _selectedTab == 0 ? _buildMiembros() : _buildInvitaciones(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, int count) {
    final sel = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: sel ? const Color(0xFF4CAF50) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  color: sel ? const Color(0xFF4CAF50) : Colors.grey,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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

    if (_errorMiembros != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              _errorMiembros!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargarMiembros,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_miembros.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_off_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay miembros en este proyecto',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Genera un token en la pestaña "Invitaciones"\npara agregar personas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _miembros.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final m = _miembros[index];

        final usuarioIdObj = m['usuarioId'];
        final usuarioId = usuarioIdObj is int
            ? usuarioIdObj
            : (usuarioIdObj as num?)?.toInt();

        final nombreRaw = m["usuarioNombre"] as String? ?? "Usuario";

        final nombre = (nombreRaw.startsWith('0') || nombreRaw.startsWith('1'))
            ? "Usuario"
            : nombreRaw;

        final correo = m['usuarioCorreo'] as String? ?? 'Sin correo';
        final rol = m['rolProyecto'] as String? ?? '';
        final esOwner = rol == 'ROLE_OWNER';

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
                backgroundColor: _colorRol(rol).withValues(alpha: 0.15),
                child: Text(
                  _getInitials(nombre),
                  style: TextStyle(
                    color: _colorRol(rol),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      correo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _colorRol(rol).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rol.replaceAll('ROLE_', '').replaceAll('_', ' '),
                  style: TextStyle(
                    color: _colorRol(rol),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!esOwner)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: Colors.grey,
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'rol',
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 18,
                            color: Color(0xFF2196F3),
                          ),
                          SizedBox(width: 8),
                          Text('Cambiar rol'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_circle_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Remover', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (action) {
                    if (action == 'rol') _cambiarRol(usuarioId!, nombre);
                    if (action == 'remove') {
                      _removerMiembro(usuarioId!, nombre);
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generarInvitacion,
              icon: const Icon(Icons.add_link),
              label: const Text('Generar Nueva Invitación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        if (_errorInvitaciones != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _errorInvitaciones!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: _invitaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_off,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sin invitaciones activas',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Genera un token para invitar nuevos miembros.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invitaciones.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final inv = _invitaciones[i];
                    final rol = inv['rolPorDefecto'] as String? ?? '';
                    final usos = inv['usosRestantes'] ?? 0;
                    final token = inv['token'] as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _colorRol(rol).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rol
                                      .replaceAll('ROLE_', '')
                                      .replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: _colorRol(rol),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.repeat,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$usos usos restantes',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              token,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: token),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('✓ Token copiado'),
                                          backgroundColor: Color(0xFF4CAF50),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text(
                                    'Copiar',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4CAF50),
                                    side: const BorderSide(
                                      color: Color(0xFF4CAF50),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _revocarInvitacion(token),
                                  icon: const Icon(Icons.block, size: 14),
                                  label: const Text(
                                    'Revocar',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
