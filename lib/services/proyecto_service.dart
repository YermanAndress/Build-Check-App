import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/main.dart';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/auth_header.dart';
<<<<<<< HEAD
import 'package:build_check_app/services/http_handler.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:http/http.dart' as http;
=======
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)

class ProyectoService {
  Future<List<Proyecto>> obtenerMisProyectos() async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.get(
      Uri.parse("${ApiConfig.proyectos}/usuario/mis-proyectos"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
<<<<<<< HEAD
      final List<dynamic> lista = decoded['proyectos'] as List<dynamic>;
      return lista
          .map((e) => Proyecto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Error al cargar proyectos: ${res.statusCode}");
  }

  /// Obtiene TODOS los proyectos (solo admin)
  @Deprecated("Usar obtenerMisProyectos() en su lugar")
  Future<List<Proyecto>> obtenerProyectos() async {
    final res = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse(ApiConfig.proyectos),
        headers: await AuthHeader.getHeaders(),
      );
    });
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List<dynamic> lista = decoded['proyectos'];
      return lista.map((e) => Proyecto.fromJson(e)).toList();
=======
      final listaRaw = decoded['proyectos'];
      if (listaRaw == null) return [];
      final List<dynamic> lista = listaRaw as List<dynamic>;
      return lista
          .map((e) => Proyecto.fromJson(e as Map<String, dynamic>))
          .toList();
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
    }
    throw Exception("Error al cargar proyectos: ${res.statusCode}");
  }

  Future<Proyecto> obtenerProyecto(int id) async {
    final res = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse("${ApiConfig.proyectos}/$id"),
        headers: await AuthHeader.getHeaders(),
      );
    });
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return Proyecto.fromJson(decoded['proyecto']);
    }
    throw Exception("Error al cargar proyecto: ${res.statusCode}");
  }

<<<<<<< HEAD
  Future<bool> crearProyecto(Proyecto proyecto) async {
    final res = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse(ApiConfig.proyectos),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode(proyecto.toJson()),
      );
    });
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return res.statusCode == 200 || res.statusCode == 201;
=======
  Future<Proyecto> crearProyecto(Proyecto proyecto) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.proyectos),
      headers: headers,
      body: jsonEncode(proyecto.toJson()),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      return Proyecto.fromJson(decoded['proyecto']);
    }
    throw Exception("Error al crear proyecto: ${res.statusCode}");
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
  }

  Future<bool> actualizarProyecto(Proyecto proyecto) async {
    final res = await HttpInterceptor.send(() async {
      return http.put(
        Uri.parse("${ApiConfig.proyectos}/${proyecto.id}"),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode(proyecto.toJson()),
      );
    });
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return res.statusCode == 200;
  }

  Future<bool> eliminarProyecto(int id) async {
    final res = await HttpInterceptor.send(() async {
      return http.delete(
        Uri.parse("${ApiConfig.proyectos}/$id"),
        headers: await AuthHeader.getHeaders(),
      );
    });
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return res.statusCode == 200 ||
        res.statusCode == 202 ||
        res.statusCode == 204;
  }

  /// ============= MÉTODOS DE INVITACIONES =============
  Future<Map<String, dynamic>> generarInvitacion(
    int proyectoId,
    String rolPorDefecto,
  ) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.post(
      Uri.parse("${ApiConfig.proyectos}/$proyectoId/invitaciones/generar"),
      headers: headers,
      body: jsonEncode({"rolPorDefecto": rolPorDefecto}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      return {
        'token': decoded['token'],
        'expires_at': decoded['expires_at'],
        'usos_restantes': decoded['usos_restantes'],
      };
    }
    throw Exception("Error al generar invitación: ${res.statusCode}");
  }

  Future<List<Map<String, dynamic>>> obtenerInvitaciones(int proyectoId) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.get(
      Uri.parse("${ApiConfig.proyectos}/$proyectoId/invitaciones"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List<dynamic> lista = decoded['invitaciones'] as List<dynamic>;
      return lista.cast<Map<String, dynamic>>();
    }
    throw Exception("Error al obtener invitaciones: ${res.statusCode}");
  }

  Future<bool> revocarInvitacion(int proyectoId, String token) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.delete(
      Uri.parse("${ApiConfig.proyectos}/$proyectoId/invitaciones/$token"),
      headers: headers,
    );
    return res.statusCode == 200;
  }

  /// ============= MÉTODOS DE MIEMBROS =============
  Future<List<Map<String, dynamic>>> obtenerMiembros(int proyectoId) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.get(
      Uri.parse("${ApiConfig.proyectos}/$proyectoId/miembros"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List<dynamic> lista = decoded['miembros'] as List<dynamic>;
      return lista.cast<Map<String, dynamic>>();
    }
    throw Exception("Error al obtener miembros: ${res.statusCode}");
  }

  Future<bool> cambiarRolMiembro(
    int proyectoId,
    int usuarioId,
    String nuevoRol,
  ) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.put(
      Uri.parse("${ApiConfig.proyectos}/$proyectoId/miembros/$usuarioId/rol"),
      headers: headers,
      body: jsonEncode({"nuevoRol": nuevoRol}),
    );
    return res.statusCode == 200;
  }

  Future<bool> removerMiembro(int proyectoId, int usuarioId) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.delete(
      Uri.parse("${ApiConfig.proyectos}/$proyectoId/miembros/$usuarioId"),
      headers: headers,
    );
    return res.statusCode == 200;
  }

  /// ============= MÉTODOS DE UNIRSE A PROYECTO =============
  Future<Map<String, dynamic>> unirseAProyecto(String token) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.post(
      Uri.parse("${ApiConfig.proyectos}/unirse"),
      headers: headers,
      body: jsonEncode({"token": token}),
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return {
        'token': decoded['token'],
        'proyecto_id': decoded['proyecto_id'],
        'rol_proyecto': decoded['rol_proyecto'],
      };
    }
    throw Exception("Error al unirse al proyecto: ${res.statusCode}");
  }
}
