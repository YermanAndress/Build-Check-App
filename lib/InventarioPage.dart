import 'package:flutter/material.dart';
import 'bottom_nav_shell.dart';

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomNavShell(
      currentIndex: 2,
      child: Center(
        child: Text(
          'Inventario\n(en construcción)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
        ),
      ),
    );
  }
}