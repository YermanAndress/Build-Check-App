import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/features/dashboard/screen/dashboard_page.dart';

void main() {
  // Asegura que los bindings de Flutter se inicialicen antes de cualquier plugin
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear orientación vertical para mejor UX en inventarios
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const BuildCheckApp());
}

class BuildCheckApp extends StatelessWidget {
  const BuildCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Build Check',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
        ),
      ),

      home: const DashboardPage(),
    );
  }
}
