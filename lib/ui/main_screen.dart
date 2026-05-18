// lib/ui/main_screen.dart
import 'package:flutter/material.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/services/role_helper.dart';
import 'package:build_check_app/ui/features/dashboard/screen/dashboard_page.dart';
import 'package:build_check_app/ui/features/proyectos/screen/proyectos_page.dart';
import 'package:build_check_app/ui/features/facturas/screen/facturas_page.dart';
import 'package:build_check_app/ui/features/movimientos/screen/movimientos_page.dart';
import 'package:build_check_app/ui/features/materiales/screen/materiales_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    ProyectoActual.notifier.addListener(_onProyectoChanged);
  }

  @override
  void dispose() {
    ProyectoActual.notifier.removeListener(_onProyectoChanged);
    super.dispose();
  }

  void _onProyectoChanged() {
    if (mounted) {
      setState(() {
        if (_selectedIndex >= _builders.length) {
          _selectedIndex = 0;
        }
      });
    }
  }

  List<Widget Function()> get _builders {
    final lista = <Widget Function()>[
      () => const DashboardPage(),
      () => const ProyectosPage(),
      () => const MaterialesPage(),
      () => const MovimientosPage(),
    ];
    if (RoleHelper.puedeVerFacturas()) {
      lista.add(() => const FacturasPage());
    }
    return lista;
  }

  // Lista de elementos de la barra inferior según los tabs visibles
  List<BottomNavigationBarItem> get _items {
    final lista = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: "Dashboard",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_outlined),
        label: "Proyectos",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        label: "Inventario",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.swap_vert),
        label: "Movimientos",
      ),
    ];
    if (RoleHelper.puedeVerFacturas()) {
      lista.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: "Facturas",
        ),
      );
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final builders = _builders;
    final index = _selectedIndex.clamp(0, builders.length - 1);

    return Scaffold(
      body: builders[index](),
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
