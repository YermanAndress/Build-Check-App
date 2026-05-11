import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProyectoActual {
  ProyectoActual._();

  static final ValueNotifier<int?> notifier = ValueNotifier<int?>(null);

  static int? get id => notifier.value;
  static String? rolEnProyecto;

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getInt('proyectoActual');
    rolEnProyecto = prefs.getString('rolProyectoActual');
  }

  static Future<void> set(int proyectoId, {String? rolEnProyecto}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('proyectoActual', proyectoId);
    if (rolEnProyecto != null) {
      await prefs.setString('rolProyectoActual', rolEnProyecto);
    }
    rolEnProyecto = rolEnProyecto;
    notifier.value = proyectoId;
  }

  static bool get esAdmin =>
      rolEnProyecto == 'ROLE_OWNER' || rolEnProyecto == 'ROLE_ADMIN';

  static Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('proyectoActual');
    await prefs.remove('rolProyectoActual');
    rolEnProyecto = null;
    notifier.value = null;
  }
}
