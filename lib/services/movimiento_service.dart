import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/material_model.dart';
import '../models/movimiento_model.dart';

class MovimientoService {
  /// Obtiene y procesa los movimientos del día actual, cruzándolos con materiales
  Future<Map<String, dynamic>> obtenerStatsHoy() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse(ApiConfig.movimientos)),
        http.get(Uri.parse(ApiConfig.materiales)),
      ]);

      final resMov = responses[0];
      final resMat = responses[1];

      if (resMov.statusCode != 200) {
        throw 'Error en el servidor de movimientos: ${resMov.statusCode}';
      }

      // 1. Procesar Materiales para el mapeo
      final Map<int, MaterialItem> matMap = {};
      int totalMat = 0;

      if (resMat.statusCode == 200) {
        final decMat = jsonDecode(resMat.body);
        List rawMat = decMat is List ? decMat : (decMat['materiales'] ?? []);
        totalMat = rawMat.length;
        for (final e in rawMat) {
          final m = MaterialItem.fromJson(e as Map<String, dynamic>);
          matMap[m.id] = m;
        }
      }

      // 2. Procesar Movimientos
      final decodedMov = jsonDecode(resMov.body);
      List rawMov = decodedMov is List
          ? decodedMov
          : (decodedMov['movimientos'] ?? []);

      final hoy = DateTime.now();

      final hoyLista =
          rawMov
              .map((e) => MovimientoResumen.fromJson(e as Map<String, dynamic>))
              .where(
                (m) =>
                    m.fecha.year == hoy.year &&
                    m.fecha.month == hoy.month &&
                    m.fecha.day == hoy.day,
              )
              .map((m) {
                final mat = m.materialId != null ? matMap[m.materialId] : null;
                return mat != null
                    ? m.conMaterial(mat.nombre, mat.unidadMedida)
                    : m;
              })
              .toList()
            ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      // 3. Retornar el paquete de datos procesado
      return {
        'movimientos': hoyLista,
        'totalMateriales': totalMat,
        'entradasHoy': hoyLista
            .where((m) => m.tipoMovimiento.toUpperCase() == 'ENTRADA')
            .length,
        'salidasHoy': hoyLista
            .where((m) => m.tipoMovimiento.toUpperCase() == 'SALIDA')
            .length,
      };
    } catch (e) {
      rethrow; // Reenviamos el error para que la UI lo maneje
    }
  }
}
