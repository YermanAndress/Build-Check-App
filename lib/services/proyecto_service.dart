import 'dart:convert';
import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/main.dart';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:http/http.dart' as http;

class ProyectoService {
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
}
