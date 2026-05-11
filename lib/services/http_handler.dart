import 'package:build_check_app/services/secure_storage.dart';
import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:flutter/material.dart';

class HttpHandler {
  static Future<void> handleUnauthorized(BuildContext context) async {
<<<<<<< HEAD
    await SecureStorage.clear();
=======
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (_) => false,
    );
  }
}
