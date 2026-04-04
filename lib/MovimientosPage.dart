import 'package:flutter/material.dart';
import 'bottom_nav_shell.dart';

class MovimientosPage extends StatelessWidget {
  const MovimientosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomNavShell(
      currentIndex: 3,
      child: Center(
        child: Text(
          'Movimientos\n(en construcción)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
        ),
      ),
    );
  }
}