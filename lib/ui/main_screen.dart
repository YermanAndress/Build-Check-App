// lib/ui/main_screen.dart
import 'package:flutter/material.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/services/role_helper.dart';
import 'package:build_check_app/ui/features/dashboard/screen/dashboard_page.dart';
import 'package:build_check_app/ui/features/proyectos/screen/proyectos_page.dart';
import 'package:build_check_app/ui/features/facturas/screen/facturas_page.dart';
import 'package:build_check_app/ui/features/movimientos/screen/movimientos_page.dart';
import 'package:build_check_app/ui/features/materiales/screen/materiales_page.dart';
import 'package:build_check_app/ui/features/proyectos/screen/select_proyecto_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _puedeVerFacturas = false;
  bool _cargandoRol = true;

  // Definición completa de tabs disponibles (sin Facturas, que se añade condicionalmente)
  static final List<_TabItem> _tabsBase = [
    const _TabItem(icon: Icons.home_outlined, label: 'Inicio'),
    const _TabItem(icon: Icons.folder_outlined, label: 'Proyectos'),
    const _TabItem(icon: Icons.inventory_2_outlined, label: 'Inventario'),
    const _TabItem(icon: Icons.swap_vert, label: 'Movimientos'),
  ];
  static const _tabFacturas = _TabItem(
    icon: Icons.bar_chart_outlined,
    label: 'Facturas',
  );

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

  Future<void> _verificarProyecto() async {
    await ProyectoActual.cargar();
    if (ProyectoActual.id == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SelectProyectoPage(),
            fullscreenDialog: true,
          ),
        );
      });
    }
  }

  // Lista de páginas según los tabs visibles
  List<Widget> get _paginas {
    final lista = <Widget>[
      const DashboardPage(),
      const ProyectosPage(),
      const MaterialesPage(),
      const MovimientosPage(),
    ];
    if (_puedeVerFacturas) {
      lista.add(const FacturasPage());
    }
    return lista;
  }

  // Lista de elementos de la barra inferior según los tabs visibles
  List<BottomNavigationBarItem> get _items {
    final lista = _tabsBase
        .map((e) => BottomNavigationBarItem(icon: Icon(e.icon), label: e.label))
        .toList();
    if (_puedeVerFacturas) {
      lista.add(
        BottomNavigationBarItem(
          icon: Icon(_tabFacturas.icon),
          label: _tabFacturas.label,
        ),
      );
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoRol) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final index = _selectedIndex.clamp(0, _paginas.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: _paginas),
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
