import 'dart:convert';

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:http/http.dart' as http;

class RefreshService {
  static Future<bool> refreshToken() async {
    final refresh = await SecureStorage.read("refreshToken");
    if (refresh == null) return false;
    final res = await http.post(
      Uri.parse("${ApiConfig.usuarios}/refresh"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refreshToken": refresh}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await SecureStorage.save("accessToken", data["accessToken"]);
      await SecureStorage.save("refreshToken", data["refreshToken"]);
      print("NUEVO ACCESS TOKEN: ${data['accessToken']}");
      print("NUEVO REFRESH TOKEN: ${data['refreshToken']}");
      return true;
    }
    return false;
  }
}
