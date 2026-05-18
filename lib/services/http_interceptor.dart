import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:build_check_app/main.dart';
import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:flutter/material.dart';

class HttpInterceptor {
  static bool _isRefreshing = false;

  static Future<http.Response> send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response = await request();

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        !_isRefreshing) {
      _isRefreshing = true;

      final newTokens = await _refreshToken();
      if (newTokens != null) {
        await SecureStorage.save("accessToken", newTokens['accessToken']!);
        await SecureStorage.save("refreshToken", newTokens['refreshToken']!);
        _isRefreshing = false;
        return await request();
      } else {
        _isRefreshing = false;
        await _logout();
        return response;
      }
    }

    // Resetear contador después de una respuesta exitosa
    if (response.statusCode != 401 && response.statusCode != 403) {
      _isRefreshing = false;
    }

    return response;
  }

  static Future<Map<String, String>?> _refreshToken() async {
    final refreshToken = await SecureStorage.read("refreshToken");
    if (refreshToken == null) return null;

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/usuarios-service/refresh");
      final headers = {
        'Content-Type': 'application/json',
        if (ProyectoActual.id != null)
          'X-Proyecto-Id': ProyectoActual.id.toString(),
      };
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _logout() async {
    await SecureStorage.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Loginpage()),
      (_) => false,
    );
  }
}
