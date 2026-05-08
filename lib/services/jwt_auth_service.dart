import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:build_check_app/services/rsa_service.dart';
import 'package:build_check_app/core/api_config.dart';

/// Servicio de autenticación JWT contra el backend de BuildCheck.
/// Maneja login, almacenamiento local y cierre de sesión.
///
/// - SharedPreferences  → datos NO sensibles (nombre, correo, rol, tema, idioma)
/// - FlutterSecureStorage → datos SENSIBLES (accessToken, refreshToken)
class JwtAuthService {
  final _rsa = RsaService();

  // ── Keys para SharedPreferences (datos NO sensibles) ──
  static const String _prefName = 'jwt_user_name';
  static const String _prefEmail = 'jwt_user_email';
  static const String _prefRol = 'jwt_user_rol';
  static const String _prefTheme = 'jwt_user_theme';
  static const String _prefLang = 'jwt_user_lang';

  // ── Keys para SecureStorage (datos SENSIBLES) ──
  static const String _secAccessToken = 'jwt_access_token';
  static const String _secRefreshToken = 'jwt_refresh_token';

  // ─────────────────── CARGAR LLAVE RSA ───────────────────
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

  // ─────────────────── LOGIN ───────────────────
  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    await _loadPublicKey();

    final url = Uri.parse('${ApiConfig.usuarios}/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'correo': _rsa.encrypt(correo),
        'password': _rsa.encrypt(password),
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      await _saveUserData(body);
      return body;
    }

    if (response.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }

    throw Exception('Error de servidor: ${response.statusCode}');
  }

  // ─────────────────── GUARDAR DATOS LOCALMENTE ───────────────────
  Future<void> _saveUserData(Map<String, dynamic> responseBody) async {
    final prefs = await SharedPreferences.getInstance();

    // Extraer datos del usuario
    final usuario = responseBody['usuario'] ?? {};
    final nombre = usuario['nombre'] ?? '';
    final correo = usuario['correo'] ?? '';
    final rol = usuario['rol'] ?? '';

    // SharedPreferences → datos NO sensibles
    await prefs.setString(_prefName, nombre.toString());
    await prefs.setString(_prefEmail, correo.toString());
    await prefs.setString(_prefRol, rol.toString());
    await prefs.setString(_prefTheme, 'dark');
    await prefs.setString(_prefLang, 'es');

    // SecureStorage → datos SENSIBLES
    final accessToken = responseBody['accessToken'] ?? '';
    final refreshToken = responseBody['refreshToken'] ?? '';

    await SecureStorage.save(_secAccessToken, accessToken.toString());
    await SecureStorage.save(_secRefreshToken, refreshToken.toString());
  }

  // ─────────────────── LEER DATOS GUARDADOS ───────────────────
  static Future<Map<String, String?>> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_prefName),
      'email': prefs.getString(_prefEmail),
      'rol': prefs.getString(_prefRol),
      'theme': prefs.getString(_prefTheme),
      'lang': prefs.getString(_prefLang),
    };
  }

  static Future<String?> getAccessToken() async {
    return await SecureStorage.read(_secAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await SecureStorage.read(_secRefreshToken);
  }

  // ─────────────────── CERRAR SESIÓN ───────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Limpiar SharedPreferences
    await prefs.remove(_prefName);
    await prefs.remove(_prefEmail);
    await prefs.remove(_prefRol);
    await prefs.remove(_prefTheme);
    await prefs.remove(_prefLang);

    // Limpiar SecureStorage
    await SecureStorage.delete(_secAccessToken);
    await SecureStorage.delete(_secRefreshToken);
  }

  // ─────────────────── VERIFICAR SESIÓN ───────────────────
  static Future<bool> hasActiveSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
