import 'package:flutter/material.dart';

import 'features/dashboard/screen/dashboard_page.dart';
import 'features/proyectos/screen/proyectos_page.dart';
import 'features/facturas/screen/facturas_page.dart';
import 'features/movimientos/screen/movimientos_page.dart';
import 'features/materiales/screen/materiales_page.dart';
import 'features/jwt_evidence/screen/jwt_evidence_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget Function()> _builders = [
    () => DashboardPage(),
    () => ProyectosPage(),
    () => MaterialesPage(),
    () => MovimientosPage(),
    () => FacturasPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _builders[_selectedIndex](),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JwtEvidencePage()),
          );
        },
        backgroundColor: const Color(0xFF7C4DFF),
        icon: const Icon(Icons.token, color: Colors.white),
        label: const Text(
          'JWT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
              label: 'Facturas',
            ),
          ],
        ),
      ),
    );
  }
}
