import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/services/rsa_service.dart';

class LoginService {
  final _rsa = RsaService();

  Future<void> _loadPublicKey() async {
    final url = Uri.parse('${ApiConfig.usuarios}/public-key');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      _rsa.loadPublicKey(body['publicKey']);
    } else {
      throw Exception('No se pudo obtener la llave pública');
    }
  }

  Future<Map<String, dynamic>> login(String correo, String password) async {
    await _loadPublicKey();

    final url = Uri.parse('${ApiConfig.usuarios}/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': _rsa.encrypt(correo),
        'password': _rsa.encrypt(password),
      }),
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }
    throw Exception('Error de servidor: ${response.statusCode}');
  }

  Future<void> registrarUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String telefono,
  }) async {
    await _loadPublicKey();

    final url = Uri.parse('${ApiConfig.usuarios}/usuarios');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': _rsa.encrypt(correo),
        'password': password,
        'telefono': telefono,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al registrar usuario: ${response.statusCode}');
    }
  }

  Future<void> recuperarPassword(String correo) async {
    final url = Uri.parse(
      '${ApiConfig.usuarios}/usuarios/recuperar?correo=${Uri.encodeComponent(correo)}',
    );
    final res = await http.post(url);
    if (res.statusCode != 200) {
      try {
        final body = jsonDecode(res.body);
        final mensaje =
            body['error'] ?? body['mensaje'] ?? 'Error al enviar correo';
        throw Exception(mensaje);
      } catch (_) {
        throw Exception('Error al enviar correo de recuperacion');
      }
    }
  }
}
