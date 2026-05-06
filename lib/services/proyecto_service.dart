import 'dart:convert';
import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:http/http.dart' as http;

class ProyectoService {
  Future<List<Proyecto>> obtenerProyectos() async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.get(
      Uri.parse(ApiConfig.proyectos),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List<dynamic> lista = decoded['proyectos'] as List<dynamic>;
      return lista
          .map((e) => Proyecto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception("Error al cargar proyectos: ${res.statusCode}");
  }

  Future<Proyecto> obtenerProyecto(int id) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.get(
      Uri.parse("${ApiConfig.proyectos}/$id"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      return Proyecto.fromJson(decoded['proyecto']);
    }
    throw Exception("Error al cargar proyecto: ${res.statusCode}");
  }

  Future<bool> crearProyecto(Proyecto proyecto) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.proyectos),
      headers: headers,
      body: jsonEncode(proyecto.toJson()),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> actualizarProyecto(Proyecto proyecto) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.put(
      Uri.parse("${ApiConfig.proyectos}/${proyecto.id}"),
      headers: headers,
      body: jsonEncode(proyecto.toJson()),
    );
    return res.statusCode == 200;
  }

  Future<bool> eliminarProyecto(int id) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.delete(
      Uri.parse("${ApiConfig.proyectos}/$id"),
      headers: headers,
    );
    return res.statusCode == 200 ||
        res.statusCode == 202 ||
        res.statusCode == 204;
  }
}
