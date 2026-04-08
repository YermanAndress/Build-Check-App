import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/material_model.dart';
import '../models/movimiento_model.dart';

// movimiento_service.dart
class MovimientoService {
  Future<Map<String, dynamic>> obtenerStatsHoy() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(ApiConfig.movimientos)),
        http.get(Uri.parse(ApiConfig.materiales)),
      ]);

      final resMov = responses[0];
      final resMat = responses[1];

      // Helper para normalizar la respuesta de n8n (siempre a Lista)
      List normalizar(dynamic data, String key) {
        if (data is List) return data;
        if (data is Map && data.containsKey(key)) return data[key] as List;
        return [data]; // Si es un objeto solo, lo metemos en lista
      }

      // 1. Procesar Materiales
      final Map<int, MaterialItem> matMap = {};
      if (resMat.statusCode == 200) {
        final decoded = jsonDecode(resMat.body);
        final rawMat = normalizar(decoded, 'materiales');
        for (var e in rawMat) {
          final m = MaterialItem.fromJson(e);
          matMap[m.id] = m;
        }
      }

      // 2. Procesar Movimientos
      if (resMov.statusCode != 200) throw 'Error: ${resMov.statusCode}';

      final decodedMov = jsonDecode(resMov.body);
      final rawMov = normalizar(decodedMov, 'movimientos');

      final hoy = DateTime.now();

      // Procesamiento en una sola pasada (más eficiente)
      final hoyLista =
          rawMov
              .map((e) {
                final m = MovimientoResumen.fromJson(e);
                // Cruzar con material
                final mat = matMap[m.materialId];
                return mat != null
                    ? m.conMaterial(mat.nombre, mat.unidadMedida)
                    : m;
              })
              .where(
                (m) =>
                    m.fecha.year == hoy.year &&
                    m.fecha.month == hoy.month &&
                    m.fecha.day == hoy.day,
              )
              .toList()
            ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      return {
        'movimientos': hoyLista,
        'totalMateriales': matMap.length,
        'entradasHoy': hoyLista
            .where((m) => m.tipoMovimiento == 'ENTRADA')
            .length,
        'salidasHoy': hoyLista
            .where((m) => m.tipoMovimiento == 'SALIDA')
            .length,
      };
    } catch (e) {
      print('DEBUG: Error en MovimientoService: $e');
      rethrow;
    }
  }
}
