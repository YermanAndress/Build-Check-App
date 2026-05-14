import 'package:build_check_app/services/secure_storage.dart';
import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HttpHandler {
  static Future<void> handleUnauthorized(BuildContext context) async {
    await SecureStorage.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (_) => false,
    );
  }
}
