import 'package:shared_preferences/shared_preferences.dart';

class AuthHeader {
  static Future<Map<String, String>> getHeaders({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final headers = {"Authorization": "Bearer $token"};
    if (json) {
      headers["Content-Type"] = "application/json";
    }
    return headers;
  }
}
