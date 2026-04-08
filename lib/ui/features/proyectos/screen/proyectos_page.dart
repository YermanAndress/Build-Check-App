import 'package:flutter/material.dart';
import '../../../bottom_nav_shell.dart';

class ProyectosPage extends StatelessWidget {
  const ProyectosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomNavShell(
      currentIndex: 1,
      child: Center(
        child: Text(
          'Proyectos\n(en construcción)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
        ),
      ),
    );
  }
}
