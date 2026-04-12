import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BottomNavShell
//
// Wrapper reutilizable que incluye la barra de navegación inferior.
// Cada página nueva debe envolver su contenido con este widget:
//
//   return BottomNavShell(
//     currentIndex: 2, // índice de esta pantalla en la barra
//     child: TuContenido(),
//   );
//
// Índices:
//   0 → Inicio (build_check_screen.dart)
//   1 → Proyectos
//   2 → Inventario
//   3 → Movimientos
//   4 → Reporte
// ─────────────────────────────────────────────────────────────────────────────

class BottomNavShell extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const BottomNavShell({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return; // ya estamos aquí

    if (index == 0) {
      // Volver al inicio limpiando toda la pila de navegación
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // Para las demás páginas: reemplazar la actual (evita apilar pantallas)
    final pages = _buildPages();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => pages[index]),
    );
  }

  // Importación diferida para evitar dependencias circulares.
  // Cada página se instancia aquí para que el shell pueda navegar entre ellas.
  List<Widget> _buildPages() {
    // ignore: avoid_returning_null_for_void
    return [
      const SizedBox(), // 0 → Inicio, se maneja con popUntil
      const _ProyectosProxy(),
      const _InventarioProxy(),
      const _MovimientosProxy(),
      const _ReporteProxy(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => _onTap(context, i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'Proyectos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_outlined),
              activeIcon: Icon(Icons.inventory),
              label: 'Inventario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert),
              label: 'Movimientos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reporte',
            ),
          ],
        ),
      ),
    );
  }
}

// Proxies para evitar importaciones circulares — cada uno importa su página
class _ProyectosProxy extends StatelessWidget {
  const _ProyectosProxy();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderPage(label: 'Proyectos', index: 1);
}

class _InventarioProxy extends StatelessWidget {
  const _InventarioProxy();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderPage(label: 'Inventario', index: 2);
}

class _MovimientosProxy extends StatelessWidget {
  const _MovimientosProxy();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderPage(label: 'Movimientos', index: 3);
}

class _ReporteProxy extends StatelessWidget {
  const _ReporteProxy();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderPage(label: 'Reporte', index: 4);
}

class _PlaceholderPage extends StatelessWidget {
  final String label;
  final int index;
  const _PlaceholderPage({required this.label, required this.index});

  @override
  Widget build(BuildContext context) {
    return BottomNavShell(
      currentIndex: index,
      child: Center(
        child: Text(
          '$label\n(en construcción)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Color(0xFF999999)),
        ),
      ),
    );
  }
}
