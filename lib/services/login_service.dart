import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';

class LoginService {
  Future<Map<String, dynamic>> login(String correo, String password) async {
    final url = Uri.parse(ApiConfig.usuarios + '/login');
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

  Future<void> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
  }) async {
    final url = Uri.parse(ApiConfig.usuarios + '/usuarios');
    final body = {
      'nombre': nombre,
      'correo': correo,
      'password': password,
      'rol': rol,
    };
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al registrar usuario: ${response.statusCode}');
    }
  }

  Future<void> recuperarPassword(String correo, String nuevaPassword) async {
    final urlBuscar = Uri.parse(
      "${ApiConfig.usuarios}/usuarios/buscar?correo=$correo",
    );
    final responseBuscar = await http.get(urlBuscar);
    if (responseBuscar.statusCode != 200) {
      throw Exception('Usuario no encontrado');
    }
    final usuario = jsonDecode(responseBuscar.body);
    final id = usuario['id'];

    final urlActualizar = Uri.parse("${ApiConfig.usuarios}/usuarios/$id");
    final responseActualizar = await http.put(
      urlActualizar,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "id": id,
        "nombre": usuario['nombre'],
        "correo": usuario['correo'],
        'password': nuevaPassword,
        "rol": usuario['rol'],
        "activo": usuario['activo'],
      }),
    );
    if (responseActualizar.statusCode != 200) {
      throw Exception(
        'Error al actualizar contraseña: ${responseActualizar.statusCode}',
      );
    }
  }
}
