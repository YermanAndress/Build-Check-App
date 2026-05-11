// lib/ui/main_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_check_app/services/role_helper.dart';

import 'features/dashboard/screen/dashboard_page.dart';
import 'features/proyectos/screen/proyectos_page.dart';
import 'features/facturas/screen/facturas_page.dart';
import 'features/movimientos/screen/movimientos_page.dart';
import 'features/materiales/screen/materiales_page.dart';
import 'features/proyectos/widget/select_proyecto_modal.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _puedeVerFacturas = false;
  bool _cargandoRol = true;

  // Definición completa de tabs disponibles
  static const List<_TabItem> _todosLosTabs = [
    _TabItem(icon: Icons.home_outlined, label: 'Inicio'),
    _TabItem(icon: Icons.folder_outlined, label: 'Proyectos'),
    _TabItem(icon: Icons.inventory_2_outlined, label: 'Inventario'),
    _TabItem(icon: Icons.swap_vert, label: 'Movimientos'),
    _TabItem(icon: Icons.bar_chart_outlined, label: 'Facturas'),
  ];

  @override
  void initState() {
    super.initState();
    _cargarPermisos();
    _verificarProyecto();
  }

  Future<void> _cargarPermisos() async {
    final puedeFacturas = await RoleHelper.puedeVerFacturas();
    if (mounted) {
      setState(() {
        _puedeVerFacturas = puedeFacturas;
        _cargandoRol = false;
      });
    }
  }

  bool _mostrarSelector = false;

  Future<void> _verificarProyecto() async {
    final prefs = await SharedPreferences.getInstance();
    final proyectoId = prefs.getInt("proyectoActual");

    if (proyectoId == null && mounted) {
      setState(() => _mostrarSelector = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarModalSeleccion();
      });
    }
  }

  void _mostrarModalSeleccion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SelectProyectoModal(
        onProyectoSelected: (proyecto) {
          setState(() => _mostrarSelector = false);
        },
      ),
    );
  }

  // Builders según tabs visibles
  List<Widget Function()> get _builders {
    final lista = <Widget Function()>[
      () => const DashboardPage(),
      () => const ProyectosPage(),
      () => const MaterialesPage(),
      () => const MovimientosPage(),
    ];
    if (_puedeVerFacturas) {
      lista.add(() => const FacturasPage());
    }
    return lista;
  }

  List<BottomNavigationBarItem> get _items {
    final lista = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_outlined),
        label: 'Proyectos',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        label: 'Inventario',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.swap_vert),
        label: 'Movimientos',
      ),
    ];
    if (_puedeVerFacturas) {
      lista.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Facturas',
        ),
      );
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    // Muestra loading mientras lee el rol
    if (_cargandoRol) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Asegura que el índice no quede fuera de rango si se cambió la lista
    final index = _selectedIndex.clamp(0, _builders.length - 1);

    return Scaffold(
      body: _builders[index](),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4CAF50),
          items: _items,
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
