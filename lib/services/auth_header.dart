import 'package:build_check_app/services/secure_storage.dart';
import 'package:build_check_app/core/proyecto_actual.dart';

class AuthHeader {
  static Future<Map<String, String>> getHeaders({bool json = true}) async {
    final token = await SecureStorage.read("accessToken");
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    final proyectoId = ProyectoActual.id;
    if (proyectoId != null) {
      headers["X-Proyecto-Id"] = proyectoId.toString();
    }
    if (json) {
      headers["Content-Type"] = "application/json";
    }
    return headers;
  }
}
