import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/main.dart';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
import 'package:build_check_app/services/http_interceptor.dart';

class ProyectoService {
  Future<List<Proyecto>> obtenerMisProyectos() async {
    final response = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse("${ApiConfig.proyectos}/usuario/mis-proyectos"),
        headers: await AuthHeader.getHeaders(),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return [];
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final listaRaw = decoded['proyectos'];
      if (listaRaw == null) return [];
      final List<dynamic> lista = listaRaw as List<dynamic>;
      return lista
          .map((e) => Proyecto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Error al cargar proyectos: ${response.statusCode}");
  }

  Future<Proyecto> obtenerProyecto(int id) async {
    final response = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse("${ApiConfig.proyectos}/$id"),
        headers: await AuthHeader.getHeaders(),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      throw Exception("No autorizado");
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return Proyecto.fromJson(decoded['proyecto']);
    }
    throw Exception("Error al cargar proyecto: ${response.statusCode}");
  }

  Future<Proyecto> crearProyecto(Proyecto proyecto) async {
    final response = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse(ApiConfig.proyectos),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode(proyecto.toJson()),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      throw Exception("No autorizado");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return Proyecto.fromJson(decoded['proyecto']);
    }
    throw Exception("Error al crear proyecto: ${response.statusCode}");
  }

  Future<bool> actualizarProyecto(Proyecto proyecto) async {
    final response = await HttpInterceptor.send(() async {
      return http.put(
        Uri.parse("${ApiConfig.proyectos}/${proyecto.id}"),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode(proyecto.toJson()),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return response.statusCode == 200;
  }

  Future<bool> eliminarProyecto(int id) async {
    final response = await HttpInterceptor.send(() async {
      return http.delete(
        Uri.parse("${ApiConfig.proyectos}/$id"),
        headers: await AuthHeader.getHeaders(),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return response.statusCode == 200 ||
        response.statusCode == 202 ||
        response.statusCode == 204;
  }

  // ============= MÉTODOS DE INVITACIONES =============

  Future<Map<String, dynamic>> generarInvitacion(
    int proyectoId,
    String rolPorDefecto,
  ) async {
    final response = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse("${ApiConfig.proyectos}/$proyectoId/invitaciones/generar"),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode({"rolPorDefecto": rolPorDefecto}),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      throw Exception("No autorizado");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return {
        'token': decoded['token'],
        'expires_at': decoded['expires_at'],
        'usos_restantes': decoded['usos_restantes'],
      };
    }
    throw Exception("Error al generar invitación: ${response.statusCode}");
  }

  Future<List<Map<String, dynamic>>> obtenerInvitaciones(int proyectoId) async {
    final response = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse("${ApiConfig.proyectos}/$proyectoId/invitaciones"),
        headers: await AuthHeader.getHeaders(),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return [];
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> lista = decoded['invitaciones'] as List<dynamic>;
      return lista.cast<Map<String, dynamic>>();
    }
    throw Exception("Error al obtener invitaciones: ${response.statusCode}");
  }

  Future<bool> revocarInvitacion(int proyectoId, String token) async {
    final response = await HttpInterceptor.send(() async {
      return http.delete(
        Uri.parse("${ApiConfig.proyectos}/$proyectoId/invitaciones/$token"),
        headers: await AuthHeader.getHeaders(),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return response.statusCode == 200;
  }

  // ============= MÉTODOS DE MIEMBROS =============

  Future<List<Map<String, dynamic>>> obtenerMiembros(int proyectoId) async {
    final response = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse("${ApiConfig.proyectos}/$proyectoId/miembros"),
        headers: await AuthHeader.getHeaders(),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return [];
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> lista = decoded['miembros'] as List<dynamic>;
      return lista.cast<Map<String, dynamic>>();
    }
    throw Exception("Error al obtener miembros: ${response.statusCode}");
  }

  Future<bool> cambiarRolMiembro(
    int proyectoId,
    int usuarioId,
    String nuevoRol,
  ) async {
    final response = await HttpInterceptor.send(() async {
      return http.put(
        Uri.parse("${ApiConfig.proyectos}/$proyectoId/miembros/$usuarioId/rol"),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode({"nuevoRol": nuevoRol}),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return response.statusCode == 200;
  }

  Future<bool> removerMiembro(int proyectoId, int usuarioId) async {
    final response = await HttpInterceptor.send(() async {
      return http.delete(
        Uri.parse("${ApiConfig.proyectos}/$proyectoId/miembros/$usuarioId"),
        headers: await AuthHeader.getHeaders(),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return response.statusCode == 200;
  }

  // ============= MÉTODO PARA UNIRSE A PROYECTO =============

  Future<Map<String, dynamic>> unirseAProyecto(String token) async {
    final response = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse("${ApiConfig.proyectos}/unirse"),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode({"token": token}),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      throw Exception("No autorizado");
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return {
        'token': decoded['token'],
        'proyecto_id': decoded['proyecto_id'],
        'rol_proyecto': decoded['rol_proyecto'],
      };
    }
    throw Exception("Error al unirse al proyecto: ${response.statusCode}");
  }
}
