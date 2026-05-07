import 'package:build_check_app/services/secure_storage.dart';

class AuthHeader {
  static Future<Map<String, String>> getHeaders({bool json = true}) async {
    final token = await SecureStorage.read("accessToken");
    print("ACCESS TOKEN REAL: $token");
    final headers = {"Authorization": "Bearer $token"};
    if (json) {
      headers["Content-Type"] = "application/json";
    }
    return headers;
  }
}
