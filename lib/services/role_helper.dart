import 'package:build_check_app/core/proyecto_actual.dart';

class RoleHelper {
  static String? get rol => ProyectoActual.rolEnProyecto;

  static bool esAdmin() => rol == "ROLE_ADMIN" || rol == "ROLE_OWNER";
  static bool esAlmacenista() => rol == "ROLE_ALMACENISTA";
  static bool esDirectorObra() => rol == "ROLE_DIRECTOR_OBRA";
  static bool esResidente() => rol == "ROLE_RESIDENTE";

  static bool puedeRegistrarMovimientos() {
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_OWNER" ||
        rol == "ROLE_ALMACENISTA" ||
        rol == "ROLE_RESIDENTE";
  }

  static bool puedeGestionarMateriales() {
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_OWNER" ||
        rol == "ROLE_ALMACENISTA";
  }

  static bool puedeEliminarMaterial() => esAdmin();

  static bool puedeGestionarFacturas() {
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_OWNER" ||
        rol == "ROLE_ALMACENISTA";
  }

  static bool puedeVerFacturas() {
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_OWNER" ||
        rol == "ROLE_ALMACENISTA" ||
        rol == "ROLE_DIRECTOR_OBRA";
  }

  static bool puedeGestionarProyectos() {
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_OWNER" ||
        rol == "ROLE_DIRECTOR_OBRA";
  }

  static bool puedeEditarMovimientos() {
    return rol == "ROLE_ADMIN" ||
        rol == "ROLE_OWNER" ||
        rol == "ROLE_ALMACENISTA";
  }
}
