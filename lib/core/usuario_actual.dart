import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioActual {
  UsuarioActual._();

  static final ValueNotifier<int?> notifier = ValueNotifier<int?>(null);
  static String? _correo;
  static String? _nombre;
  static String? _telegramChatId;

  static int? get id => notifier.value;
  static String? get correo => _correo;
  static String? get nombre => _nombre;
  static String? get telegramChatId => _telegramChatId;

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getInt('usuarioId');
    _correo = prefs.getString('usuarioCorreo');
    _nombre = prefs.getString('usuarioNombre');
    _telegramChatId = prefs.getString('usuarioTelegramChatId');
  }

  static Future<void> set(
    int usuarioId,
    String correo, {
    String? nombre,
    String? telegramChatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuarioId', usuarioId);
    await prefs.setString('usuarioCorreo', correo);
    if (nombre != null) await prefs.setString('usuarioNombre', nombre);
    if (telegramChatId != null) {
      await prefs.setString('usuarioTelegramChatId', telegramChatId);
    }
    notifier.value = usuarioId;
    _correo = correo;
    if (nombre != null) _nombre = nombre;
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
    await prefs.remove('usuarioTelegramChatId');
    notifier.value = null;
    _correo = null;
    _nombre = null;
    _telegramChatId = null;
  }
}
