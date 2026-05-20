import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioActual {
  UsuarioActual._();

  static final ValueNotifier<int?> notifier = ValueNotifier<int?>(null);
  static int? get id => notifier.value;
  static String? get correo => _correo;
  static String? get nombre => _nombre;
  static String? get rol => _rol;
  static String? get telegramChatId => _telegramChatId;

  static String? _correo;
  static String? _nombre;
  static String? _rol;
  static String? _telegramChatId;

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getInt('usuarioId');
    _correo = prefs.getString('usuarioCorreo');
    _correo = prefs.getString("usuarioNombre");
    _rol = prefs.getString("usuarioRol");
    _telegramChatId = prefs.getString("usuarioTelegramChatId");
  }

  static Future<void> set(
    int usuarioId,
    String correo, {
    String? nombre,
    String? rol,
    String? telegramChatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuarioId', usuarioId);
    await prefs.setString('usuarioCorreo', correo);
    if (nombre != null) await prefs.setString('usuarioNombre', nombre);
    if (rol != null) await prefs.setString('usuarioRol', rol);
    if (telegramChatId != null) {
      await prefs.setString('usuarioTelegramChatId', telegramChatId);
    }
    notifier.value = usuarioId;
    _correo = correo;
    if (nombre != null) _nombre = nombre;
    if (rol != null) _rol = rol;
    if (telegramChatId != null) _telegramChatId = telegramChatId;
  }

  static Future<void> setTelegramChatId(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuarioTelegramChatId', chatId);
    _telegramChatId = chatId;
  }

  static Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuarioId');
    await prefs.remove('usuarioCorreo');
    await prefs.remove('usuarioNombre');
    await prefs.remove('usuarioRol');
    await prefs.remove('usuarioTelegramChatId');
    notifier.value = null;
    _correo = null;
    _nombre = null;
    _rol = null;
    _telegramChatId = null;
  }
}
