import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';

class LoginService {
  Future<Map<String, dynamic>> login(String correo, String password) async {
    final url = Uri.parse(ApiConfig.usuarios);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    } else {
      throw Exception('Error de servidor: ${response.statusCode}');
    }
  }
}
