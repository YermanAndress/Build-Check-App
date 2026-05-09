import 'dart:convert';

import 'package:build_check_app/services/secure_storage.dart';

class RoleHelper {
  static Future<String?> getRol() async {
    final usuarioJson = await SecureStorage.read("usuario");
    if (usuarioJson == null) return null;
    final usuario = jsonDecode(usuarioJson);
    return usuario["rol"] as String?;
  }

  static Future<bool> esAdmin() async => await getRol() == "ROLE_ADMIN";
  static Future<bool> esAlmacenista() async =>
      await getRol() == "ROLE_ALMACENISTA";
  static Future<bool> esDirectorObra() async =>
      await getRol() == "ROLE_DIRECTOR_OBRA";
  static Future<bool> esResidente() async => await getRol() == "ROLE_RESIDENTE";

  static Future<bool> puedeRegistrarMovimientos() async {
    final rol = await getRol();
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_ALMACENISTA" ||
        rol == "ROLE_RESIDENTE";
  }

  static Future<bool> puedeGestionarMateriales() async {
    final rol = await getRol();
    return rol == "ROLE_ADMIN" || rol == "ROLE_ALMACENISTA";
  }

  static Future<bool> puedeEliminarMaterial() async => await esAdmin();

  static Future<bool> puedeGestionarFacturas() async {
    final rol = await getRol();
    return rol == "ROLE_ADMIN" || rol == "ROLE_ALMACENISTA";
  }

  static Future<bool> puedeVerFacturas() async {
    final rol = await getRol();
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_ALMACENISTA" ||
        rol == "ROLE_DIRECTOR_OBRA";
  }

  static Future<bool> puedeGestionarProyectos() async {
    final rol = await getRol();
    return rol == "ROLE_ADMIN" || rol == "ROLE_DIRECTOR_OBRA";
  }

  static Future<bool> puedeEditarMovimientos() async {
    final rol = await getRol();
    return rol == "ROLE_ADMIN" || rol == "ROLE_ALMACENISTA";
  }
}
