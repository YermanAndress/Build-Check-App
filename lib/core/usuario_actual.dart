import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioActual {
  UsuarioActual._();

  static final ValueNotifier<int?> notifier = ValueNotifier<int?>(null);
  static int? get id => notifier.value;
  static String? get correo => _correo;
  static String? _correo;

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getInt('usuarioId');
    _correo = prefs.getString('usuarioCorreo');
  }

  static Future<void> set(int usuarioId, String correo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuarioId', usuarioId);
    await prefs.setString('usuarioCorreo', correo);
    notifier.value = usuarioId;
    _correo = correo;
  }

  static Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuarioId');
    await prefs.remove('usuarioCorreo');
    notifier.value = null;
    _correo = null;
  }
}
