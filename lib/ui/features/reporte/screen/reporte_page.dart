import 'package:flutter/material.dart';
import '../../../bottom_nav_shell.dart';

class ReportePage extends StatelessWidget {
  const ReportePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BottomNavShell(
      currentIndex: 4,
      child: Center(
        child: Text(
          'Reporte\n(en construcción)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
        ),
      ),
    );
  }
}
