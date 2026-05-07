import 'package:build_check_app/services/secure_storage.dart';
import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:flutter/material.dart';

class HttpHandler {
  static Future<void> handleUnauthorized(BuildContext context) async {
    await SecureStorage.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (_) => false,
    );
  }
}
