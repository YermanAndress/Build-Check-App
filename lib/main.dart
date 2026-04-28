import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/main_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

      //Develop
      home: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final prefs = snapshot.data!;
          final token = prefs.getString("token");
          if (token == null) {
            return const Loginpage();
          } else {
            return const MainScreen();
          }
        },
      ),
    );
  }
}
