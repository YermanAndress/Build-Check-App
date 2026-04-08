import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/material_model.dart';

class MaterialService {
  // Obtener alertas de stock bajo
  Future<List<AlertaMaterial>> obtenerAlertas() async {
    final res = await http.get(Uri.parse(ApiConfig.alertas));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      List raw = decoded is List
          ? decoded
          : (decoded is Map && decoded.containsKey('alertas')
                ? decoded['alertas']
                : [decoded]);
      return raw.map((e) => AlertaMaterial.fromJson(e)).toList();
    }
    throw Exception('Error al cargar alertas: ${res.statusCode}');
  }

  // Obtener todos los materiales (para el mapa de nombres)
  Future<Map<int, MaterialItem>> obtenerMapaMateriales() async {
    final res = await http.get(Uri.parse(ApiConfig.materiales));
    final Map<int, MaterialItem> map = {};
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      List raw = decoded is List ? decoded : decoded['materiales'] ?? [];
      for (var item in raw) {
        final m = MaterialItem.fromJson(item);
        map[m.id] = m;
      }
    }
    return map;
  }

  // Registrar un nuevo movimiento
  Future<bool> registrarMovimiento(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse(ApiConfig.movimientos),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }
}
