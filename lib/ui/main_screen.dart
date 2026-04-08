import 'package:flutter/material.dart';

import 'features/dashboard/screen/dashboard_page.dart';
import 'features/proyectos/screen/proyectos_page.dart';
import 'features/materiales/screen/materiales_page.dart';
import 'features/movimientos/screen/movimientos_page.dart';
import 'features/reporte/screen/reporte_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Aquí listas todas tus páginas principales
  final List<Widget> _paginas = [
    const DashboardPage(), // Tu Home actual
    const ProyectosPage(), // Placeholder o página real
    const CatalogoScreen(), // ¡Aquí va tu nuevo catálogo!
    const MovimientosPage(),
    const ReportePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El IndexedStack mantiene el estado de las páginas vivo (no se recargan al cambiar)
      body: IndexedStack(index: _selectedIndex, children: _paginas),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4CAF50),
          // ... todo el estilo que ya tienes ...
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              label: 'Proyectos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Inventario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert),
              label: 'Movimientos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              label: 'Reporte',
            ),
          ],
        ),
      ),
    );
  }
}
