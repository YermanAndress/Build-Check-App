import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/core/usuario_actual.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:build_check_app/ui/main_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await UsuarioActual.cargar();
  await ProyectoActual.cargar();

  runApp(const BuildCheckApp());
}

class BuildCheckApp extends StatelessWidget {
  const BuildCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
      home: FutureBuilder<String?>(
        future: SecureStorage.read("accessToken"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final token = snapshot.data;
          if (token == null || token.isEmpty) {
            return const Loginpage();
          } else {
            return const MainScreen();
          }
        },
      ),
    );
  }
}
